"""Login for admins and sellers. OTP / password recovery is NOT simulated."""

from typing import Any

from ..core.errors import Forbidden, NotImplementedYet, Unauthorized
from ..core.security import create_token, verify_password
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
    out = {k: user.get(k) for k in ("id", "role", "name", "mobile", "email", "status", "seller_id", "application_id")}
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


def request_password_otp() -> None:
    raise NotImplementedYet("পাসওয়ার্ড পুনরুদ্ধারের কোড পাঠানোর সেবা এখনো চালু হয়নি। অফিসে যোগাযোগ করুন।", code="otp_not_available")
