"""Endpoints used by the Investor mobile app."""

from typing import Literal

from fastapi import APIRouter, File, UploadFile

from ..core.deps import InvestorDep, StoreDep, UserDep
from ..core.errors import Forbidden
from ..schemas_investor import InvestorApplicationIn, MobileCheckIn, PreferenceIn, WithdrawalRequestIn
from ..services import auth, investors, system
from .uploads import save_image

router = APIRouter(prefix="/investor", tags=["বিনিয়োগকারী অ্যাপ (Investor)"])
DocKind = Literal["nid_front", "nid_back", "selfie"]


# ---------- onboarding ----------
@router.post("/mobile-check", summary="এই নম্বরে আগে অ্যাকাউন্ট আছে কিনা")
def mobile_check(body: MobileCheckIn, store: StoreDep):
    with store.transaction() as tx:
        return investors.mobile_available(tx, body.mobile)


@router.post("/applications", status_code=201, summary="বিনিয়োগকারী হিসেবে আবেদন")
def submit_application(body: InvestorApplicationIn, store: StoreDep):
    with store.transaction() as tx:
        created = investors.submit_application(tx, body)
    with store.transaction() as tx:
        session = auth.login(tx, body.mobile, body.password)
    return {**created, **session, "message": "আবেদন জমা হয়েছে। এখন NID-এর দুই পাশ ও সেলফি আপলোড করুন।"}


def _applicant(user: dict) -> dict:
    if user["role"] != "investor" or not user.get("application_id"):
        raise Forbidden("আবেদন পাওয়া যায়নি।")
    return user


@router.post("/application/documents/{kind}", summary="NID বা সেলফি আপলোড")
async def upload_document(kind: DocKind, user: UserDep, store: StoreDep, file: UploadFile = File(...)):
    _applicant(user)
    ref, ctype = await save_image(file, f"investor_applications/{user['application_id']}", kind)
    with store.transaction() as tx:
        return investors.record_document(tx, user, kind, ref, ctype)


@router.get("/application", summary="আবেদনের অবস্থা")
def my_application(user: UserDep, store: StoreDep):
    _applicant(user)
    with store.transaction() as tx:
        return investors.my_application(tx, user)


@router.post("/application/resubmit", summary="চাওয়া তথ্য দিয়ে আবার জমা")
def resubmit(user: UserDep, store: StoreDep):
    _applicant(user)
    with store.transaction() as tx:
        return investors.resubmit(tx, user)


# ---------- money picture ----------
@router.get("/dashboard", summary="হোম: মূলধন, লাভ, আজকের বিক্রি")
def dashboard(ctx: InvestorDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.dashboard(tx, ctx.investor)


@router.get("/portfolio", summary="কোন প্রোডাক্টে কত টাকা")
def portfolio(ctx: InvestorDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.portfolio(tx, ctx.investor)


@router.get("/products/{product_id}", summary="প্রোডাক্টের হিসাব ও কোন সেলারের কাছে")
def product(product_id: str, ctx: InvestorDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.product_detail(tx, ctx.investor, product_id)


@router.get("/sellers", summary="কোন সেলারের কাছে আমার স্টক (ফোন/NID ছাড়া)")
def sellers(ctx: InvestorDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.sellers_view(tx, ctx.investor)


@router.get("/ledger", summary="লেনদেনের খাতা")
def ledger(ctx: InvestorDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.ledger(tx, ctx.investor)


@router.get("/reports", summary="মাসিক রিপোর্ট")
def reports(ctx: InvestorDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.reports(tx, ctx.investor)


@router.put("/preferences", summary="লাভ টাকায় নেবেন নাকি আবার বিনিয়োগ")
def preferences(body: PreferenceIn, ctx: InvestorDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.set_preference(tx, ctx.investor, ctx.user, body.preference)


# ---------- capital withdrawal ----------
@router.get("/withdrawals", summary="আমার ফেরতের অনুরোধ")
def my_withdrawals(ctx: InvestorDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.list_withdrawals(tx, investor_id=ctx.id)


@router.post("/withdrawals", status_code=201, summary="মূলধন ফেরতের অনুরোধ")
def request_withdrawal(body: WithdrawalRequestIn, ctx: InvestorDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.request_withdrawal(tx, ctx.investor, ctx.user, body)


# ---------- notifications ----------
@router.get("/notifications", summary="নোটিফিকেশন")
def notifications(ctx: InvestorDep, store: StoreDep, unread_only: bool = False):
    with store.transaction() as tx:
        return system.list_notifications(tx, f"investor:{ctx.id}", unread_only)


@router.post("/notifications/read", summary="সব পড়া হয়েছে")
def read_all(ctx: InvestorDep, store: StoreDep):
    with store.transaction() as tx:
        return {"updated": system.mark_read(tx, f"investor:{ctx.id}")}
