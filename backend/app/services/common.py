"""Shared helpers used by every service: lookups, stock keys, audit, notifications."""

from typing import Any

from ..core.errors import NotFound
from ..core.utils import money, new_id, now_iso
from ..storage import Tx

# Collection names (same names will be used in Firestore).
USERS = "users"
SELLERS = "sellers"
APPLICATIONS = "applications"
CATEGORIES = "categories"
PRODUCTS = "products"
WAREHOUSE = "warehouse_stock"
SELLER_STOCK = "seller_stock"
MOVEMENTS = "stock_movements"
ASSIGNMENTS = "assignments"
SALES = "sales"
CORRECTIONS = "corrections"
HANDOVERS = "cash_handovers"
EARNINGS = "earnings"
PAYOUTS = "payouts"
RETURNS = "stock_returns"
DAMAGES = "damages"
SETTLEMENTS = "settlements"
EXPENSES = "expenses"
NOTIFICATIONS = "notifications"
AUDIT = "audit_log"
SETTINGS = "settings"
LOTS = "stock_lots"  # every stock receipt; funded lots carry investor shares
INVESTORS = "investors"
INV_APPS = "investor_applications"
INV_TXNS = "investor_transactions"
INV_RUNS = "investor_profit_runs"
INV_WITHDRAWALS = "investor_withdrawals"

SELLER_CASH_METHODS = {"cash", "other"}  # money that stays in the seller's hand


def require(tx: Tx, collection: str, doc_id: str, message: str = "তথ্যটি পাওয়া যায়নি।") -> dict[str, Any]:
    doc = tx.get(collection, doc_id)
    if doc is None:
        raise NotFound(message)
    return doc


def vkey(variant: str | None) -> str:
    return variant or "-"


def warehouse_id(product_id: str, variant: str | None) -> str:
    return f"{product_id}|{vkey(variant)}"


def seller_stock_id(seller_id: str, product_id: str, variant: str | None) -> str:
    return f"{seller_id}|{product_id}|{vkey(variant)}"


def get_warehouse(tx: Tx, product_id: str, variant: str | None) -> dict[str, Any]:
    wid = warehouse_id(product_id, variant)
    return tx.get(WAREHOUSE, wid) or {"id": wid, "product_id": product_id, "variant": variant, "qty": 0.0, "reserved": 0.0, "damaged": 0.0}


def get_seller_stock(tx: Tx, seller_id: str, product_id: str, variant: str | None) -> dict[str, Any]:
    sid = seller_stock_id(seller_id, product_id, variant)
    return tx.get(SELLER_STOCK, sid) or {"id": sid, "seller_id": seller_id, "product_id": product_id, "variant": variant, "qty": 0.0}


def add_movement(tx: Tx, *, kind: str, product_id: str, variant: str | None, qty: float, source: str, destination: str, ref: str, by: str) -> None:
    tx.put(MOVEMENTS, {
        "id": new_id("mv"), "kind": kind, "product_id": product_id, "variant": variant, "qty": qty,
        "source": source, "destination": destination, "ref": ref, "by": by, "at": now_iso(),
    })


def audit(tx: Tx, actor: dict[str, Any], action: str, target: str, summary: str) -> None:
    """Append-only audit log. Never put NID numbers or passwords in `summary`."""
    tx.put(AUDIT, {"id": new_id("au"), "actor_id": actor["id"], "actor_name": actor.get("name", ""), "action": action, "target": target, "summary": summary, "at": now_iso()})


def notify(tx: Tx, audience: str, kind: str, title: str, body: str, link: str = "") -> None:
    """audience = "admin" or "seller:<seller_id>"."""
    tx.put(NOTIFICATIONS, {"id": new_id("nt"), "audience": audience, "kind": kind, "title": title, "body": body, "link": link, "read": False, "at": now_iso()})


def effective_sale(sale: dict[str, Any]) -> dict[str, Any]:
    """A sale's current values after any approved correction (the original is kept)."""
    eff = sale.get("effective") or {}
    qty = eff.get("qty", sale["qty"])
    unit_price = eff.get("unit_price", sale["unit_price"])
    payment = eff.get("payment", sale["payment"])
    total = money(qty * unit_price)
    profit = money((unit_price - sale["unit_cost"]) * qty)
    return {"qty": qty, "unit_price": unit_price, "payment": payment, "total": total, "gross_profit": profit, "commission": eff.get("commission", sale["commission"])}


def product_name(tx: Tx, product_id: str, variant: str | None = None) -> str:
    p = tx.get(PRODUCTS, product_id)
    name = p["name"] if p else product_id
    return f"{name} ({variant})" if variant else name
