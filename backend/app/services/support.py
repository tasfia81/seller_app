"""Support chat: sellers and investors write to the office; admins reply.

One thread per question (with a topic). The office can mark it resolved; a new
message from the user opens it again. Messages are plain text for now.
"""

from typing import Any

from ..core.errors import AppError, Forbidden
from ..core.utils import new_id, now_iso
from ..storage import Tx
from .common import audit, notify, require

THREADS = "support_threads"
MESSAGES = "support_messages"

TOPICS = {
    "profit": "লাভ ও লাভের টাকা",
    "investment": "বিনিয়োগ ও মূলধন",
    "stock": "স্টক ও পণ্য",
    "sales": "বিক্রি ও হিসাব",
    "cash": "ক্যাশ ও পেমেন্ট",
    "account": "অ্যাকাউন্ট ও যাচাই",
    "other": "অন্য কিছু",
}
TOPICS_BY_ROLE = {
    "seller": ["stock", "sales", "cash", "account", "other"],
    "investor": ["profit", "investment", "stock", "account", "other"],
}
STATUS_LABEL = {"open": "খোলা", "resolved": "সমাধান হয়েছে"}


def _owner(user: dict[str, Any]) -> dict[str, Any]:
    if user["role"] not in TOPICS_BY_ROLE:
        raise Forbidden("সাপোর্ট চ্যাট শুধু সেলার ও বিনিয়োগকারীদের জন্য।")
    return user


def _audience(thread: dict[str, Any]) -> str | None:
    """Where the user's in-app notification goes (applicants have none yet)."""
    if thread["owner_kind"] == "seller" and thread.get("seller_id"):
        return f"seller:{thread['seller_id']}"
    if thread["owner_kind"] == "investor" and thread.get("investor_id"):
        return f"investor:{thread['investor_id']}"
    return None


def thread_view(t: dict[str, Any], *, for_admin: bool) -> dict[str, Any]:
    out = {
        "id": t["id"], "topic": t["topic"], "topic_label": TOPICS.get(t["topic"], t["topic"]), "status": t["status"],
        "status_label": STATUS_LABEL[t["status"]], "created_at": t["created_at"], "updated_at": t["updated_at"],
        "last_message": t["last_message"], "last_from": t["last_from"],
        "unread": t["unread_admin"] if for_admin else t["unread_user"],
    }
    if for_admin:
        out.update({"owner_kind": t["owner_kind"], "owner_name": t["owner_name"], "owner_mobile": t["owner_mobile"],
                    "seller_id": t.get("seller_id"), "investor_id": t.get("investor_id"), "is_applicant": t.get("is_applicant", False)})
    return out


def _messages(tx: Tx, thread_id: str) -> list[dict[str, Any]]:
    items = [m for m in tx.list(MESSAGES) if m["thread_id"] == thread_id]
    items.sort(key=lambda m: m["at"])
    return [{k: m[k] for k in ("id", "sender", "author", "text", "at")} for m in items]


def _add_message(tx: Tx, t: dict[str, Any], sender: str, author: str, text: str, request_id: str) -> dict[str, Any] | None:
    """Returns None when the same client_request_id was already stored (double tap / retry)."""
    if tx.first(MESSAGES, lambda m: m["thread_id"] == t["id"] and m["client_request_id"] == request_id):
        return None
    msg = {"id": new_id("sm"), "thread_id": t["id"], "sender": sender, "author": author, "text": text, "at": now_iso(), "client_request_id": request_id}
    tx.put(MESSAGES, msg)
    t["last_message"] = text[:140]
    t["last_from"] = sender
    t["updated_at"] = msg["at"]
    if sender == "user":
        t["unread_admin"] += 1
        t["status"] = "open"  # a new question re-opens a resolved thread
    else:
        t["unread_user"] += 1
    tx.put(THREADS, t)
    return msg


def _check_text(text: str) -> str:
    text = text.strip()
    if not text:
        raise AppError("বার্তা লিখুন।", code="empty_message")
    if len(text) > 2000:
        raise AppError("বার্তা ২০০০ অক্ষরের মধ্যে রাখুন।", code="message_too_long")
    return text


# ---------------------------------------------------------------- seller / investor
def topics_for(user: dict[str, Any]) -> list[dict[str, str]]:
    return [{"id": k, "label": TOPICS[k]} for k in TOPICS_BY_ROLE[_owner(user)["role"]]]


def my_threads(tx: Tx, user: dict[str, Any]) -> list[dict[str, Any]]:
    _owner(user)
    items = [t for t in tx.list(THREADS) if t["owner_user_id"] == user["id"]]
    items.sort(key=lambda t: t["updated_at"], reverse=True)
    return [thread_view(t, for_admin=False) for t in items]


def start_thread(tx: Tx, user: dict[str, Any], topic: str, text: str, request_id: str) -> dict[str, Any]:
    _owner(user)
    if topic not in TOPICS_BY_ROLE[user["role"]]:
        raise AppError("এই বিষয়টি বাছা যাবে না।", code="invalid_topic")
    text = _check_text(text)
    existing = tx.first(THREADS, lambda t: t["owner_user_id"] == user["id"] and t.get("client_request_id") == request_id)
    if existing:
        return {**thread_view(existing, for_admin=False), "messages": _messages(tx, existing["id"])}
    now = now_iso()
    t = {
        "id": new_id("st"), "owner_user_id": user["id"], "owner_kind": user["role"], "owner_name": user["name"], "owner_mobile": user.get("mobile"),
        "seller_id": user.get("seller_id"), "investor_id": user.get("investor_id"), "is_applicant": not (user.get("seller_id") or user.get("investor_id")),
        "topic": topic, "status": "open", "created_at": now, "updated_at": now, "last_message": "", "last_from": "user",
        "unread_admin": 0, "unread_user": 0, "client_request_id": request_id,
    }
    tx.put(THREADS, t)
    _add_message(tx, t, "user", user["name"], text, request_id)
    who = "সেলার" if user["role"] == "seller" else "বিনিয়োগকারী"
    notify(tx, "admin", "support_new", f"নতুন সাপোর্ট প্রশ্ন · {TOPICS[topic]}", f"{user['name']} ({who}): {text[:80]}", f"/support?id={t['id']}")
    return {**thread_view(t, for_admin=False), "messages": _messages(tx, t["id"])}


def _my_thread(tx: Tx, user: dict[str, Any], thread_id: str) -> dict[str, Any]:
    _owner(user)
    t = require(tx, THREADS, thread_id, "কথোপকথন পাওয়া যায়নি।")
    if t["owner_user_id"] != user["id"]:
        raise Forbidden("এই কথোপকথন আপনার নয়।")
    return t


def open_my_thread(tx: Tx, user: dict[str, Any], thread_id: str) -> dict[str, Any]:
    t = _my_thread(tx, user, thread_id)
    if t["unread_user"]:
        t["unread_user"] = 0
        tx.put(THREADS, t)
    return {**thread_view(t, for_admin=False), "messages": _messages(tx, t["id"])}


def user_reply(tx: Tx, user: dict[str, Any], thread_id: str, text: str, request_id: str) -> dict[str, Any]:
    t = _my_thread(tx, user, thread_id)
    text = _check_text(text)
    was_resolved = t["status"] == "resolved"
    if _add_message(tx, t, "user", user["name"], text, request_id):
        title = "সাপোর্ট কথোপকথন আবার খোলা হয়েছে" if was_resolved else "সাপোর্টে নতুন বার্তা"
        notify(tx, "admin", "support_message", title, f"{user['name']}: {text[:80]}", f"/support?id={t['id']}")
    return {**thread_view(t, for_admin=False), "messages": _messages(tx, t["id"])}


# ---------------------------------------------------------------- admin
def admin_threads(tx: Tx, status: str | None = None, kind: str | None = None) -> dict[str, Any]:
    all_items = tx.list(THREADS)
    items = [t for t in all_items if (not status or t["status"] == status) and (not kind or t["owner_kind"] == kind)]
    # Unanswered first (user spoke last), then newest.
    items.sort(key=lambda t: (t["status"] == "open" and t["last_from"] == "user", t["updated_at"]), reverse=True)
    return {
        "counts": {
            "open": sum(1 for t in all_items if t["status"] == "open"),
            "waiting": sum(1 for t in all_items if t["status"] == "open" and t["last_from"] == "user"),
            "resolved": sum(1 for t in all_items if t["status"] == "resolved"),
        },
        "items": [thread_view(t, for_admin=True) for t in items],
    }


def admin_open_thread(tx: Tx, thread_id: str) -> dict[str, Any]:
    t = require(tx, THREADS, thread_id, "কথোপকথন পাওয়া যায়নি।")
    if t["unread_admin"]:
        t["unread_admin"] = 0
        tx.put(THREADS, t)
    return {**thread_view(t, for_admin=True), "messages": _messages(tx, t["id"])}


def admin_reply(tx: Tx, admin: dict[str, Any], thread_id: str, text: str, request_id: str) -> dict[str, Any]:
    t = require(tx, THREADS, thread_id, "কথোপকথন পাওয়া যায়নি।")
    text = _check_text(text)
    if _add_message(tx, t, "admin", admin["name"], text, request_id):
        t["unread_admin"] = 0
        tx.put(THREADS, t)
        audience = _audience(t)
        if audience:
            notify(tx, audience, "support_reply", "সাপোর্ট থেকে উত্তর এসেছে", text[:100])
    return admin_open_thread(tx, thread_id)


def set_status(tx: Tx, admin: dict[str, Any], thread_id: str, status: str) -> dict[str, Any]:
    t = require(tx, THREADS, thread_id, "কথোপকথন পাওয়া যায়নি।")
    if t["status"] != status:
        t["status"] = status
        t["updated_at"] = now_iso()
        tx.put(THREADS, t)
        audit(tx, admin, f"support.{status}", t["id"], f"{t['owner_name']} · {TOPICS.get(t['topic'], t['topic'])}")
    return admin_open_thread(tx, thread_id)


def waiting_count(tx: Tx) -> int:
    """Open threads whose last message is from the user (sidebar badge)."""
    return sum(1 for t in tx.list(THREADS) if t["status"] == "open" and t["last_from"] == "user")
