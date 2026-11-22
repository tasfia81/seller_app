"""Request dependencies: current user and role checks."""

from dataclasses import dataclass
from typing import Annotated, Any

from fastapi import Depends, Header

from ..storage import Store, get_store
from .errors import Forbidden, Unauthorized
from .security import decode_token


def store_dep() -> Store:
    return get_store()


StoreDep = Annotated[Store, Depends(store_dep)]


def current_user(store: StoreDep, authorization: Annotated[str | None, Header()] = None) -> dict[str, Any]:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise Unauthorized("লগইন করুন।")
    payload = decode_token(authorization.split(" ", 1)[1].strip())
    with store.transaction() as tx:
        user = tx.get("users", payload["sub"])
    if not user or user.get("session_version", 0) != payload.get("sv"):
        raise Unauthorized("সেশন শেষ হয়েছে। আবার লগইন করুন।", code="session_revoked")
    if user["status"] == "disabled":
        raise Forbidden("এই অ্যাকাউন্ট বন্ধ আছে।", code="account_disabled")
    return user


UserDep = Annotated[dict[str, Any], Depends(current_user)]


def require_admin(user: UserDep) -> dict[str, Any]:
    if user["role"] != "admin":
        raise Forbidden("এই কাজ শুধু অ্যাডমিন করতে পারেন।")
    return user


AdminDep = Annotated[dict[str, Any], Depends(require_admin)]


@dataclass
class SellerCtx:
    user: dict[str, Any]
    seller: dict[str, Any]

    @property
    def id(self) -> str:
        return self.seller["id"]


def require_active_seller(user: UserDep, store: StoreDep) -> SellerCtx:
    if user["role"] != "seller":
        raise Forbidden("এই কাজ শুধু সেলার করতে পারেন।")
    if not user.get("seller_id"):
        raise Forbidden("আবেদন অনুমোদনের পর এই অংশ চালু হবে।", code="application_pending")
    with store.transaction() as tx:
        seller = tx.get("sellers", user["seller_id"])
    if not seller or seller["status"] != "active":
        raise Forbidden("আপনার সেলার অ্যাকাউন্ট এখন সক্রিয় নেই। অফিসে যোগাযোগ করুন।", code="seller_inactive")
    return SellerCtx(user=user, seller=seller)


SellerDep = Annotated[SellerCtx, Depends(require_active_seller)]


@dataclass
class InvestorCtx:
    user: dict[str, Any]
    investor: dict[str, Any]

    @property
    def id(self) -> str:
        return self.investor["id"]


def require_investor(user: UserDep, store: StoreDep) -> InvestorCtx:
    """Approved investors. Suspended investors can still read their numbers; write actions check status in the service."""
    if user["role"] != "investor":
        raise Forbidden("এই অংশ শুধু বিনিয়োগকারীদের জন্য।")
    if not user.get("investor_id"):
        raise Forbidden("আবেদন অনুমোদনের পর এই অংশ চালু হবে।", code="application_pending")
    with store.transaction() as tx:
        investor = tx.get("investors", user["investor_id"])
    if not investor:
        raise Forbidden("বিনিয়োগকারীর অ্যাকাউন্ট পাওয়া যায়নি।", code="investor_missing")
    return InvestorCtx(user=user, investor=investor)


InvestorDep = Annotated[InvestorCtx, Depends(require_investor)]
