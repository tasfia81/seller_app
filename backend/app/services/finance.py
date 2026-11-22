"""Cash collected by sellers, handovers, seller earnings, payouts and expenses.

Definitions (kept consistent everywhere):
  cash collected   = sales paid in cash/other (money that stays in the seller's hand)
  cash due         = collected − verified handovers
  to submit        = cash due − handovers still pending verification
  Digital payments (bKash/Nagad/bank) go straight to the business: never seller cash.
"""

from datetime import date
from typing import Any

from ..core.errors import AppError, Conflict
from ..core.utils import day_of, in_range, money, new_id, now_iso, today
from ..schemas import ExpenseIn, HandoverIn, PayoutIn, VerifyHandoverIn
from ..storage import Tx
from .common import EARNINGS, EXPENSES, HANDOVERS, PAYOUTS, SALES, SELLER_CASH_METHODS, SELLERS, audit, effective_sale, notify, require

METHOD_LABEL = {"in_person": "অফিসে হাতে", "bkash": "বিকাশ", "nagad": "নগদ", "bank": "ব্যাংক"}


# ---------------- cash ----------------
def cash_summary(tx: Tx, seller_id: str) -> dict[str, float]:
    collected = sum(effective_sale(s)["total"] for s in tx.find(SALES, lambda s: s["seller_id"] == seller_id) if effective_sale(s)["payment"] in SELLER_CASH_METHODS)
    handovers = tx.find(HANDOVERS, lambda h: h["seller_id"] == seller_id)
    verified = sum(h["received_amount"] for h in handovers if h["status"] == "verified")
    pending = sum(h["amount"] for h in handovers if h["status"] == "pending")
    due = money(collected - verified)
    return {"collected": money(collected), "verified": money(verified), "pending_verification": money(pending), "due": due, "to_submit": money(max(due - pending, 0))}


def submit_handover(tx: Tx, seller: dict[str, Any], data: HandoverIn) -> dict[str, Any]:
    summary = cash_summary(tx, seller["id"])
    if data.amount > summary["to_submit"] + 0.001:
        raise AppError(f"জমা দেওয়ার মতো বাকি আছে ৳{summary['to_submit']:g}। এর বেশি দেওয়া যাবে না।", code="amount_exceeds_due", details=summary)
    doc = {"id": new_id("ho"), "seller_id": seller["id"], "seller_name": seller["name"], "amount": money(data.amount), "method": data.method,
           "reference": data.reference, "note": data.note, "status": "pending", "submitted_at": now_iso(), "received_amount": None, "history": []}
    tx.put(HANDOVERS, doc)
    notify(tx, "admin", "cash_handover", "ক্যাশ জমা যাচাইয়ের অপেক্ষায়", f"{seller['name']} · ৳{data.amount:g}", "/cash")
    return doc


def list_handovers(tx: Tx, status: str | None = None, seller_id: str | None = None) -> list[dict[str, Any]]:
    items = tx.find(HANDOVERS, lambda h: (not status or h["status"] == status) and (not seller_id or h["seller_id"] == seller_id))
    return sorted(items, key=lambda h: h["submitted_at"], reverse=True)


def verify_handover(tx: Tx, admin: dict[str, Any], handover_id: str, data: VerifyHandoverIn) -> dict[str, Any]:
    h = require(tx, HANDOVERS, handover_id, "জমার তথ্য পাওয়া যায়নি।")
    if h["status"] != "pending":
        raise Conflict("এই জমা আগেই যাচাই বা প্রত্যাখ্যান করা হয়েছে।", code="already_processed")
    if data.received_amount > h["amount"] + 0.001:
        raise AppError("জমার কথা বলা টাকার চেয়ে বেশি গ্রহণ দেখানো যাবে না।", code="received_exceeds_amount")
    h["status"] = "verified"
    h["received_amount"] = money(data.received_amount)
    h["shortfall"] = money(h["amount"] - data.received_amount)
    h["verified_by"] = admin["name"]
    h["verified_at"] = now_iso()
    h["history"].append({"action": "verified", "by": admin["name"], "at": h["verified_at"], "note": data.note})
    tx.put(HANDOVERS, h)
    audit(tx, admin, "cash.verified", handover_id, f"{h['seller_name']} · ৳{data.received_amount:g} গ্রহণ" + (f" (৳{h['shortfall']:g} কম)" if h["shortfall"] else ""))
    notify(tx, f"seller:{h['seller_id']}", "cash_verified", "ক্যাশ জমা যাচাই হয়েছে", f"৳{data.received_amount:g} গ্রহণ নিশ্চিত করা হয়েছে।")
    return h


def reject_handover(tx: Tx, admin: dict[str, Any], handover_id: str, note: str | None) -> dict[str, Any]:
    h = require(tx, HANDOVERS, handover_id, "জমার তথ্য পাওয়া যায়নি।")
    if h["status"] != "pending":
        raise Conflict("এই জমা আগেই যাচাই বা প্রত্যাখ্যান করা হয়েছে।", code="already_processed")
    h["status"] = "rejected"
    h["history"].append({"action": "rejected", "by": admin["name"], "at": now_iso(), "note": note})
    tx.put(HANDOVERS, h)
    audit(tx, admin, "cash.rejected", handover_id, f"{h['seller_name']} · ৳{h['amount']:g}")
    notify(tx, f"seller:{h['seller_id']}", "cash_rejected", "ক্যাশ জমা প্রত্যাখ্যাত", note or "অফিসে যোগাযোগ করুন।")
    return h


def cash_overview(tx: Tx) -> dict[str, Any]:
    rows = []
    totals = {"collected": 0.0, "verified": 0.0, "pending_verification": 0.0, "due": 0.0, "to_submit": 0.0}
    for s in tx.list(SELLERS):
        c = cash_summary(tx, s["id"])
        if any(c.values()):
            rows.append({"seller_id": s["id"], "seller_name": s["name"], **c})
        for k in totals:
            totals[k] = money(totals[k] + c[k])
    business_direct = sum(effective_sale(s)["total"] for s in tx.list(SALES) if effective_sale(s)["payment"] not in SELLER_CASH_METHODS and day_of(s["created_at"]) == today())
    return {"totals": totals, "business_direct_today": money(business_direct), "sellers": sorted(rows, key=lambda r: r["due"], reverse=True)}


# ---------------- earnings & payouts ----------------
def add_earning(tx: Tx, seller_id: str, amount: float, source: str, ref: str, on: date | None = None, status: str = "pending") -> None:
    if amount <= 0:
        return
    tx.put(EARNINGS, {"id": new_id("er"), "seller_id": seller_id, "date": (on or today()).isoformat(), "amount": money(amount), "source": source, "ref": ref, "status": status})


def earnings_summary(tx: Tx, seller_id: str) -> dict[str, float]:
    items = tx.find(EARNINGS, lambda e: e["seller_id"] == seller_id)
    t = today()
    paid = sum(p["amount"] for p in tx.find(PAYOUTS, lambda p: p["seller_id"] == seller_id))
    approved = sum(e["amount"] for e in items if e["status"] == "approved")
    return {
        "today": money(sum(e["amount"] for e in items if e["date"] == t.isoformat())),
        "this_month": money(sum(e["amount"] for e in items if e["date"][:7] == t.isoformat()[:7])),
        "pending": money(sum(e["amount"] for e in items if e["status"] == "pending")),
        "approved": money(approved),
        "total_paid": money(paid),
        "outstanding": money(approved - paid),
    }


def earnings_history(tx: Tx, seller_id: str) -> list[dict[str, Any]]:
    by_day: dict[str, dict[str, Any]] = {}
    for e in tx.find(EARNINGS, lambda e: e["seller_id"] == seller_id):
        d = by_day.setdefault(e["date"], {"date": e["date"], "amount": 0.0, "sales": 0, "status": "approved"})
        d["amount"] = money(d["amount"] + e["amount"])
        d["sales"] += 1 if e["source"] == "sale" else 0
        if e["status"] == "pending":
            d["status"] = "pending"
    return sorted(by_day.values(), key=lambda d: d["date"], reverse=True)


def create_payout(tx: Tx, admin: dict[str, Any], data: PayoutIn) -> dict[str, Any]:
    existing = tx.first(PAYOUTS, lambda p: p["client_request_id"] == data.client_request_id)
    if existing:
        return existing  # idempotent: the same request never pays twice
    seller = require(tx, SELLERS, data.seller_id, "সেলার পাওয়া যায়নি।")
    outstanding = earnings_summary(tx, seller["id"])["outstanding"]
    if data.amount > outstanding + 0.001:
        raise AppError(f"দেওয়া যাবে সর্বোচ্চ ৳{outstanding:g}।", code="exceeds_payable", details={"payable": outstanding})
    if data.method != "in_person" and not data.reference:
        raise AppError("লেনদেন নম্বর দিন।", code="reference_required")
    doc = {"id": new_id("po"), "seller_id": seller["id"], "seller_name": seller["name"], "amount": money(data.amount), "method": data.method,
           "reference": data.reference, "note": data.note, "client_request_id": data.client_request_id, "by": admin["name"], "at": now_iso(), "status": "paid"}
    tx.put(PAYOUTS, doc)
    audit(tx, admin, "payout.created", doc["id"], f"{seller['name']} · ৳{data.amount:g} · {METHOD_LABEL[data.method]}")
    notify(tx, f"seller:{seller['id']}", "payout", "পেমেন্ট দেওয়া হয়েছে", f"৳{data.amount:g} · {METHOD_LABEL[data.method]}")
    return doc


def payouts_overview(tx: Tx) -> dict[str, Any]:
    rows = []
    for s in tx.list(SELLERS):
        e = earnings_summary(tx, s["id"])
        earned = sum(x["amount"] for x in tx.find(EARNINGS, lambda x: x["seller_id"] == s["id"]))
        rows.append({"seller_id": s["id"], "seller_name": s["name"], "earned": money(earned), "approved": e["approved"], "paid": e["total_paid"], "outstanding": e["outstanding"]})
    history = sorted(tx.list(PAYOUTS), key=lambda p: p["at"], reverse=True)
    totals = {k: money(sum(r[k] for r in rows)) for k in ("earned", "approved", "paid", "outstanding")}
    return {"totals": totals, "sellers": rows, "history": history}


# ---------------- expenses ----------------
def add_expense(tx: Tx, admin: dict[str, Any], data: ExpenseIn) -> dict[str, Any]:
    doc = {"id": new_id("ex"), **data.model_dump(mode="json"), "amount": money(data.amount), "recorded_by": admin["name"], "at": now_iso()}
    tx.put(EXPENSES, doc)
    audit(tx, admin, "expense.created", doc["id"], f"{data.category} · ৳{data.amount:g}")
    return doc


def list_expenses(tx: Tx, start: date, end: date, category: str | None) -> dict[str, Any]:
    items = [e for e in tx.list(EXPENSES) if start.isoformat() <= e["date"] <= end.isoformat() and (not category or e["category"] == category)]
    items.sort(key=lambda e: e["date"], reverse=True)
    by_cat: dict[str, float] = {}
    for e in items:
        by_cat[e["category"]] = money(by_cat.get(e["category"], 0) + e["amount"])
    return {"total": money(sum(e["amount"] for e in items)), "by_category": by_cat, "items": items}


def sales_cash_in_range(tx: Tx, seller_id: str, start: date, end: date) -> float:
    return money(sum(effective_sale(s)["total"] for s in tx.find(SALES, lambda s: s["seller_id"] == seller_id and in_range(s["created_at"], start, end)) if effective_sale(s)["payment"] in SELLER_CASH_METHODS))
