"""Support chat: endpoints for sellers and investors (applicants too) and for admins."""

import asyncio
from typing import Literal

from fastapi import APIRouter, Request, WebSocket, WebSocketDisconnect
from starlette.concurrency import run_in_threadpool

from ..core.deps import AdminDep, StoreDep, UserDep
from ..core.errors import Forbidden
from ..core.security import decode_token
from ..storage import get_store
from ..schemas import SupportMessageIn, SupportStartIn
from ..services import support, support_live
from ..services.common import require

router = APIRouter(prefix="/support", tags=["সাপোর্ট চ্যাট (Support)"])
admin_router = APIRouter(prefix="/admin/support", tags=["অ্যাডমিন · সাপোর্ট চ্যাট"])


@router.post("/live-ticket")
def live_ticket(request: Request, user: UserDep):
    if user["role"] not in ("seller", "investor", "admin"):
        raise Forbidden("সাপোর্ট চ্যাটের অনুমতি নেই।")
    session = decode_token(request.headers["authorization"].split(" ", 1)[1].strip())
    return {"ticket": support_live.issue_ticket(user, session["exp"])}


@router.websocket("/live")
async def live(websocket: WebSocket):
    await websocket.accept()
    try:
        # Send the one-use ticket as a frame so it never enters URL/access logs.
        frame = await asyncio.wait_for(websocket.receive(), timeout=5)
        if frame["type"] == "websocket.disconnect":
            return
        ticket = frame.get("text")
        identity = support_live.redeem_ticket(ticket) if ticket else None
        store = get_store()
        if identity is None or not await run_in_threadpool(identity.is_current, store):
            await websocket.close(code=1008)
            return
        subscriber = support_live.subscribe(identity)
        try:
            await websocket.send_text("ready")
            receiving = asyncio.create_task(websocket.receive())
            updated = asyncio.create_task(subscriber.updated.wait())
            try:
                while True:
                    await asyncio.wait({receiving, updated}, timeout=25, return_when=asyncio.FIRST_COMPLETED)
                    if receiving.done():
                        # The protocol is server-to-client after authentication.
                        if receiving.result()["type"] != "websocket.disconnect":
                            await websocket.close(code=1008)
                        break
                    if not await run_in_threadpool(identity.is_current, store):
                        await websocket.close(code=1008)
                        break
                    if updated.done():
                        subscriber.updated.clear()
                        updated = asyncio.create_task(subscriber.updated.wait())
                        await websocket.send_text("changed")
                    else:
                        await websocket.send_text("heartbeat")
            finally:
                for task in (receiving, updated):
                    task.cancel()
                await asyncio.gather(receiving, updated, return_exceptions=True)
        finally:
            support_live.unsubscribe(subscriber)
    except TimeoutError:
        await websocket.close(code=1008)
    except (WebSocketDisconnect, asyncio.CancelledError):
        pass


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
        result = support.start_thread(tx, user, body.topic, body.text, body.client_request_id)
    support_live.publish(user["id"])
    return result


@router.get("/threads/{thread_id}", summary="কথোপকথন ও বার্তা (খুললে 'পড়া হয়েছে')")
def thread(thread_id: str, user: UserDep, store: StoreDep):
    with store.transaction() as tx:
        return support.open_my_thread(tx, user, thread_id)


@router.post("/threads/{thread_id}/messages", summary="বার্তা পাঠান")
def reply(thread_id: str, body: SupportMessageIn, user: UserDep, store: StoreDep):
    with store.transaction() as tx:
        result = support.user_reply(tx, user, thread_id, body.text, body.client_request_id)
    support_live.publish(user["id"])
    return result


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
        result = support.admin_reply(tx, admin, thread_id, body.text, body.client_request_id)
        owner = require(tx, support.THREADS, thread_id)["owner_user_id"]
    support_live.publish(owner)
    return result


@admin_router.post("/threads/{thread_id}/{action}", summary="সমাধান হয়েছে / আবার খুলুন")
def admin_status(thread_id: str, action: Literal["resolve", "reopen"], admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        result = support.set_status(tx, admin, thread_id, "resolved" if action == "resolve" else "open")
        owner = require(tx, support.THREADS, thread_id)["owner_user_id"]
    support_live.publish(owner)
    return result
