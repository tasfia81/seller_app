"""Daily settlement (day closing).

Seller submits the day → admin reviews the reconciliation (sales, cash, stock,
earnings) → admin closes the day. Closing approves that day's earnings and adds
the daily wage. A day with unresolved cash or (for daily-return sellers) stock
cannot be closed unless an admin records an authorised exception.
"""

from datetime import date
from typing import Any

from ..core.errors import AppError, Conflict
from ..core.utils import day_of, money, now_iso, today
from ..storage import Tx
from .common import EARNINGS, HANDOVERS, RETURNS, SALES, SELLER_CASH_METHODS, SELLER_STOCK, SELLERS, SETTINGS, SETTLEMENTS, audit, effective_sale, notify, require
from .compensation import current_rule, daily_wage
from .finance import add_earning, cash_summary

STATUS_LABEL = {"open": "খোলা", "submitted": "জমা হয়েছে", "review": "যাচাই চলছে", "discrepancy": "গরমিল", "closed": "বন্ধ"}


def _sid(seller_id: str, d: date) -> str:
    return f"{seller_id}|{d.isoformat()}"


def reconciliation(tx: Tx, seller: dict[str, Any], d: date) -> dict[str, Any]:
    day = d.isoformat()
    sales = [effective_sale(s) for s in tx.find(SALES, lambda s: s["seller_id"] == seller["id"] and day_of(s["created_at"]) == d)]
    cash_sales = money(sum(s["total"] for s in sales if s["payment"] in SELLER_CASH_METHODS))
    handovers = tx.find(HANDOVERS, lambda h: h["seller_id"] == seller["id"] and day_of(h["submitted_at"]) == d)
    stock_left = sum(s["qty"] for s in tx.find(SELLER_STOCK, lambda s: s["seller_id"] == seller["id"]))
    pending_returns = [r for r in tx.find(RETURNS, lambda r: r["seller_id"] == seller["id"] and r["status"] in ("pending", "approved"))]
    cash = cash_summary(tx, seller["id"])
    rule = current_rule(seller, day)
    earned = money(sum(e["amount"] for e in tx.find(EARNINGS, lambda e: e["seller_id"] == seller["id"] and e["date"] == day)))
    settings = (tx.get(SETTINGS, "main") or {}).get("inventory", {})
    needs_cash = settings.get("close_requires_cash", True)
    needs_returns = settings.get("close_requires_returns", True) and seller["policy"] == "daily_return"
    requirements = [
        {"key": "sales_synced", "text": "সব বিক্রি সার্ভারে নিশ্চিত হয়েছে", "done": True},
        {"key": "cash", "text": "সব ক্যাশ জমা ও যাচাই" if needs_cash else "ক্যাশ জমা (এই দিনে বাধ্যতামূলক নয়)", "done": cash["due"] <= 0.001 or not needs_cash, "amount": cash["due"]},
    ]
    if needs_returns:
        requirements.append({"key": "returns", "text": "বিক্রি না হওয়া সব পণ্য ফেরত", "done": stock_left <= 1e-6, "quantity": stock_left})
    return {
        "date": day, "seller_id": seller["id"], "seller_name": seller["name"], "policy": seller["policy"],
        "sales": {"count": len(sales), "total": money(sum(s["total"] for s in sales)), "quantity": sum(s["qty"] for s in sales),
                  "cash": cash_sales, "digital": money(sum(s["total"] for s in sales) - cash_sales)},
        "cash": {**cash, "handed_over_today": money(sum(h["amount"] for h in handovers))},
        "stock": {"remaining_with_seller": stock_left, "pending_returns": len(pending_returns)},
        "earnings": {"commission": earned, "daily_wage": daily_wage(rule) if sales else 0.0},
        "requirements": requirements,
        "can_close": all(r["done"] for r in requirements),
    }


def seller_day(tx: Tx, seller: dict[str, Any]) -> dict[str, Any]:
    d = today()
    doc = tx.get(SETTLEMENTS, _sid(seller["id"], d))
    return {**reconciliation(tx, seller, d), "status": doc["status"] if doc else "open"}


def seller_submit(tx: Tx, seller: dict[str, Any]) -> dict[str, Any]:
    d = today()
    rec = reconciliation(tx, seller, d)
    sid = _sid(seller["id"], d)
    doc = tx.get(SETTLEMENTS, sid)
    if doc and doc["status"] in ("submitted", "review", "closed"):
        raise Conflict("আজকের হিসাব আগেই জমা হয়েছে।", code="already_submitted")
    if not rec["can_close"]:
        raise AppError("দিনের হিসাব জমার আগে বাকি কাজগুলো শেষ করুন।", code="requirements_unmet", details={"requirements": rec["requirements"]})
    tx.put(SETTLEMENTS, {"id": sid, "seller_id": seller["id"], "date": d.isoformat(), "status": "submitted", "submitted_at": now_iso(), "snapshot": rec, "exception": None, "history": [{"title": "সেলার জমা দিয়েছেন", "at": now_iso()}]})
    notify(tx, "admin", "settlement_submitted", "দিনের হিসাব জমা হয়েছে", f"{seller['name']} · {d.isoformat()}", "/settlements")
    return {**rec, "status": "submitted"}


def list_for_date(tx: Tx, d: date, status: str | None) -> list[dict[str, Any]]:
    rows = []
    for s in tx.list(SELLERS):
        doc = tx.get(SETTLEMENTS, _sid(s["id"], d))
        has_sales = tx.first(SALES, lambda x: x["seller_id"] == s["id"] and day_of(x["created_at"]) == d)
        if not doc and not has_sales:
            continue
        rec = reconciliation(tx, s, d)
        st = doc["status"] if doc else "open"
        if st in ("submitted", "review") and not rec["can_close"] and not (doc and doc.get("exception")):
            st = "discrepancy"
        if status and st != status:
            continue
        rows.append({"seller_id": s["id"], "seller_name": s["name"], "date": d.isoformat(), "status": st, "status_label": STATUS_LABEL[st],
                     "total_sales": rec["sales"]["total"], "cash_due": rec["cash"]["due"], "stock_remaining": rec["stock"]["remaining_with_seller"], "policy": s["policy"]})
    return rows


def detail(tx: Tx, seller_id: str, d: date) -> dict[str, Any]:
    seller = require(tx, SELLERS, seller_id, "সেলার পাওয়া যায়নি।")
    doc = tx.get(SETTLEMENTS, _sid(seller_id, d))
    rec = reconciliation(tx, seller, d)
    return {**rec, "status": doc["status"] if doc else "open", "exception": doc.get("exception") if doc else None, "history": doc.get("history", []) if doc else []}


def record_exception(tx: Tx, admin: dict[str, Any], seller_id: str, d: date, note: str) -> dict[str, Any]:
    require(tx, SELLERS, seller_id, "সেলার পাওয়া যায়নি।")
    sid = _sid(seller_id, d)
    doc = tx.get(SETTLEMENTS, sid) or {"id": sid, "seller_id": seller_id, "date": d.isoformat(), "status": "review", "history": []}
    doc["exception"] = {"note": note, "by": admin["name"], "at": now_iso()}
    doc["history"].append({"title": "অনুমোদিত ব্যতিক্রম রেকর্ড", "at": now_iso(), "by": admin["name"]})
    tx.put(SETTLEMENTS, doc)
    audit(tx, admin, "settlement.exception", sid, note)
    return detail(tx, seller_id, d)


def request_correction(tx: Tx, admin: dict[str, Any], seller_id: str, d: date, note: str) -> dict[str, Any]:
    sid = _sid(seller_id, d)
    doc = require(tx, SETTLEMENTS, sid, "এই দিনের হিসাব জমা হয়নি।")
    doc["status"] = "review"
    doc["history"].append({"title": "সংশোধন চাওয়া হয়েছে", "at": now_iso(), "by": admin["name"], "note": note})
    tx.put(SETTLEMENTS, doc)
    notify(tx, f"seller:{seller_id}", "settlement_correction", "দিনের হিসাবে সংশোধন দরকার", note)
    return detail(tx, seller_id, d)


def close_day(tx: Tx, admin: dict[str, Any], seller_id: str, d: date) -> dict[str, Any]:
    seller = require(tx, SELLERS, seller_id, "সেলার পাওয়া যায়নি।")
    sid = _sid(seller_id, d)
    doc = tx.get(SETTLEMENTS, sid) or {"id": sid, "seller_id": seller_id, "date": d.isoformat(), "history": [], "exception": None}
    if doc.get("status") == "closed":
        raise Conflict("এই দিন আগেই বন্ধ হয়েছে।", code="already_closed")
    rec = reconciliation(tx, seller, d)
    if not rec["can_close"] and not doc.get("exception"):
        raise AppError("গরমিল মেটানো বা অনুমোদিত ব্যতিক্রম রেকর্ড না করে দিন বন্ধ করা যাবে না।", code="unresolved_discrepancy", details={"requirements": rec["requirements"]})
    for e in tx.find(EARNINGS, lambda e: e["seller_id"] == seller_id and e["date"] == d.isoformat() and e["status"] == "pending"):
        e["status"] = "approved"
        tx.put(EARNINGS, e)
    if rec["earnings"]["daily_wage"]:
        add_earning(tx, seller_id, rec["earnings"]["daily_wage"], "daily_wage", sid, on=d, status="approved")
    doc.update({"status": "closed", "closed_at": now_iso(), "closed_by": admin["name"], "snapshot": rec})
    doc["history"].append({"title": "দিন বন্ধ", "at": now_iso(), "by": admin["name"]})
    tx.put(SETTLEMENTS, doc)
    audit(tx, admin, "settlement.closed", sid, f"{seller['name']} · {d.isoformat()}")
    notify(tx, f"seller:{seller_id}", "day_closed", "দিনের হিসাব সম্পন্ন", f"{d.isoformat()} এর হিসাব বন্ধ হয়েছে।")
    return detail(tx, seller_id, d)
