"""Sales and sale corrections.

A sale is confirmed only after the server validates stock, price limits and
payment permissions. `client_request_id` makes submission idempotent: a retried
request returns the original sale instead of selling twice. Confirmed sales are
never edited in place — an approved correction stores new *effective* values
next to the original.
"""

from datetime import date
from typing import Any

from ..core.errors import AppError, Conflict, Forbidden
from ..core.utils import in_range, money, new_id, now_iso, period_range, today
from ..schemas import CorrectionIn, SaleIn
from ..storage import Tx
from .common import (ASSIGNMENTS, CORRECTIONS, EARNINGS, PRODUCTS, SALES, SELLER_CASH_METHODS, SELLER_STOCK, SELLERS, SETTINGS, SETTLEMENTS, add_movement, audit,
                     effective_sale, get_seller_stock, notify, product_name, require)
from .compensation import current_rule, sale_commission
from .finance import add_earning
from .inventory import _check_step, _check_variant, apply_to_assignments

PAYMENT_LABEL = {"cash": "ক্যাশ", "bkash": "বিকাশ", "nagad": "নগদ", "bank": "ব্যাংক", "other": "অন্যান্য"}
STATUS_LABEL = {"confirmed": "নিশ্চিত", "correction_requested": "সংশোধনের অনুরোধ"}


def _next_receipt_no(tx: Tx) -> str:
    counter = tx.get("counters", "sales") or {"id": "sales", "n": 10000}
    counter["n"] += 1
    tx.put("counters", counter)
    return f"S{counter['n']}"


def sale_view(tx: Tx, s: dict[str, Any], *, admin: bool = False) -> dict[str, Any]:
    eff = effective_sale(s)
    out = {
        "id": s["id"], "receipt_no": s["receipt_no"], "seller_id": s["seller_id"], "seller_name": s["seller_name"],
        "product_id": s["product_id"], "product_name": product_name(tx, s["product_id"], s["variant"]), "variant": s["variant"],
        "quantity": eff["qty"], "unit_price": eff["unit_price"], "total": eff["total"], "payment": eff["payment"],
        "payment_label": PAYMENT_LABEL[eff["payment"]],
        "money_destination": "seller_cash" if eff["payment"] in SELLER_CASH_METHODS else "business_account",
        "note": s.get("note"), "status": s["status"], "status_label": STATUS_LABEL[s["status"]], "created_at": s["created_at"],
        "corrected": bool(s.get("effective")),
    }
    if admin:
        out.update({"unit_cost_snapshot": s["unit_cost"], "cost_total": money(s["unit_cost"] * eff["qty"]), "gross_profit": eff["gross_profit"],
                    "commission": eff["commission"], "original": {k: s[k] for k in ("qty", "unit_price", "payment")}})
    return out


def _allowed_price(tx: Tx, seller: dict[str, Any], product: dict[str, Any], price: float) -> None:
    fixed_by_assignment = tx.first(ASSIGNMENTS, lambda a: a["seller_id"] == seller["id"] and a["status"] in ("active", "partially_returned")
                                   and a["price_mode"] == "fixed" and any(i["product_id"] == product["id"] for i in a["items"]))
    flexible = product["price_editable"] and seller["permissions"].get("can_edit_price", False) and not fixed_by_assignment
    if not flexible:
        if abs(price - product["price"]) > 0.001:
            raise AppError(f"এই পণ্যের দাম নির্ধারিত: ৳{product['price']:g}।", code="price_fixed", details={"price": product["price"]})
        return
    if not product["min_price"] <= price <= product["max_price"]:
        raise AppError(f"দাম ৳{product['min_price']:g} থেকে ৳{product['max_price']:g}-এর মধ্যে হতে হবে।", code="price_out_of_range",
                       details={"min": product["min_price"], "max": product["max_price"]})


def create_sale(tx: Tx, seller: dict[str, Any], data: SaleIn) -> dict[str, Any]:
    existing = tx.first(SALES, lambda s: s["seller_id"] == seller["id"] and s["client_request_id"] == data.client_request_id)
    if existing:
        return {**sale_view(tx, existing), "duplicate": True}
    closed = tx.get(SETTLEMENTS, f"{seller['id']}|{today().isoformat()}")
    if closed and closed["status"] == "closed":
        raise Conflict("আজকের দিনের হিসাব বন্ধ হয়ে গেছে। নতুন বিক্রি যোগ করা যাবে না।", code="day_closed")
    product = require(tx, PRODUCTS, data.product_id, "পণ্য পাওয়া যায়নি।")
    if not product["active"]:
        raise AppError("এই পণ্য এখন বিক্রি বন্ধ।", code="product_inactive")
    _check_variant(product, data.variant)
    _check_step(product, data.quantity)
    _allowed_price(tx, seller, product, data.unit_price)
    if data.payment not in SELLER_CASH_METHODS and not seller["permissions"].get("can_take_digital", True):
        raise Forbidden("আপনি ডিজিটাল পেমেন্ট নিতে পারবেন না।", code="payment_not_allowed")
    methods = (tx.get(SETTINGS, "main") or {}).get("payments", {})
    if methods and not methods.get(data.payment, {}).get("enabled", True):
        raise AppError("এই পেমেন্ট মাধ্যম এখন বন্ধ।", code="payment_disabled")
    ss = get_seller_stock(tx, seller["id"], product["id"], data.variant)
    if data.quantity > ss["qty"] + 1e-6:
        raise AppError(f"পর্যাপ্ত স্টক নেই। হাতে আছে {ss['qty']:g}।", code="insufficient_stock", details={"available": ss["qty"]})

    commission = sale_commission(current_rule(seller), product, data.quantity, data.unit_price, product["unit_cost"])
    sale = {
        "id": new_id("sale"), "receipt_no": _next_receipt_no(tx), "seller_id": seller["id"], "seller_name": seller["name"],
        "product_id": product["id"], "variant": data.variant, "qty": data.quantity, "unit_price": money(data.unit_price),
        "unit_cost": product["unit_cost"], "payment": data.payment, "commission": commission, "note": data.note,
        "client_request_id": data.client_request_id, "status": "confirmed", "created_at": now_iso(), "effective": None, "corrections": [],
    }
    tx.put(SALES, sale)
    ss["qty"] -= data.quantity
    tx.put(SELLER_STOCK, ss)
    apply_to_assignments(tx, seller["id"], product["id"], data.variant, data.quantity, "sold")
    add_movement(tx, kind="sale", product_id=product["id"], variant=data.variant, qty=data.quantity, source=seller["id"], destination="customer", ref=sale["receipt_no"], by=seller["name"])
    add_earning(tx, seller["id"], commission, "sale", sale["id"])
    if ss["qty"] <= product["low_stock_at"] / 4:
        notify(tx, "admin", "seller_low_stock", "সেলারের কাছে স্টক কম", f"{seller['name']} · {product_name(tx, product['id'], data.variant)} · {ss['qty']:g} বাকি")
    return {**sale_view(tx, sale), "duplicate": False}


def list_sales(tx: Tx, *, seller_id: str | None = None, period: str = "today", start: date | None = None, end: date | None = None,
               payment: str | None = None, product_id: str | None = None, q: str | None = None, admin: bool = False) -> dict[str, Any]:
    d1, d2 = period_range(period, start, end)
    items = [s for s in tx.list(SALES) if in_range(s["created_at"], d1, d2)
             and (not seller_id or s["seller_id"] == seller_id) and (not product_id or s["product_id"] == product_id)
             and (not payment or effective_sale(s)["payment"] == payment) and (not q or q.upper() in s["receipt_no"])]
    items.sort(key=lambda s: s["created_at"], reverse=True)
    views = [sale_view(tx, s, admin=admin) for s in items]
    summary = {"count": len(views), "total": money(sum(v["total"] for v in views)), "quantity": sum(v["quantity"] for v in views)}
    if admin:
        summary["gross_profit"] = money(sum(v["gross_profit"] for v in views))
        summary["seller_earnings"] = money(sum(v["commission"] for v in views))
    return {"from": d1.isoformat(), "to": d2.isoformat(), "summary": summary, "items": views}


def get_sale(tx: Tx, sale_id: str, *, seller_id: str | None = None, admin: bool = False) -> dict[str, Any]:
    s = require(tx, SALES, sale_id, "বিক্রি পাওয়া যায়নি।")
    if seller_id and s["seller_id"] != seller_id:
        raise Forbidden("এই বিক্রি আপনার নয়।")
    view = sale_view(tx, s, admin=admin)
    view["corrections"] = [c for c in tx.list(CORRECTIONS) if c["sale_id"] == sale_id]
    return view


# ---------- corrections ----------
def request_correction(tx: Tx, seller: dict[str, Any], sale_id: str, data: CorrectionIn) -> dict[str, Any]:
    s = require(tx, SALES, sale_id, "বিক্রি পাওয়া যায়নি।")
    if s["seller_id"] != seller["id"]:
        raise Forbidden("এই বিক্রি আপনার নয়।")
    if s["status"] == "correction_requested":
        raise Conflict("এই বিক্রির একটি সংশোধন আগেই অপেক্ষায় আছে।", code="correction_pending")
    requested = {k: v for k, v in {"qty": data.quantity, "unit_price": data.unit_price, "payment": data.payment}.items() if v is not None}
    if not requested:
        raise AppError("কী বদলাতে চান তা দিন।", code="nothing_to_change")
    corr = {"id": new_id("cor"), "sale_id": sale_id, "receipt_no": s["receipt_no"], "seller_id": seller["id"], "seller_name": seller["name"],
            "current": {k: effective_sale(s)[k] for k in ("qty", "unit_price", "payment")}, "requested": requested, "reason": data.reason,
            "status": "pending", "admin_note": None, "created_at": now_iso()}
    tx.put(CORRECTIONS, corr)
    s["status"] = "correction_requested"
    tx.put(SALES, s)
    notify(tx, "admin", "correction_request", "বিক্রি সংশোধনের অনুরোধ", f"{seller['name']} · {s['receipt_no']}", "/corrections")
    return corr


def list_corrections(tx: Tx, status: str | None = None) -> list[dict[str, Any]]:
    items = tx.find(CORRECTIONS, lambda c: not status or c["status"] == status)
    return sorted(items, key=lambda c: c["created_at"], reverse=True)


def decide_correction(tx: Tx, admin: dict[str, Any], correction_id: str, decision: str, note: str | None) -> dict[str, Any]:
    c = require(tx, CORRECTIONS, correction_id, "সংশোধনের অনুরোধ পাওয়া যায়নি।")
    if c["status"] not in ("pending", "clarification"):
        raise Conflict("এই অনুরোধ আগেই সিদ্ধান্ত হয়েছে।", code="already_processed")
    s = require(tx, SALES, c["sale_id"])
    if decision == "clarify":
        c["status"] = "clarification"
        c["admin_note"] = note
        tx.put(CORRECTIONS, c)
        notify(tx, f"seller:{c['seller_id']}", "correction_clarify", "সংশোধন নিয়ে প্রশ্ন", note or "অফিসে যোগাযোগ করুন।")
        return c
    if decision == "approve":
        old = effective_sale(s)
        new_qty = c["requested"].get("qty", old["qty"])
        delta = new_qty - old["qty"]
        if delta:
            ss = get_seller_stock(tx, s["seller_id"], s["product_id"], s["variant"])
            if delta > ss["qty"] + 1e-6:
                raise AppError(f"সেলারের কাছে মাত্র {ss['qty']:g} আছে।", code="insufficient_stock")
            ss["qty"] -= delta
            tx.put(SELLER_STOCK, ss)
            add_movement(tx, kind="adjustment", product_id=s["product_id"], variant=s["variant"], qty=-delta, source="correction", destination=s["seller_id"], ref=c["id"], by=admin["name"])
        product = require(tx, PRODUCTS, s["product_id"])
        seller = require(tx, SELLERS, s["seller_id"])
        new_price = c["requested"].get("unit_price", old["unit_price"])
        commission = sale_commission(current_rule(seller, s["created_at"][:10]), product, new_qty, new_price, s["unit_cost"])
        s["effective"] = {"qty": new_qty, "unit_price": new_price, "payment": c["requested"].get("payment", old["payment"]), "commission": commission}
        for e in tx.find(EARNINGS, lambda e: e["ref"] == s["id"]):
            e["amount"] = commission
            tx.put(EARNINGS, e)
        s["corrections"].append({"correction_id": c["id"], "at": now_iso(), "by": admin["name"]})
        c["status"] = "approved"
    else:
        c["status"] = "rejected"
    c["admin_note"] = note
    c["decided_by"] = admin["name"]
    c["decided_at"] = now_iso()
    s["status"] = "confirmed"
    tx.put(SALES, s)
    tx.put(CORRECTIONS, c)
    audit(tx, admin, f"correction.{c['status']}", c["id"], f"{s['receipt_no']} · {c['seller_name']}")
    notify(tx, f"seller:{c['seller_id']}", "correction_decided", "সংশোধনের সিদ্ধান্ত", f"{s['receipt_no']}: " + ("অনুমোদিত" if c["status"] == "approved" else "বাতিল"))
    return c
