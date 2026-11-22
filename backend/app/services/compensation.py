"""Seller compensation rules. The server is the only place commissions are calculated."""

from typing import Any

from ..core.utils import money, today


def current_rule(seller: dict[str, Any], on: str | None = None) -> dict[str, Any]:
    """The rule in force on a date (ISO). Rules with a future effective date wait their turn,
    so past earnings are never recalculated with a newer rule."""
    day = on or today().isoformat()
    history = [h for h in seller.get("compensation_history", []) if h.get("effective_from") and h["effective_from"] <= day]
    if not history:
        return seller["compensation"]
    return max(history, key=lambda h: (h["effective_from"], h.get("at", "")))["to"]


def rule_text(rule: dict[str, Any]) -> str:
    m = rule["model"]
    if m == "profit":
        return f"আপনি বিক্রির লাভের {rule['profit_percent']:g}% কমিশন পাবেন।"
    if m == "daily":
        return f"আপনার অনুমোদিত দৈনিক বেতন ৳{rule['daily_wage']:g}।"
    if m == "per_unit":
        return f"প্রতি বিক্রিত ইউনিটে ৳{rule['per_unit']:g} কমিশন পাবেন।"
    parts = []
    if rule.get("daily_wage"):
        parts.append(f"দৈনিক ৳{rule['daily_wage']:g}")
    if rule.get("profit_percent"):
        parts.append(f"লাভের {rule['profit_percent']:g}%")
    if rule.get("per_unit"):
        parts.append(f"প্রতি ইউনিটে ৳{rule['per_unit']:g}")
    return "আপনার আয়: " + " + ".join(parts) + "।"


def short_label(rule: dict[str, Any]) -> str:
    return rule_text(rule).replace("আপনি বিক্রির ", "").replace("আপনার আয়: ", "").rstrip("।")


def sale_commission(rule: dict[str, Any], product: dict[str, Any], qty: float, unit_price: float, unit_cost: float) -> float:
    """Commission for one sale. Daily wage is added once per worked day at settlement."""
    override = (product.get("commission_override") or {})
    percent = override.get("profit_percent", rule.get("profit_percent") or 0)
    per_unit = override.get("per_unit", rule.get("per_unit") or 0)
    m = rule["model"]
    amount = 0.0
    if m in ("profit", "hybrid") and percent:
        amount += max(unit_price - unit_cost, 0) * qty * percent / 100
    if m in ("per_unit", "hybrid") and per_unit:
        amount += per_unit * qty
    return money(amount)


def daily_wage(rule: dict[str, Any]) -> float:
    return money(rule.get("daily_wage") or 0) if rule["model"] in ("daily", "hybrid") else 0.0
