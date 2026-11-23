"""Support chat: endpoints for sellers and investors (applicants too) and for admins."""

from typing import Literal

from fastapi import APIRouter

from ..core.deps import AdminDep, StoreDep, UserDep
from ..schemas import SupportMessageIn, SupportStartIn
from ..services import support

router = APIRouter(prefix="/support", tags=["সাপোর্ট চ্যাট (Support)"])
admin_router = APIRouter(prefix="/admin/support", tags=["অ্যাডমিন · সাপোর্ট চ্যাট"])


@router.get("/topics", summary="কোন কোন বিষয়ে প্রশ্ন করা যায়")
def topics(user: UserDep):
    return support.topics_for(user)


@router.get("/threads", summary="আমার কথোপকথন")
def my_threads(user: UserDep, store: StoreDep):
    with store.transaction() as tx:
        return support.my_threads(tx, user)


@router.post("/threads", status_code=201, summary="নতুন প্রশ্ন (প্রথম বার্তাসহ)")
def start(body: SupportStartIn, user: UserDep, store: StoreDep):
    with store.transaction() as tx:
        return support.start_thread(tx, user, body.topic, body.text, body.client_request_id)


@router.get("/threads/{thread_id}", summary="কথোপকথন ও বার্তা (খুললে 'পড়া হয়েছে')")
def thread(thread_id: str, user: UserDep, store: StoreDep):
    with store.transaction() as tx:
        return support.open_my_thread(tx, user, thread_id)


@router.post("/threads/{thread_id}/messages", summary="বার্তা পাঠান")
def reply(thread_id: str, body: SupportMessageIn, user: UserDep, store: StoreDep):
    with store.transaction() as tx:
        return support.user_reply(tx, user, thread_id, body.text, body.client_request_id)


@admin_router.get("/threads", summary="সব কথোপকথন (উত্তর বাকিগুলো আগে)")
def admin_threads(admin: AdminDep, store: StoreDep, status: Literal["open", "resolved"] | None = None,
                  kind: Literal["seller", "investor"] | None = None):
    with store.transaction() as tx:
        return support.admin_threads(tx, status, kind)


@admin_router.get("/threads/{thread_id}", summary="কথোপকথন খুলুন (খুললে 'পড়া হয়েছে')")
def admin_thread(thread_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return support.admin_open_thread(tx, thread_id)


@admin_router.post("/threads/{thread_id}/messages", summary="উত্তর দিন")
def admin_reply(thread_id: str, body: SupportMessageIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return support.admin_reply(tx, admin, thread_id, body.text, body.client_request_id)


@admin_router.post("/threads/{thread_id}/{action}", summary="সমাধান হয়েছে / আবার খুলুন")
def admin_status(thread_id: str, action: Literal["resolve", "reopen"], admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return support.set_status(tx, admin, thread_id, "resolved" if action == "resolve" else "open")
