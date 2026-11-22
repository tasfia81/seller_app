"""Notifications, audit log and business settings."""

from typing import Any

from ..storage import Tx
from .common import AUDIT, NOTIFICATIONS, SETTINGS, audit

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
