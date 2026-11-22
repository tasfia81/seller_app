"""Dashboards and reports. Revenue, profit, cash and seller earnings are kept separate."""

from datetime import date, timedelta
from typing import Any

from ..core.utils import day_of, in_range, money, period_range, today
from ..storage import Tx
from .common import (ASSIGNMENTS, CORRECTIONS, EARNINGS, EXPENSES, HANDOVERS, NOTIFICATIONS, PRODUCTS, RETURNS, SALES, SELLER_CASH_METHODS, SELLER_STOCK,
                     SELLERS, effective_sale, product_name)
from .finance import cash_summary, earnings_summary
from .inventory import inventory_overview
from .sales import list_sales, sale_view
from .settlements import list_for_date


def _sales(tx: Tx, d1: date, d2: date) -> list[dict[str, Any]]:
    return [{**s, "eff": effective_sale(s)} for s in tx.list(SALES) if in_range(s["created_at"], d1, d2)]


def financial(tx: Tx, d1: date, d2: date) -> dict[str, Any]:
    sales = _sales(tx, d1, d2)
    gross_revenue = money(sum(s["qty"] * s["unit_price"] for s in sales))  # as originally recorded
    net_sales = money(sum(s["eff"]["total"] for s in sales))
    refunds = money(max(gross_revenue - net_sales, 0))
    cogs = money(sum(s["unit_cost"] * s["eff"]["qty"] for s in sales))
    gross_profit = money(net_sales - cogs)
    compensation = money(sum(e["amount"] for e in tx.list(EARNINGS) if d1.isoformat() <= e["date"] <= d2.isoformat()))
    expenses = money(sum(e["amount"] for e in tx.list(EXPENSES) if d1.isoformat() <= e["date"] <= d2.isoformat()))
    cash_received = money(sum(h["received_amount"] for h in tx.list(HANDOVERS) if h["status"] == "verified" and in_range(h["submitted_at"], d1, d2))
                          + sum(s["eff"]["total"] for s in sales if s["eff"]["payment"] not in SELLER_CASH_METHODS))
    return {"from": d1.isoformat(), "to": d2.isoformat(), "revenue": gross_revenue, "refunds_adjustments": refunds, "net_sales": net_sales,
            "cost_of_goods_sold": cogs, "gross_profit": gross_profit, "seller_compensation": compensation, "operating_expenses": expenses,
            "net_profit": money(gross_profit - compensation - expenses), "cash_received": cash_received,
            "note": "হাতে পাওয়া টাকা আর লাভ এক নয়।"}


def admin_dashboard(tx: Tx, period: str) -> dict[str, Any]:
    d1, d2 = period_range(period)
    fin = financial(tx, d1, d2)
    span = (d2 - d1).days + 1
    prev = financial(tx, d1 - timedelta(days=span), d1 - timedelta(days=1))
    sales = _sales(tx, d1, d2)
    sellers = tx.list(SELLERS)
    active_ids = {s["seller_id"] for s in sales}
    hourly = [0.0] * 24
    for s in sales:
        if day_of(s["created_at"]) == today():
            hourly[int(s["created_at"][11:13])] += s["eff"]["total"]
    perf = []
    for sl in sellers:
        mine = [s for s in sales if s["seller_id"] == sl["id"]]
        if not mine and sl["status"] != "active":
            continue
        prev_total = sum(effective_sale(s)["total"] for s in tx.list(SALES) if s["seller_id"] == sl["id"] and in_range(s["created_at"], d1 - timedelta(days=span), d1 - timedelta(days=1)))
        total = sum(s["eff"]["total"] for s in mine)
        perf.append({"seller_id": sl["id"], "name": sl["name"], "sales": money(total), "quantity": sum(s["eff"]["qty"] for s in mine),
                     "cash_due": cash_summary(tx, sl["id"])["due"], "change_percent": round((total - prev_total) / prev_total * 100) if prev_total else None})
    inv = inventory_overview(tx)
    low_central = [{"product_id": p["product_id"], "name": p["name"], "warehouse": p["warehouse"]} for p in inv["products"] if p["low"]]
    low_seller = []
    for ss in tx.list(SELLER_STOCK):
        p = tx.get(PRODUCTS, ss["product_id"])
        if p and 0 < ss["qty"] <= max(p["low_stock_at"] / 4, 2):
            s = tx.get(SELLERS, ss["seller_id"])
            low_seller.append({"seller_name": s["name"] if s else "", "product": product_name(tx, ss["product_id"], ss["variant"]), "qty": ss["qty"]})
    pending_settlements = [r for r in list_for_date(tx, today() - timedelta(days=1), None) + list_for_date(tx, today(), None) if r["status"] in ("submitted", "review", "discrepancy")]
    return {
        "period": {"from": d1.isoformat(), "to": d2.isoformat()},
        "metrics": {
            "total_sales": fin["net_sales"], "previous_total_sales": prev["net_sales"],
            "gross_profit": fin["gross_profit"], "estimated_net_profit": fin["net_profit"],
            "cash_outstanding": money(sum(cash_summary(tx, s["id"])["due"] for s in sellers)),
            "seller_earnings": fin["seller_compensation"],
            "active_sellers": len(active_ids), "total_active_sellers": sum(1 for s in sellers if s["status"] == "active"),
        },
        "hourly_sales": [{"hour": h, "total": money(v)} for h, v in enumerate(hourly) if 7 <= h <= 21],
        "seller_performance": sorted(perf, key=lambda r: r["sales"], reverse=True),
        "recent_sales": list_sales(tx, period=period, admin=True)["items"][:6],
        "inventory_alerts": {
            "low_central_stock": low_central,
            "low_seller_stock": low_seller,
            "pending_transfers": sum(1 for a in tx.list(ASSIGNMENTS) if a["status"] == "pending_handover"),
            "damaged_units": inv["totals"]["damaged"],
        },
        "pending_actions": {
            "applications": sum(1 for a in tx.list("applications") if a["status"] in ("submitted", "under_review")),
            "cash_handovers": sum(1 for h in tx.list(HANDOVERS) if h["status"] == "pending"),
            "stock_returns": sum(1 for r in tx.list(RETURNS) if r["status"] in ("pending", "approved")),
            "settlements": len(pending_settlements),
            "corrections": sum(1 for c in tx.list(CORRECTIONS) if c["status"] in ("pending", "clarification")),
        },
        "unread_notifications": sum(1 for n in tx.list(NOTIFICATIONS) if n["audience"] == "admin" and not n["read"]),
    }


def seller_performance(tx: Tx, d1: date, d2: date) -> list[dict[str, Any]]:
    sales = _sales(tx, d1, d2)
    rows = []
    for sl in tx.list(SELLERS):
        mine = [s for s in sales if s["seller_id"] == sl["id"]]
        rows.append({"seller_id": sl["id"], "name": sl["name"], "total_sales": money(sum(s["eff"]["total"] for s in mine)),
                     "quantity": sum(s["eff"]["qty"] for s in mine), "gross_profit": money(sum(s["eff"]["gross_profit"] for s in mine)),
                     "compensation": money(sum(e["amount"] for e in tx.find(EARNINGS, lambda e: e["seller_id"] == sl["id"] and d1.isoformat() <= e["date"] <= d2.isoformat()))),
                     "cash_due": cash_summary(tx, sl["id"])["due"]})
    return sorted(rows, key=lambda r: r["total_sales"], reverse=True)


def product_performance(tx: Tx, d1: date, d2: date) -> list[dict[str, Any]]:
    sales = _sales(tx, d1, d2)
    inv = {p["product_id"]: p for p in inventory_overview(tx)["products"]}
    rows = []
    for p in tx.list(PRODUCTS):
        mine = [s for s in sales if s["product_id"] == p["id"]]
        revenue = money(sum(s["eff"]["total"] for s in mine))
        cogs = money(sum(s["unit_cost"] * s["eff"]["qty"] for s in mine))
        rows.append({"product_id": p["id"], "name": p["name"], "quantity_sold": sum(s["eff"]["qty"] for s in mine), "revenue": revenue,
                     "cost_of_goods_sold": cogs, "gross_profit": money(revenue - cogs), "margin_percent": round((revenue - cogs) / revenue * 100) if revenue else 0,
                     "remaining_stock": inv[p["id"]]["warehouse"] + inv[p["id"]]["with_sellers"]})
    return sorted(rows, key=lambda r: r["revenue"], reverse=True)


def seller_dashboard(tx: Tx, seller: dict[str, Any]) -> dict[str, Any]:
    t = today()
    mine = [s for s in tx.list(SALES) if s["seller_id"] == seller["id"] and day_of(s["created_at"]) == t]
    mine.sort(key=lambda s: s["created_at"], reverse=True)
    effs = [effective_sale(s) for s in mine]
    stocks = tx.find(SELLER_STOCK, lambda s: s["seller_id"] == seller["id"])
    low = []
    for ss in stocks:
        p = tx.get(PRODUCTS, ss["product_id"])
        if p and 0 < ss["qty"] <= max(p["low_stock_at"] / 4, 2):
            low.append(product_name(tx, ss["product_id"], ss["variant"]))

    return {
        "seller_name": seller["name"],
        "today_sales": money(sum(e["total"] for e in effs)),
        "sales_count": len(effs),
        "items_sold": sum(e["qty"] for e in effs),
        "today_earnings": earnings_summary(tx, seller["id"])["today"],
        "available_stock": sum(s["qty"] for s in stocks),
        "cash_to_submit": cash_summary(tx, seller["id"])["to_submit"],
        "last_sale_at": mine[0]["created_at"] if mine else None,
        "low_stock": low,
        "pending_handover_assignments": sum(1 for a in tx.list(ASSIGNMENTS) if a["seller_id"] == seller["id"] and a["status"] == "pending_handover"),
        "recent_sales": [sale_view(tx, s) for s in mine[:3]],
        "unread_notifications": sum(1 for n in tx.list(NOTIFICATIONS) if n["audience"] == f"seller:{seller['id']}" and not n["read"]),
    }


def nav_counts(tx: Tx) -> dict[str, int]:
    """Items waiting for an admin, keyed by panel route (sidebar badges)."""
    from .common import INV_APPS, INV_WITHDRAWALS
    pending_settlements = [r for r in list_for_date(tx, today() - timedelta(days=1), None) + list_for_date(tx, today(), None)
                           if r["status"] in ("submitted", "review", "discrepancy")]
    return {
        "/corrections": sum(1 for c in tx.list(CORRECTIONS) if c["status"] in ("pending", "clarification")),
        "/applications": sum(1 for a in tx.list("applications") if a["status"] in ("submitted", "under_review")),
        "/returns": sum(1 for r in tx.list(RETURNS) if r["status"] in ("pending", "approved")),
        "/cash": sum(1 for h in tx.list(HANDOVERS) if h["status"] == "pending"),
        "/settlements": len(pending_settlements),
        "/investors": sum(1 for a in tx.list(INV_APPS) if a["status"] in ("submitted", "under_review")),
        "/investor-withdrawals": sum(1 for w in tx.list(INV_WITHDRAWALS) if w["status"] == "pending"),
        "/activity": sum(1 for n in tx.list(NOTIFICATIONS) if n["audience"] == "admin" and not n["read"]),
    }
