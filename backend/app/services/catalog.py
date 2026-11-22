"""Categories and products. Category is plain data — no category gets special code."""

from typing import Any

from ..core.errors import AppError, Conflict
from ..core.utils import new_id, now_iso
from ..schemas import CategoryIn, ProductIn, ProductUpdateIn
from ..storage import Tx
from .common import CATEGORIES, PRODUCTS, SELLER_STOCK, WAREHOUSE, audit, require

UNIT_LABEL = {"piece": "পিস", "kg": "কেজি", "gram": "গ্রাম", "liter": "লিটার", "packet": "প্যাকেট", "bottle": "বোতল", "box": "বক্স"}


# ---------- categories ----------
def list_categories(tx: Tx, include_archived: bool = True) -> list[dict[str, Any]]:
    products = tx.list(PRODUCTS)
    cats = [{**c, "product_count": sum(1 for p in products if p["category_id"] == c["id"])} for c in tx.list(CATEGORIES)]
    if not include_archived:
        cats = [c for c in cats if not c["archived"]]
    return sorted(cats, key=lambda c: (c["archived"], c["name"]))


def create_category(tx: Tx, admin: dict[str, Any], data: CategoryIn) -> dict[str, Any]:
    if tx.first(CATEGORIES, lambda c: c["name"] == data.name):
        raise Conflict("এই নামে ক্যাটাগরি আগেই আছে।", code="category_exists")
    doc = {"id": new_id("cat"), "name": data.name, "archived": False, "created_at": now_iso()}
    tx.put(CATEGORIES, doc)
    audit(tx, admin, "category.created", doc["id"], data.name)
    return doc


def rename_category(tx: Tx, admin: dict[str, Any], cat_id: str, data: CategoryIn) -> dict[str, Any]:
    cat = require(tx, CATEGORIES, cat_id, "ক্যাটাগরি পাওয়া যায়নি।")
    old = cat["name"]
    cat["name"] = data.name
    tx.put(CATEGORIES, cat)
    audit(tx, admin, "category.renamed", cat_id, f"{old} → {data.name}")
    return cat


def set_category_archived(tx: Tx, admin: dict[str, Any], cat_id: str, archived: bool) -> dict[str, Any]:
    cat = require(tx, CATEGORIES, cat_id, "ক্যাটাগরি পাওয়া যায়নি।")
    cat["archived"] = archived
    tx.put(CATEGORIES, cat)
    audit(tx, admin, "category.archived" if archived else "category.restored", cat_id, cat["name"])
    return cat


# ---------- products ----------
def _validate_prices(price: float, lo: float | None, hi: float | None, editable: bool) -> None:
    if editable:
        if lo is None or hi is None:
            raise AppError("দাম বদলানো গেলে সর্বনিম্ন ও সর্বোচ্চ দাম দিতে হবে।", code="price_range_required")
        if hi < lo:
            raise AppError("সর্বোচ্চ দাম সর্বনিম্নের চেয়ে কম হতে পারে না।", code="invalid_price_range")
        if not lo <= price <= hi:
            raise AppError("বিক্রয়মূল্য সর্বনিম্ন ও সর্বোচ্চের মধ্যে রাখুন।", code="price_out_of_range")


def stock_totals(tx: Tx, product_id: str) -> dict[str, float]:
    wh = tx.find(WAREHOUSE, lambda w: w["product_id"] == product_id)
    ss = tx.find(SELLER_STOCK, lambda s: s["product_id"] == product_id)
    return {
        "warehouse": sum(w["qty"] for w in wh),
        "reserved": sum(w.get("reserved", 0) for w in wh),
        "damaged": sum(w.get("damaged", 0) for w in wh),
        "with_sellers": sum(s["qty"] for s in ss),
    }


def admin_view(tx: Tx, p: dict[str, Any]) -> dict[str, Any]:
    cat = tx.get(CATEGORIES, p["category_id"])
    stock = stock_totals(tx, p["id"])
    status = "out_of_stock" if stock["warehouse"] <= 0 else "low_stock" if stock["warehouse"] <= p["low_stock_at"] else "ok"
    return {**p, "category_name": cat["name"] if cat else None, "unit_label": UNIT_LABEL[p["unit"]], "stock": stock, "stock_status": status}


def seller_view(p: dict[str, Any], qty: float) -> dict[str, Any]:
    """What a seller may see — never purchase cost or margin."""
    hidden = {"unit_cost", "cost_history", "commission_override"}
    return {**{k: v for k, v in p.items() if k not in hidden}, "unit_label": UNIT_LABEL[p["unit"]], "available_qty": qty}


def list_products(tx: Tx, category_id: str | None, status: str | None, q: str | None) -> list[dict[str, Any]]:
    out = []
    for p in tx.list(PRODUCTS):
        if category_id and p["category_id"] != category_id:
            continue
        if q and q.lower() not in p["name"].lower() and q.lower() not in p["sku"].lower():
            continue
        v = admin_view(tx, p)
        if status == "active" and not p["active"]:
            continue
        if status == "inactive" and p["active"]:
            continue
        if status in ("low_stock", "out_of_stock") and v["stock_status"] != status:
            continue
        out.append(v)
    return sorted(out, key=lambda p: p["name"])


def create_product(tx: Tx, admin: dict[str, Any], data: ProductIn) -> dict[str, Any]:
    require(tx, CATEGORIES, data.category_id, "ক্যাটাগরি পাওয়া যায়নি।")
    if tx.first(PRODUCTS, lambda p: p["sku"].lower() == data.sku.lower()):
        raise Conflict("এই SKU আগেই ব্যবহার হয়েছে।", code="sku_exists")
    _validate_prices(data.price, data.min_price, data.max_price, data.price_editable)
    doc = {"id": new_id("prd"), **data.model_dump(), "cost_history": [{"unit_cost": data.unit_cost, "at": now_iso()}], "created_at": now_iso()}
    tx.put(PRODUCTS, doc)
    audit(tx, admin, "product.created", doc["id"], f"{data.name} · ৳{data.price:g}")
    return admin_view(tx, doc)


def update_product(tx: Tx, admin: dict[str, Any], product_id: str, data: ProductUpdateIn) -> dict[str, Any]:
    p = require(tx, PRODUCTS, product_id, "পণ্য পাওয়া যায়নি।")
    changes = data.model_dump(exclude_unset=True)
    if "category_id" in changes:
        require(tx, CATEGORIES, changes["category_id"], "ক্যাটাগরি পাওয়া যায়নি।")
    summary = []
    if "price" in changes and changes["price"] != p["price"]:
        summary.append(f"দাম ৳{p['price']:g} → ৳{changes['price']:g}")
    if "unit_cost" in changes and changes["unit_cost"] != p["unit_cost"]:
        # New cost applies to future sales only; past sales keep their cost snapshot.
        p["cost_history"].append({"unit_cost": changes["unit_cost"], "at": now_iso()})
        summary.append("ক্রয়মূল্য বদলানো হয়েছে")
    p.update(changes)
    _validate_prices(p["price"], p.get("min_price"), p.get("max_price"), p["price_editable"])
    tx.put(PRODUCTS, p)
    audit(tx, admin, "product.updated", product_id, f"{p['name']}: " + (", ".join(summary) or "তথ্য হালনাগাদ"))
    return admin_view(tx, p)
