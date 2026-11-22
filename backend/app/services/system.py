"""Notifications, audit log and business settings."""

from typing import Any

from ..core.errors import AppError
from ..core.utils import new_id, now_iso
from ..schemas import MessageIn
from ..storage import Tx
from .common import AUDIT, INVESTORS, NOTIFICATIONS, SELLERS, SETTINGS, audit, notify

MESSAGES = "admin_messages"

DEFAULT_SETTINGS: dict[str, Any] = {
    "id": "main",
    "business": {"name": "স্ট্রিট সেলস", "phone": "", "address": "", "currency": "BDT", "timezone": "Asia/Dhaka"},
    "inventory": {"default_policy": "daily_return", "low_stock_default": 10, "require_handover_accept": True,
                  "require_return_receipt": True, "close_requires_cash": True, "close_requires_returns": True},
    "payments": {
        "cash": {"enabled": True, "destination": "seller"},
        "bkash": {"enabled": True, "destination": "business"},
        "nagad": {"enabled": True, "destination": "business"},
        "bank": {"enabled": False, "destination": "business"},
        "other": {"enabled": False, "destination": "seller"},
    },
    "onboarding": {"minimum_age": 18, "default_compensation": {"model": "profit", "profit_percent": 40}},
    "investor_terms": {"share_percent": 50.0, "payout_day": 5, "notice_days": 30},
}


def get_settings(tx: Tx) -> dict[str, Any]:
    return tx.get(SETTINGS, "main") or DEFAULT_SETTINGS


def update_settings(tx: Tx, admin: dict[str, Any], changes: dict[str, Any]) -> dict[str, Any]:
    current = get_settings(tx)
    for section, values in changes.items():
        if values is not None:
            current[section] = {**current.get(section, {}), **values}
    tx.put(SETTINGS, current)
    audit(tx, admin, "settings.updated", "settings", ", ".join(k for k, v in changes.items() if v is not None))
    return current


def list_notifications(tx: Tx, audience: str, unread_only: bool = False) -> list[dict[str, Any]]:
    items = tx.find(NOTIFICATIONS, lambda n: n["audience"] == audience and (not unread_only or not n["read"]))
    return sorted(items, key=lambda n: n["at"], reverse=True)


def mark_read(tx: Tx, audience: str, notification_id: str | None = None) -> int:
    count = 0
    for n in tx.find(NOTIFICATIONS, lambda n: n["audience"] == audience and not n["read"] and (notification_id is None or n["id"] == notification_id)):
        n["read"] = True
        tx.put(NOTIFICATIONS, n)
        count += 1
    return count


def list_audit(tx: Tx, action: str | None = None, actor_id: str | None = None, limit: int = 200) -> list[dict[str, Any]]:
    items = tx.find(AUDIT, lambda a: (not action or a["action"].startswith(action)) and (not actor_id or a["actor_id"] == actor_id))
    return sorted(items, key=lambda a: a["at"], reverse=True)[:limit]


# ---------- admin → seller / investor messages ----------
def _recipients(tx: Tx, data: MessageIn) -> list[tuple[str, str]]:
    """(audience, name) pairs. Only active accounts receive broadcasts."""
    sellers = {s["id"]: s for s in tx.list(SELLERS)}
    investors = {i["id"]: i for i in tx.list(INVESTORS)}
    if data.audience in ("sellers", "investors"):
        pool = sellers if data.audience == "sellers" else investors
        prefix = "seller" if data.audience == "sellers" else "investor"
        if not data.recipient_ids:
            raise AppError("কাকে পাঠাবেন বাছুন।", code="no_recipients")
        missing = [i for i in data.recipient_ids if i not in pool]
        if missing:
            raise AppError("কিছু প্রাপক পাওয়া যায়নি।", code="unknown_recipients", details={"missing": missing})
        return [(f"{prefix}:{i}", pool[i]["name"]) for i in dict.fromkeys(data.recipient_ids)]
    out: list[tuple[str, str]] = []
    if data.audience in ("all_sellers", "everyone"):
        out += [(f"seller:{s['id']}", s["name"]) for s in sellers.values() if s["status"] == "active"]
    if data.audience in ("all_investors", "everyone"):
        out += [(f"investor:{i['id']}", i["name"]) for i in investors.values() if i["status"] == "active"]
    if not out:
        raise AppError("পাঠানোর মতো কোনো সক্রিয় প্রাপক নেই।", code="no_recipients")
    return out


def send_message(tx: Tx, admin: dict[str, Any], data: MessageIn) -> dict[str, Any]:
    """In-app notification to each recipient. Same client_request_id returns the first result (no double send)."""
    existing = tx.first(MESSAGES, lambda m: m.get("client_request_id") == data.client_request_id)
    if existing:
        return {**existing, "duplicate": True}
    recipients = _recipients(tx, data)
    for audience, _ in recipients:
        notify(tx, audience, "admin_message", data.title, data.body)
    msg = {"id": new_id("msg"), "audience": data.audience, "title": data.title, "body": data.body, "recipient_count": len(recipients),
           "recipients": [name for _, name in recipients][:50], "client_request_id": data.client_request_id, "by": admin["name"], "at": now_iso()}
    tx.put(MESSAGES, msg)
    audit(tx, admin, "message.sent", msg["id"], f"{data.title} · {len(recipients)} জন")
    return {**msg, "duplicate": False}


def list_messages(tx: Tx, limit: int = 100) -> list[dict[str, Any]]:
    items = sorted(reversed(tx.list(MESSAGES)), key=lambda m: m["at"], reverse=True)  # newest first, ties too
    return [{k: v for k, v in m.items() if k != "client_request_id"} for m in items[:limit]]
