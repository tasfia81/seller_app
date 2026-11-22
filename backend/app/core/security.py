"""Password hashing and signed login tokens (standard library only).

Passwords: PBKDF2-SHA256 with a random salt — plaintext is never stored.
Tokens:    base64url(payload).base64url(HMAC-SHA256 signature). When Firebase
           Auth is connected later, replace `create_token` / `decode_token`.
"""

import base64
import hashlib
import hmac
import json
import secrets
from datetime import datetime, timedelta, timezone

from .config import settings
from .errors import Unauthorized

_ITERATIONS = 240_000


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, _ITERATIONS)
    return f"pbkdf2${_ITERATIONS}${salt.hex()}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        _, iterations, salt_hex, digest_hex = stored.split("$")
    except ValueError:
        return False
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), bytes.fromhex(salt_hex), int(iterations))
    return hmac.compare_digest(digest.hex(), digest_hex)


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _unb64(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def _sign(body: str) -> str:
    return _b64(hmac.new(settings.secret_key.encode(), body.encode(), hashlib.sha256).digest())


def create_token(user_id: str, role: str, session_version: int) -> str:
    exp = datetime.now(timezone.utc) + timedelta(hours=settings.token_ttl_hours)
    body = _b64(json.dumps({"sub": user_id, "role": role, "sv": session_version, "exp": int(exp.timestamp())}).encode())
    return f"{body}.{_sign(body)}"


def decode_token(token: str) -> dict:
    try:
        body, signature = token.split(".")
    except ValueError as exc:
        raise Unauthorized("লগইন সেশন সঠিক নয়। আবার লগইন করুন।") from exc
    if not hmac.compare_digest(signature, _sign(body)):
        raise Unauthorized("লগইন সেশন সঠিক নয়। আবার লগইন করুন।")
    payload = json.loads(_unb64(body))
    if payload.get("exp", 0) < datetime.now(timezone.utc).timestamp():
        raise Unauthorized("লগইনের মেয়াদ শেষ। আবার লগইন করুন।", code="token_expired")
    return payload
