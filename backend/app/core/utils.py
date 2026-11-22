"""Small shared helpers: ids, time, money rounding, masking."""

import re
import secrets
from datetime import date, datetime, timedelta

from .config import DHAKA


def now() -> datetime:
    return datetime.now(DHAKA)


def now_iso() -> str:
    return now().isoformat(timespec="seconds")


def today() -> date:
    return now().date()


def new_id(prefix: str) -> str:
    return f"{prefix}_{secrets.token_hex(6)}"


def money(value: float) -> float:
    """Round to paisa. (Switch to integer paisa or Decimal when moving to Firestore.)"""
    return round(float(value) + 0.0, 2)


def day_of(iso: str) -> date:
    return datetime.fromisoformat(iso).astimezone(DHAKA).date()


def period_range(period: str, start: date | None = None, end: date | None = None) -> tuple[date, date]:
    """today | yesterday | last7 | month | custom → inclusive (from, to) dates."""
    t = today()
    if period == "yesterday":
        y = t - timedelta(days=1)
        return y, y
    if period in ("last7", "7d", "week"):
        return t - timedelta(days=6), t
    if period == "month":
        return t.replace(day=1), t
    if period == "custom" and start and end:
        return start, end
    return t, t


def in_range(iso: str, start: date, end: date) -> bool:
    d = day_of(iso)
    return start <= d <= end


def normalize_mobile(value: str) -> str:
    bn = "০১২৩৪৫৬৭৮৯"
    ascii_digits = "".join(str(bn.index(c)) if c in bn else c for c in value)
    digits = re.sub(r"\D", "", ascii_digits)
    return digits[2:] if digits.startswith("88") and len(digits) == 13 else digits


def is_bd_mobile(value: str) -> bool:
    return bool(re.fullmatch(r"01[3-9]\d{8}", normalize_mobile(value)))


def mask_nid(nid: str) -> str:
    digits = re.sub(r"\D", "", nid)
    return f"•••• •••• {digits[-4:]}" if digits else ""


def mask_mobile(mobile: str) -> str:
    m = normalize_mobile(mobile)
    return f"{m[:3]}XXXX{m[-4:]}" if len(m) == 11 else m
