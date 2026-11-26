"""Password login for Street Sales accounts."""

from typing import Any

from ..core.errors import AppError, Forbidden, Unauthorized
from ..core.security import create_token, hash_password, verify_password
from ..core.utils import normalize_mobile
from ..storage import Tx
from .common import SELLERS, USERS


def find_user(tx: Tx, identifier: str) -> dict[str, Any] | None:
    ident = identifier.strip().lower()
    if "@" in ident:
        return tx.first(USERS, lambda u: (u.get("email") or "").lower() == ident)
    mobile = normalize_mobile(ident)
    return tx.first(USERS, lambda u: u.get("mobile") == mobile)


def public_user(tx: Tx, user: dict[str, Any]) -> dict[str, Any]:
    out = {k: user.get(k) for k in ("id", "role", "name", "mobile", "email", "status", "seller_id", "investor_id", "application_id")}
    if user.get("seller_id"):
        seller = tx.get(SELLERS, user["seller_id"])
        out["seller_status"] = seller["status"] if seller else None
    return out


def login(tx: Tx, identifier: str, password: str) -> dict[str, Any]:
    user = find_user(tx, identifier)
    if not user or not verify_password(password, user["password_hash"]):
        raise Unauthorized("মোবাইল নম্বর/ইমেইল বা পাসওয়ার্ড সঠিক নয়।", code="invalid_credentials")
    if user["status"] == "disabled":
        raise Forbidden("এই অ্যাকাউন্ট বন্ধ আছে। অফিসে যোগাযোগ করুন।", code="account_disabled")
    token = create_token(user["id"], user["role"], user.get("session_version", 0))
    return {"access_token": token, "token_type": "bearer", "user": public_user(tx, user)}


def _active_session(tx: Tx, session_user: dict[str, Any]) -> dict[str, Any]:
    user = tx.get(USERS, session_user["id"])
    if not user or user.get("session_version", 0) != session_user.get("session_version", 0):
        raise Unauthorized("সেশন শেষ হয়েছে। আবার লগইন করুন।", code="session_revoked")
    return user


def change_password(tx: Tx, session_user: dict[str, Any], current: str, password: str) -> None:
    user = _active_session(tx, session_user)
    if not verify_password(current, user["password_hash"]):
        raise AppError("বর্তমান পাসওয়ার্ড সঠিক নয়।", code="invalid_password")
    if not any(char.isdigit() for char in password):
        raise AppError("পাসওয়ার্ডে অন্তত একটি সংখ্যা দিন।", code="invalid_password")
    user["password_hash"] = hash_password(password)
    user["session_version"] = user.get("session_version", 0) + 1
    tx.put(USERS, user)


def revoke_sessions(tx: Tx, session_user: dict[str, Any]) -> None:
    user = _active_session(tx, session_user)
    user["session_version"] = user.get("session_version", 0) + 1
    tx.put(USERS, user)
