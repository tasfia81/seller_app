"""Central stock, assignments to sellers, transfers, returns and damage.

Rules:
- Assigned stock is *reserved* in the warehouse until the seller accepts the
  handover in the app; only then does it move to the seller.
- A return request moves nothing until an admin receives the goods.
- Every quantity change writes a stock movement (auditable).
"""

from typing import Any

from ..core.errors import AppError, Conflict, Forbidden
from ..core.utils import money, new_id, now_iso
from ..schemas import AssignmentIn, DamageIn, ReturnApproveIn, ReturnIn, StockReceiptIn, TransferIn
from ..storage import Tx
from .catalog import UNIT_LABEL, stock_totals
from .common import (ASSIGNMENTS, DAMAGES, MOVEMENTS, PRODUCTS, RETURNS, SELLER_STOCK, SELLERS, WAREHOUSE, add_movement, audit, get_seller_stock,
                     get_warehouse, notify, product_name, require)

ASSIGNMENT_LABEL = {"pending_handover": "হস্তান্তর বাকি", "active": "চালু", "partially_returned": "আংশিক ফেরত", "closed": "বন্ধ", "cancelled": "বাতিল"}
RETURN_LABEL = {"pending": "অপেক্ষমাণ", "approved": "অনুমোদিত · গ্রহণ বাকি", "rejected": "বাতিল", "completed": "সম্পন্ন"}


def _check_variant(product: dict[str, Any], variant: str | None) -> None:
    if product["variants"] and variant not in product["variants"]:
        raise AppError(f"{product['name']}-এর ধরন বাছুন: {', '.join(product['variants'])}", code="variant_required")
    if not product["variants"] and variant:
        raise AppError(f"{product['name']}-এর কোনো ধরন নেই।", code="variant_not_allowed")


def _check_step(product: dict[str, Any], qty: float) -> None:
    step = product.get("quantity_step", 1)
    if abs(round(qty / step) * step - qty) > 1e-6:
        raise AppError(f"পরিমাণ {step:g} {UNIT_LABEL[product['unit']]} করে দিতে হবে।", code="invalid_quantity_step")


# ---------- warehouse ----------
def receive_stock(tx: Tx, admin: dict[str, Any], data: StockReceiptIn) -> dict[str, Any]:
    product = require(tx, PRODUCTS, data.product_id, "পণ্য পাওয়া যায়নি।")
    _check_variant(product, data.variant)
    _check_step(product, data.quantity)
    wh = get_warehouse(tx, product["id"], data.variant)
    wh["qty"] = wh["qty"] + data.quantity
    tx.put(WAREHOUSE, wh)
    ref = data.batch_ref or new_id("rcv")
    add_movement(tx, kind="receipt", product_id=product["id"], variant=data.variant, qty=data.quantity,
                 source=data.supplier or "সরবরাহকারী", destination="warehouse", ref=ref, by=admin["name"])
    audit(tx, admin, "stock.received", product["id"], f"{product_name(tx, product['id'], data.variant)} +{data.quantity:g} · ৳{data.unit_cost:g}/ইউনিট")
    return {"product_id": product["id"], "variant": data.variant, "warehouse_qty": wh["qty"], "total_cost": money(data.quantity * data.unit_cost), "ref": ref}


def inventory_overview(tx: Tx) -> dict[str, Any]:
    rows = []
    for p in tx.list(PRODUCTS):
        s = stock_totals(tx, p["id"])
        rows.append({"product_id": p["id"], "name": p["name"], "unit_label": UNIT_LABEL[p["unit"]], **s,
                     "stock_value": money((s["warehouse"] + s["with_sellers"] + s["reserved"]) * p["unit_cost"]),
                     "low": s["warehouse"] <= p["low_stock_at"],
                     "by_variant": [{"variant": w["variant"], "warehouse": w["qty"], "reserved": w.get("reserved", 0)} for w in tx.find(WAREHOUSE, lambda w: w["product_id"] == p["id"])]})
    totals = {k: sum(r[k] for r in rows) for k in ("warehouse", "with_sellers", "reserved", "damaged")}
    totals["total"] = totals["warehouse"] + totals["with_sellers"] + totals["reserved"]
    totals["low_stock_products"] = sum(1 for r in rows if r["low"])
    return {"totals": totals, "products": sorted(rows, key=lambda r: r["name"])}


def list_movements(tx: Tx, product_id: str | None = None, seller_id: str | None = None, limit: int = 100) -> list[dict[str, Any]]:
    items = tx.list(MOVEMENTS)
    if product_id:
        items = [m for m in items if m["product_id"] == product_id]
    if seller_id:
        items = [m for m in items if seller_id in (m["source"], m["destination"])]
    items.sort(key=lambda m: m["at"], reverse=True)
    return [{**m, "product_name": product_name(tx, m["product_id"], m["variant"])} for m in items[:limit]]


# ---------- assignments ----------
def create_assignment(tx: Tx, admin: dict[str, Any], data: AssignmentIn) -> dict[str, Any]:
    seller = require(tx, SELLERS, data.seller_id, "সেলার পাওয়া যায়নি।")
    if seller["status"] != "active":
        raise AppError("শুধু সক্রিয় সেলারকে স্টক দেওয়া যায়।", code="seller_inactive")
    items = []
    seen = set()
    for it in data.items:
        product = require(tx, PRODUCTS, it.product_id, "পণ্য পাওয়া যায়নি।")
        if not product["active"]:
            raise AppError(f"{product['name']} এখন বন্ধ আছে।", code="product_inactive")
        _check_variant(product, it.variant)
        _check_step(product, it.quantity)
        key = (it.product_id, it.variant)
        if key in seen:
            raise AppError("একই পণ্য ও ধরন দুবার দেওয়া হয়েছে।", code="duplicate_item")
        seen.add(key)
        wh = get_warehouse(tx, it.product_id, it.variant)
        if it.quantity > wh["qty"]:
            raise AppError(f"{product_name(tx, it.product_id, it.variant)}: গুদামে মাত্র {wh['qty']:g} আছে।", code="insufficient_warehouse_stock",
                           details={"product_id": it.product_id, "variant": it.variant, "available": wh["qty"]})
        wh["qty"] -= it.quantity
        wh["reserved"] = wh.get("reserved", 0) + it.quantity
        tx.put(WAREHOUSE, wh)
        items.append({"product_id": it.product_id, "variant": it.variant, "name": product["name"], "quantity": it.quantity, "sold": 0.0, "returned": 0.0,
                      "price": product["price"], "min_price": product.get("min_price"), "max_price": product.get("max_price")})
    policy = seller["policy"] if data.policy == "seller_default" else data.policy
    doc = {"id": new_id("asg"), "seller_id": seller["id"], "seller_name": seller["name"], "items": items, "price_mode": data.price_mode,
           "discount_allowed": data.discount_allowed, "policy": policy, "status": "pending_handover", "created_by": admin["name"],
           "created_at": now_iso(), "accepted_at": None, "history": [{"title": "বরাদ্দ তৈরি", "by": admin["name"], "at": now_iso()}]}
    tx.put(ASSIGNMENTS, doc)
    audit(tx, admin, "assignment.created", doc["id"], f"{seller['name']} · {sum(i['quantity'] for i in items):g} ইউনিট")
    notify(tx, f"seller:{seller['id']}", "stock_assigned", "নতুন স্টক বরাদ্দ", f"{len(items)}টি পণ্য আপনাকে দেওয়া হয়েছে। হাতে পেয়ে অ্যাপে নিশ্চিত করুন।", f"/assignments/{doc['id']}")
    return assignment_view(doc)


def assignment_view(a: dict[str, Any]) -> dict[str, Any]:
    items = [{**i, "remaining": i["quantity"] - i["sold"] - i["returned"]} for i in a["items"]]
    return {**a, "items": items, "status_label": ASSIGNMENT_LABEL[a["status"]],
            "totals": {k: sum(i[k] for i in items) for k in ("quantity", "sold", "returned", "remaining")}}


def list_assignments(tx: Tx, seller_id: str | None = None, status: str | None = None) -> list[dict[str, Any]]:
    items = tx.find(ASSIGNMENTS, lambda a: (not seller_id or a["seller_id"] == seller_id) and (not status or a["status"] == status))
    return [assignment_view(a) for a in sorted(items, key=lambda a: a["created_at"], reverse=True)]


def accept_assignment(tx: Tx, seller: dict[str, Any], assignment_id: str) -> dict[str, Any]:
    a = require(tx, ASSIGNMENTS, assignment_id, "বরাদ্দ পাওয়া যায়নি।")
    if a["seller_id"] != seller["id"]:
        raise Forbidden("এই বরাদ্দ আপনার নয়।")
    if a["status"] != "pending_handover":
        raise Conflict("এই বরাদ্দ আগেই গ্রহণ বা বাতিল হয়েছে।", code="already_processed")
    for i in a["items"]:
        wh = get_warehouse(tx, i["product_id"], i["variant"])
        wh["reserved"] = max(wh.get("reserved", 0) - i["quantity"], 0)
        tx.put(WAREHOUSE, wh)
        ss = get_seller_stock(tx, seller["id"], i["product_id"], i["variant"])
        ss["qty"] += i["quantity"]
        tx.put(SELLER_STOCK, ss)
        add_movement(tx, kind="assignment", product_id=i["product_id"], variant=i["variant"], qty=i["quantity"], source="warehouse", destination=seller["id"], ref=a["id"], by=seller["name"])
    a["status"] = "active"
    a["accepted_at"] = now_iso()
    a["history"].append({"title": "সেলার স্টক বুঝে নিয়েছেন", "by": seller["name"], "at": a["accepted_at"]})
    tx.put(ASSIGNMENTS, a)
    notify(tx, "admin", "assignment_accepted", "সেলার স্টক বুঝে নিয়েছেন", f"{seller['name']} · #{a['id']}", f"/assignments/{a['id']}")
    return assignment_view(a)


def cancel_assignment(tx: Tx, admin: dict[str, Any], assignment_id: str) -> dict[str, Any]:
    a = require(tx, ASSIGNMENTS, assignment_id, "বরাদ্দ পাওয়া যায়নি।")
    if a["status"] != "pending_handover":
        raise Conflict("শুধু হস্তান্তরের আগে বাতিল করা যায়। পরে হলে স্টক ফেরত নিন।", code="cannot_cancel")
    for i in a["items"]:
        wh = get_warehouse(tx, i["product_id"], i["variant"])
        wh["reserved"] = max(wh.get("reserved", 0) - i["quantity"], 0)
        wh["qty"] += i["quantity"]
        tx.put(WAREHOUSE, wh)
    a["status"] = "cancelled"
    a["history"].append({"title": "বাতিল", "by": admin["name"], "at": now_iso()})
    tx.put(ASSIGNMENTS, a)
    audit(tx, admin, "assignment.cancelled", assignment_id, a["seller_name"])
    return assignment_view(a)


def close_assignment(tx: Tx, admin: dict[str, Any], assignment_id: str) -> dict[str, Any]:
    a = require(tx, ASSIGNMENTS, assignment_id, "বরাদ্দ পাওয়া যায়নি।")
    if a["status"] not in ("active", "partially_returned"):
        raise Conflict("এই বরাদ্দ বন্ধ করা যাবে না।", code="invalid_status")
    remaining = sum(i["quantity"] - i["sold"] - i["returned"] for i in a["items"])
    if remaining > 1e-6:
        raise AppError(f"সেলারের হাতে এখনো {remaining:g} ইউনিট আছে। আগে ফেরত বা হস্তান্তর করুন।", code="stock_remaining")
    a["status"] = "closed"
    a["history"].append({"title": "বন্ধ", "by": admin["name"], "at": now_iso()})
    tx.put(ASSIGNMENTS, a)
    audit(tx, admin, "assignment.closed", assignment_id, a["seller_name"])
    return assignment_view(a)


def apply_to_assignments(tx: Tx, seller_id: str, product_id: str, variant: str | None, qty: float, field: str) -> None:
    """Record sold/returned quantity on the seller's active assignments (oldest first)."""
    left = qty
    active = sorted(tx.find(ASSIGNMENTS, lambda a: a["seller_id"] == seller_id and a["status"] in ("active", "partially_returned")), key=lambda a: a["created_at"])
    for a in active:
        for i in a["items"]:
            if left <= 0 or i["product_id"] != product_id or i["variant"] != variant:
                continue
            room = i["quantity"] - i["sold"] - i["returned"]
            take = min(room, left)
            if take > 0:
                i[field] += take
                left -= take
        if field == "returned" and any(i["returned"] for i in a["items"]):
            a["status"] = "partially_returned"
        tx.put(ASSIGNMENTS, a)


def transfer(tx: Tx, admin: dict[str, Any], data: TransferIn) -> dict[str, Any]:
    """Recall from a seller (creates an approved return awaiting receipt) or move to another seller (new assignment the receiver must accept)."""
    product = require(tx, PRODUCTS, data.product_id, "পণ্য পাওয়া যায়নি।")
    seller = require(tx, SELLERS, data.seller_id, "সেলার পাওয়া যায়নি।")
    ss = get_seller_stock(tx, seller["id"], product["id"], data.variant)
    if data.quantity > ss["qty"]:
        raise AppError(f"{seller['name']}-এর কাছে মাত্র {ss['qty']:g} আছে।", code="insufficient_seller_stock")
    if data.kind == "recall":
        doc = {"id": new_id("ret"), "seller_id": seller["id"], "seller_name": seller["name"], "product_id": product["id"], "variant": data.variant,
               "quantity": data.quantity, "reason": "recall", "note": data.reason, "photo": None, "status": "approved", "destination": "warehouse",
               "created_at": now_iso(), "history": [{"title": "অ্যাডমিন ফেরত ডেকেছেন", "by": admin["name"], "at": now_iso()}]}
        tx.put(RETURNS, doc)
        notify(tx, f"seller:{seller['id']}", "stock_recall", "স্টক ফেরত দিন", f"{product_name(tx, product['id'], data.variant)} · {data.quantity:g} গুদামে ফেরত দিন।")
        audit(tx, admin, "stock.recall", doc["id"], f"{seller['name']} · {data.quantity:g}")
        return doc
    if not data.to_seller_id or data.to_seller_id == seller["id"]:
        raise AppError("কোন সেলারকে দেবেন বাছুন।", code="to_seller_required")
    to = require(tx, SELLERS, data.to_seller_id, "সেলার পাওয়া যায়নি।")
    ss["qty"] -= data.quantity
    tx.put(SELLER_STOCK, ss)
    apply_to_assignments(tx, seller["id"], product["id"], data.variant, data.quantity, "returned")
    wh = get_warehouse(tx, product["id"], data.variant)
    wh["reserved"] = wh.get("reserved", 0) + data.quantity  # in transit until the receiver accepts
    tx.put(WAREHOUSE, wh)
    add_movement(tx, kind="transfer_out", product_id=product["id"], variant=data.variant, qty=data.quantity, source=seller["id"], destination=f"transit→{to['id']}", ref="transfer", by=admin["name"])
    doc = {"id": new_id("asg"), "seller_id": to["id"], "seller_name": to["name"], "source_seller_id": seller["id"],
           "items": [{"product_id": product["id"], "variant": data.variant, "name": product["name"], "quantity": data.quantity, "sold": 0.0, "returned": 0.0,
                      "price": product["price"], "min_price": product.get("min_price"), "max_price": product.get("max_price")}],
           "price_mode": "flexible" if product["price_editable"] else "fixed", "discount_allowed": False, "policy": to["policy"], "status": "pending_handover",
           "created_by": admin["name"], "created_at": now_iso(), "accepted_at": None,
           "history": [{"title": f"{seller['name']}-এর কাছ থেকে হস্তান্তর", "by": admin["name"], "at": now_iso()}]}
    tx.put(ASSIGNMENTS, doc)
    audit(tx, admin, "stock.transfer", doc["id"], f"{seller['name']} → {to['name']} · {data.quantity:g}")
    notify(tx, f"seller:{to['id']}", "stock_assigned", "নতুন স্টক বরাদ্দ", f"{product['name']} · {data.quantity:g}। হাতে পেয়ে নিশ্চিত করুন।")
    return assignment_view(doc)


def record_damage(tx: Tx, admin: dict[str, Any], data: DamageIn) -> dict[str, Any]:
    product = require(tx, PRODUCTS, data.product_id, "পণ্য পাওয়া যায়নি।")
    wh = get_warehouse(tx, product["id"], data.variant)
    if data.seller_id:
        seller = require(tx, SELLERS, data.seller_id, "সেলার পাওয়া যায়নি।")
        ss = get_seller_stock(tx, seller["id"], product["id"], data.variant)
        if data.quantity > ss["qty"]:
            raise AppError(f"{seller['name']}-এর কাছে মাত্র {ss['qty']:g} আছে।", code="insufficient_seller_stock")
        ss["qty"] -= data.quantity
        tx.put(SELLER_STOCK, ss)
        apply_to_assignments(tx, seller["id"], product["id"], data.variant, data.quantity, "returned")
        source = seller["id"]
    else:
        if data.quantity > wh["qty"]:
            raise AppError(f"গুদামে মাত্র {wh['qty']:g} আছে।", code="insufficient_warehouse_stock")
        wh["qty"] -= data.quantity
        source = "warehouse"
    wh["damaged"] = wh.get("damaged", 0) + data.quantity
    tx.put(WAREHOUSE, wh)
    add_movement(tx, kind="damage", product_id=product["id"], variant=data.variant, qty=data.quantity, source=source, destination="damaged", ref="damage", by=admin["name"])
    doc = {"id": new_id("dmg"), "product_id": product["id"], "product_name": product_name(tx, product["id"], data.variant), "variant": data.variant,
           "quantity": data.quantity, "seller_id": data.seller_id, "reason": data.reason, "estimated_cost": money(data.quantity * product["unit_cost"]),
           "status": "recorded", "recorded_by": admin["name"], "at": now_iso(),
           "note": "সেলারের কাছ থেকে টাকা কাটা হয়নি — ব্যবসার নীতি অনুযায়ী আলাদা সিদ্ধান্ত লাগবে।"}
    tx.put(DAMAGES, doc)
    audit(tx, admin, "stock.damage", doc["id"], f"{doc['product_name']} · {data.quantity:g} · {data.reason}")
    return doc


# ---------- returns ----------
def request_return(tx: Tx, seller: dict[str, Any], data: ReturnIn) -> dict[str, Any]:
    product = require(tx, PRODUCTS, data.product_id, "পণ্য পাওয়া যায়নি।")
    _check_variant(product, data.variant)
    ss = get_seller_stock(tx, seller["id"], product["id"], data.variant)
    pending = sum(r["quantity"] for r in tx.find(RETURNS, lambda r: r["seller_id"] == seller["id"] and r["product_id"] == product["id"] and r["variant"] == data.variant and r["status"] in ("pending", "approved")))
    if data.quantity > ss["qty"] - pending + 1e-6:
        raise AppError(f"ফেরত দেওয়ার মতো আছে {max(ss['qty'] - pending, 0):g}।", code="insufficient_seller_stock")
    doc = {"id": new_id("ret"), "seller_id": seller["id"], "seller_name": seller["name"], "product_id": product["id"], "variant": data.variant,
           "quantity": data.quantity, "reason": data.reason, "note": data.note, "photo": None, "status": "pending", "destination": None,
           "created_at": now_iso(), "history": [{"title": "ফেরতের অনুরোধ", "by": seller["name"], "at": now_iso()}]}
    tx.put(RETURNS, doc)
    notify(tx, "admin", "return_request", "স্টক ফেরতের অনুরোধ", f"{seller['name']} · {product_name(tx, product['id'], data.variant)} · {data.quantity:g}", "/returns")
    return return_view(tx, doc)


def return_view(tx: Tx, r: dict[str, Any]) -> dict[str, Any]:
    return {**r, "product_name": product_name(tx, r["product_id"], r["variant"]), "status_label": RETURN_LABEL[r["status"]]}


def list_returns(tx: Tx, seller_id: str | None = None, status: str | None = None) -> list[dict[str, Any]]:
    items = tx.find(RETURNS, lambda r: (not seller_id or r["seller_id"] == seller_id) and (not status or r["status"] == status))
    return [return_view(tx, r) for r in sorted(items, key=lambda r: r["created_at"], reverse=True)]


def approve_return(tx: Tx, admin: dict[str, Any], return_id: str, data: ReturnApproveIn) -> dict[str, Any]:
    r = require(tx, RETURNS, return_id, "ফেরতের অনুরোধ পাওয়া যায়নি।")
    if r["status"] != "pending":
        raise Conflict("এই অনুরোধ আগেই সিদ্ধান্ত হয়েছে।", code="already_processed")
    r["status"] = "approved"
    r["destination"] = data.destination
    r["history"].append({"title": "অনুমোদিত — গুদামে গ্রহণ বাকি", "by": admin["name"], "at": now_iso()})
    tx.put(RETURNS, r)
    audit(tx, admin, "return.approved", return_id, f"{r['seller_name']} · {r['quantity']:g}")
    notify(tx, f"seller:{r['seller_id']}", "return_approved", "ফেরত অনুরোধ অনুমোদিত", "পণ্যটি অফিসে জমা দিন।")
    return return_view(tx, r)


def reject_return(tx: Tx, admin: dict[str, Any], return_id: str, note: str | None) -> dict[str, Any]:
    r = require(tx, RETURNS, return_id, "ফেরতের অনুরোধ পাওয়া যায়নি।")
    if r["status"] not in ("pending", "approved"):
        raise Conflict("এই অনুরোধ আগেই সম্পন্ন হয়েছে।", code="already_processed")
    r["status"] = "rejected"
    r["history"].append({"title": "বাতিল", "by": admin["name"], "at": now_iso(), "note": note})
    tx.put(RETURNS, r)
    audit(tx, admin, "return.rejected", return_id, r["seller_name"])
    notify(tx, f"seller:{r['seller_id']}", "return_rejected", "ফেরত অনুরোধ বাতিল", note or "অফিসে যোগাযোগ করুন।")
    return return_view(tx, r)


def receive_return(tx: Tx, admin: dict[str, Any], return_id: str) -> dict[str, Any]:
    """Admin physically received the goods: only now does stock move."""
    r = require(tx, RETURNS, return_id, "ফেরতের অনুরোধ পাওয়া যায়নি।")
    if r["status"] != "approved":
        raise Conflict("আগে অনুমোদন দিন, তারপর গ্রহণ করুন।", code="not_approved")
    ss = get_seller_stock(tx, r["seller_id"], r["product_id"], r["variant"])
    if r["quantity"] > ss["qty"] + 1e-6:
        raise AppError(f"সেলারের কাছে এখন মাত্র {ss['qty']:g} আছে।", code="insufficient_seller_stock")
    ss["qty"] -= r["quantity"]
    tx.put(SELLER_STOCK, ss)
    wh = get_warehouse(tx, r["product_id"], r["variant"])
    if r["destination"] == "damaged":
        wh["damaged"] = wh.get("damaged", 0) + r["quantity"]
    else:
        wh["qty"] += r["quantity"]
    tx.put(WAREHOUSE, wh)
    apply_to_assignments(tx, r["seller_id"], r["product_id"], r["variant"], r["quantity"], "returned")
    add_movement(tx, kind="return", product_id=r["product_id"], variant=r["variant"], qty=r["quantity"], source=r["seller_id"],
                 destination="damaged" if r["destination"] == "damaged" else "warehouse", ref=r["id"], by=admin["name"])
    r["status"] = "completed"
    r["history"].append({"title": "গুদামে গ্রহণ করা হয়েছে", "by": admin["name"], "at": now_iso()})
    tx.put(RETURNS, r)
    audit(tx, admin, "return.received", return_id, f"{r['seller_name']} · {r['quantity']:g}")
    return return_view(tx, r)


def seller_inventory(tx: Tx, seller: dict[str, Any]) -> dict[str, Any]:
    stocks = tx.find(SELLER_STOCK, lambda s: s["seller_id"] == seller["id"])
    assigns = tx.find(ASSIGNMENTS, lambda a: a["seller_id"] == seller["id"] and a["status"] != "cancelled")
    returns = tx.find(RETURNS, lambda r: r["seller_id"] == seller["id"])
    damages = tx.find(DAMAGES, lambda d: d.get("seller_id") == seller["id"])
    return {
        "policy": seller["policy"],
        "policy_text": "দিন শেষে বিক্রি না হওয়া সব পণ্য অফিসে ফেরত দিতে হবে।" if seller["policy"] == "daily_return" else "বিক্রি না হওয়া পণ্য আপনার কাছেই থাকবে।",
        "total_assigned": sum(i["quantity"] for a in assigns if a["status"] != "pending_handover" for i in a["items"]),
        "sold": sum(i["sold"] for a in assigns for i in a["items"]),
        "available": sum(s["qty"] for s in stocks),
        "pending_return": sum(r["quantity"] for r in returns if r["status"] in ("pending", "approved")),
        "damaged": sum(d["quantity"] for d in damages),
        "disputed": 0,
        "items": [{"product_id": s["product_id"], "variant": s["variant"], "name": product_name(tx, s["product_id"], s["variant"]), "qty": s["qty"]} for s in stocks if s["qty"] > 0],
        "movements": list_movements(tx, seller_id=seller["id"], limit=30),
    }
