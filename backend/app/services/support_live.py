"""Process-local delivery hints for persisted support updates."""

import asyncio
from dataclasses import dataclass
from secrets import token_urlsafe
from threading import Lock
from time import monotonic, time

from ..storage import Store


@dataclass(frozen=True)
class Identity:
    user_id: str
    role: str
    session_version: int
    expires_at: float

    def is_current(self, store: Store) -> bool:
        if time() >= self.expires_at:
            return False
        with store.transaction() as tx:
            user = tx.get("users", self.user_id)
        return bool(user and user["role"] == self.role and user["status"] != "disabled"
                    and user.get("session_version", 0) == self.session_version)


@dataclass(eq=False)
class Subscriber:
    identity: Identity
    loop: asyncio.AbstractEventLoop
    updated: asyncio.Event


_lock = Lock()
_tickets: dict[str, tuple[float, Identity]] = {}
_subscribers: set[Subscriber] = set()
ADMIN = "admin"


def issue_ticket(user: dict, expires_at: float) -> str:
    identity = Identity(user["id"], user["role"], user.get("session_version", 0), expires_at)
    ticket = token_urlsafe(32)
    now = monotonic()
    with _lock:
        for key, (deadline, _) in tuple(_tickets.items()):
            if deadline <= now:
                del _tickets[key]
        _tickets[ticket] = (now + 30, identity)
    return ticket


def redeem_ticket(ticket: str) -> Identity | None:
    with _lock:
        entry = _tickets.pop(ticket, None)
    return entry[1] if entry and entry[0] > monotonic() else None


def subscribe(identity: Identity) -> Subscriber:
    subscriber = Subscriber(identity, asyncio.get_running_loop(), asyncio.Event())
    with _lock:
        _subscribers.add(subscriber)
    return subscriber


def unsubscribe(subscriber: Subscriber) -> None:
    with _lock:
        _subscribers.discard(subscriber)


def publish(owner_id: str | None) -> None:
    with _lock:
        recipients = tuple(s for s in _subscribers
                           if s.identity.role == ADMIN or s.identity.user_id == owner_id)
    for subscriber in recipients:
        try:
            subscriber.loop.call_soon_threadsafe(subscriber.updated.set)
        except RuntimeError:
            unsubscribe(subscriber)  # Its server loop has already shut down.
