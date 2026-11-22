"""Seller management (admin) and the seller's own profile."""

from typing import Any

from ..core.errors import AppError, Conflict
from ..core.utils import day_of, mask_nid, money, new_id, now_iso, today
from ..schemas import CompensationIn, ProfileChangeIn, SellerUpdateIn
from ..storage import Tx
from .common import ASSIGNMENTS, SALES, SELLER_STOCK, SELLERS, USERS, audit, effective_sale, notify, require
from .compensation import current_rule, short_label
from .finance import cash_summary, earnings_summary

STATUS_LABEL = {"active": "সক্রিয়", "inactive": "নিষ্ক্রিয়", "suspended": "স্থগিত"}
POLICY_LABEL = {"daily_return": "প্রতিদিন ফেরত", "carry_forward": "পরের দিনে চলবে"}


def _sales_on(tx: Tx, seller_id: str, day: str) -> list[dict[str, Any]]:
    return [effective_sale(s) for s in tx.find(SALES, lambda s: s["seller_id"] == seller_id and day_of(s["created_at"]).isoformat() == day)]


def list_sellers(tx: Tx, status: str | None, model: str | None, q: str | None) -> list[dict[str, Any]]:
    t = today().isoformat()
    rows = []
    for s in tx.list(SELLERS):
        rule = current_rule(s)
        if status and s["status"] != status:
            continue
        if model and rule["model"] != model:
            continue
        if q and q not in s["name"] and q not in s["mobile"]:
            continue
        sales = _sales_on(tx, s["id"], t)
        rows.append({"id": s["id"], "name": s["name"], "mobile": s["mobile"], "status": s["status"], "status_label": STATUS_LABEL[s["status"]],
                     "compensation": short_label(rule), "model": rule["model"], "policy": s["policy"], "policy_label": POLICY_LABEL[s["policy"]],
                     "today_sales": money(sum(x["total"] for x in sales)), "today_items": sum(x["qty"] for x in sales), "cash_due": cash_summary(tx, s["id"])["due"]})
    return sorted(rows, key=lambda r: (r["status"] != "active", -r["today_sales"]))


def overview(tx: Tx, seller_id: str) -> dict[str, Any]:
    s = require(tx, SELLERS, seller_id, "সেলার পাওয়া যায়নি।")
    t = today()
    month = t.isoformat()[:7]
    sales = [effective_sale(x) | {"day": day_of(x["created_at"]).isoformat()} for x in tx.find(SALES, lambda x: x["seller_id"] == seller_id)]
    assigns = tx.find(ASSIGNMENTS, lambda a: a["seller_id"] == seller_id and a["status"] in ("active", "partially_returned", "pending_handover"))
    rule = current_rule(s)
    return {
        "seller": profile_view(s, admin=True),
        "compensation": {**rule, "label": short_label(rule)},
        "kpis": {
            "today_sales": money(sum(x["total"] for x in sales if x["day"] == t.isoformat())),
            "month_sales": money(sum(x["total"] for x in sales if x["day"][:7] == month)),
            "assigned": sum(i["quantity"] for a in assigns if a["status"] != "pending_handover" for i in a["items"]),
            "available": sum(x["qty"] for x in tx.find(SELLER_STOCK, lambda x: x["seller_id"] == seller_id)),
            "cash_due": cash_summary(tx, seller_id)["due"],
            "earnings_payable": earnings_summary(tx, seller_id)["outstanding"],
        },
        "assignments": [{"id": a["id"], "status": a["status"], "created_at": a["created_at"], "items": a["items"]} for a in assigns],
        "cash": cash_summary(tx, seller_id),
        "earnings": earnings_summary(tx, seller_id),
    }


def profile_view(s: dict[str, Any], *, admin: bool = False) -> dict[str, Any]:
    out = {"id": s["id"], "name": s["name"], "mobile": s["mobile"], "status": s["status"], "status_label": STATUS_LABEL[s["status"]],
           "present_address": s["present_address"], "permanent_address": s["permanent_address"], "emergency": s["emergency"],
           "nid_masked": mask_nid("0000" + s["nid_last4"]), "verified": True, "policy": s["policy"], "policy_label": POLICY_LABEL[s["policy"]],
           "permissions": s["permissions"], "joined_at": s["joined_at"]}
    if admin:
        out["user_id"] = s["user_id"]
    return out


def update_seller(tx: Tx, admin: dict[str, Any], seller_id: str, data: SellerUpdateIn) -> dict[str, Any]:
    s = require(tx, SELLERS, seller_id, "সেলার পাওয়া যায়নি।")
    changes = data.model_dump(exclude_unset=True)
    if "mobile" in changes and changes["mobile"] != s["mobile"]:
        if tx.first(USERS, lambda u: u.get("mobile") == changes["mobile"]):
            raise Conflict("এই মোবাইল নম্বর অন্য অ্যাকাউন্টে আছে।", code="mobile_exists")
        user = require(tx, USERS, s["user_id"])
        user["mobile"] = changes["mobile"]
        tx.put(USERS, user)
        s["mobile"] = changes["mobile"]
    if "present_address" in changes:
        s["present_address"] = changes["present_address"]
    if "policy" in changes:
        s["policy"] = changes["policy"]
    for key in ("can_edit_price", "can_discount", "can_take_digital"):
        if key in changes:
            s["permissions"][key] = changes[key]
    tx.put(SELLERS, s)
    audit(tx, admin, "seller.updated", seller_id, f"{s['name']}: {', '.join(changes) or 'কিছু না'}")
    return profile_view(s, admin=True)


def set_status(tx: Tx, admin: dict[str, Any], seller_id: str, status: str) -> dict[str, Any]:
    s = require(tx, SELLERS, seller_id, "সেলার পাওয়া যায়নি।")
    if s["status"] == status:
        return profile_view(s, admin=True)
    s["status"] = status
    tx.put(SELLERS, s)
    if status != "active":
        revoke_sessions(tx, admin, seller_id, log=False)
    audit(tx, admin, f"seller.{status}", seller_id, s["name"])
    notify(tx, f"seller:{seller_id}", "account_status", "অ্যাকাউন্টের অবস্থা বদলেছে", f"আপনার অ্যাকাউন্ট এখন {STATUS_LABEL[status]}।")
    return profile_view(s, admin=True)


def revoke_sessions(tx: Tx, admin: dict[str, Any], seller_id: str, log: bool = True) -> dict[str, str]:
    s = require(tx, SELLERS, seller_id, "সেলার পাওয়া যায়নি।")
    user = require(tx, USERS, s["user_id"])
    user["session_version"] = user.get("session_version", 0) + 1
    tx.put(USERS, user)
    if log:
        audit(tx, admin, "seller.sessions_revoked", seller_id, s["name"])
    return {"message": "সব ডিভাইস থেকে লগআউট করানো হয়েছে।"}


def set_compensation(tx: Tx, admin: dict[str, Any], seller_id: str, data: CompensationIn) -> dict[str, Any]:
    s = require(tx, SELLERS, seller_id, "সেলার পাওয়া যায়নি।")
    need = {"profit": ["profit_percent"], "daily": ["daily_wage"], "per_unit": ["per_unit"], "hybrid": []}[data.model]
    missing = [f for f in need if getattr(data, f) is None]
    if missing or (data.model == "hybrid" and sum(1 for f in ("profit_percent", "daily_wage", "per_unit") if getattr(data, f)) < 2):
        raise AppError("এই ধরনের জন্য প্রয়োজনীয় ঘরগুলো পূরণ করুন।", code="compensation_fields_missing", details={"missing": missing})
    if data.effective_from < today():
        raise AppError("কার্যকর তারিখ আজ বা পরের কোনো দিন হতে হবে — আগের আয় বদলানো যায় না।", code="effective_date_in_past")
    rule = {"model": data.model, "profit_percent": data.profit_percent, "daily_wage": data.daily_wage, "per_unit": data.per_unit}
    old = current_rule(s)
    s["compensation_history"].append({"from": old, "to": rule, "effective_from": data.effective_from.isoformat(), "by": admin["name"], "reason": data.reason, "at": now_iso()})
    if data.effective_from == today():
        s["compensation"] = {**rule, "effective_from": data.effective_from.isoformat()}
    tx.put(SELLERS, s)
    audit(tx, admin, "seller.compensation_changed", seller_id, f"{s['name']}: {short_label(old)} → {short_label(rule)} ({data.effective_from.isoformat()} থেকে)")
    notify(tx, f"seller:{seller_id}", "commission_updated", "আয়ের নিয়ম বদলেছে", f"{data.effective_from.isoformat()} থেকে: {short_label(rule)}")
    return {"current": current_rule(s), "history": compensation_history(s)}


def compensation_history(s: dict[str, Any]) -> list[dict[str, Any]]:
    return [{"previous": short_label(h["from"]) if h.get("from") else None, "new": short_label(h["to"]), "effective_from": h["effective_from"],
             "changed_by": h["by"], "reason": h["reason"], "at": h["at"]} for h in sorted(s["compensation_history"], key=lambda h: h["at"], reverse=True)]


def request_profile_change(tx: Tx, seller: dict[str, Any], data: ProfileChangeIn) -> dict[str, Any]:
    doc = {"id": new_id("pcr"), "seller_id": seller["id"], "seller_name": seller["name"], **data.model_dump(), "status": "pending", "at": now_iso()}
    tx.put("profile_requests", doc)
    notify(tx, "admin", "profile_change", "তথ্য পরিবর্তনের অনুরোধ", f"{seller['name']} · {data.field}", f"/sellers/{seller['id']}")
    return doc
