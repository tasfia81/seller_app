"""Single-use SMS verification and recovery for app accounts."""

import hashlib
import hmac
import secrets
import time

import httpx

from ..core.config import settings
from ..core.errors import AppError, NotImplementedYet
from ..core.security import hash_password
from ..core.utils import is_bd_mobile, normalize_mobile
from ..storage import Store, Tx
from .auth import find_user
from .common import USERS
from .sms import send_otp

CHALLENGES = "seller_password_recovery"
TTL = 300
RESEND_AFTER = 60
MAX_ATTEMPTS = 5


def _mobile(value: str) -> str:
    if not settings.bulksmsbd_api_key:
        raise NotImplementedYet("পাসওয়ার্ড পুনরুদ্ধারের SMS সেবা এখনো চালু হয়নি।", code="otp_not_available")
    if not is_bd_mobile(value):
        raise AppError("সঠিক মোবাইল নম্বর দিন।", code="invalid_mobile")
    return normalize_mobile(value)


def _digest(nonce: str, code: str) -> str:
    return hmac.new(settings.secret_key.encode(), f"seller-reset:{nonce}:{code}".encode(), hashlib.sha256).hexdigest()


def request(store: Store, value: str, *, signup: bool = False, role: str = "seller") -> None:
    mobile = _mobile(value)
    now = int(time.time())
    code = f"{secrets.randbelow(1_000_000):06d}"
    nonce = secrets.token_hex(16)
    challenge_id = _challenge_id(mobile, role, signup)
    with store.transaction() as tx:
        user = find_user(tx, mobile)
        previous = tx.get(CHALLENGES, challenge_id)
        if previous and previous["resend_at"] > now:
            return
        eligible = user is None if signup else (
            user is not None and user["role"] == role and user["status"] != "disabled"
        )
        tx.put(CHALLENGES, {
            "id": challenge_id,
            "user_id": user["id"] if eligible and user else None,
            "session_version": user.get("session_version", 0) if eligible and user else None,
            "nonce": nonce,
            "digest": _digest(nonce, code),
            "expires_at": now + TTL,
            "resend_at": now + RESEND_AFTER,
            "attempts": 0,
        })
    if eligible:
        with httpx.Client() as client:
            send_otp(client, mobile, code)


def reset(store: Store, value: str, code: str, password: str, *, role: str = "seller") -> None:
    mobile = _mobile(value)
    if not any(char.isdigit() for char in password):
        raise AppError("পাসওয়ার্ডে অন্তত একটি সংখ্যা দিন।", code="invalid_password")
    changed = False
    challenge_id = _challenge_id(mobile, role)
    with store.transaction() as tx:
        challenge = tx.get(CHALLENGES, challenge_id)
        if challenge and challenge["expires_at"] > int(time.time()) and challenge["attempts"] < MAX_ATTEMPTS:
            user = tx.get(USERS, challenge["user_id"]) if challenge["user_id"] else None
            if (
                user
                and user["mobile"] == mobile
                and user["role"] == role
                and user["status"] != "disabled"
                and user.get("session_version", 0) == challenge["session_version"]
                and hmac.compare_digest(challenge["digest"], _digest(challenge["nonce"], code))
            ):
                user["password_hash"] = hash_password(password)
                user["session_version"] = user.get("session_version", 0) + 1
                tx.put(USERS, user)
                tx.delete(CHALLENGES, challenge_id)
                changed = True
            else:
                challenge["attempts"] += 1
                tx.put(CHALLENGES, challenge)
    if not changed:
        raise AppError("কোডটি ভুল অথবা মেয়াদ শেষ হয়েছে।", code="invalid_otp")


def _challenge_id(mobile: str, role: str, signup: bool = False) -> str:
    prefix = "" if role == "seller" else f"{role}-"
    return f"{prefix}signup-{mobile}" if signup else f"{prefix}{mobile}"


def verify_signup(tx: Tx, mobile: str, code: str | None, *, role: str = "seller") -> bool:
    challenge = tx.get(CHALLENGES, _challenge_id(mobile, role, signup=True))
    if not challenge or challenge["expires_at"] <= int(time.time()) or challenge["attempts"] >= MAX_ATTEMPTS:
        return False
    if code and hmac.compare_digest(challenge["digest"], _digest(challenge["nonce"], code)):
        tx.delete(CHALLENGES, challenge["id"])
        return True
    challenge["attempts"] += 1
    tx.put(CHALLENGES, challenge)
    return False
