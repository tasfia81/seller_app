"""Admin endpoints: investor management and messages to sellers / investors."""

from typing import Literal

from fastapi import APIRouter
from fastapi.responses import FileResponse

from ..core.deps import AdminDep, StoreDep
from ..schemas import MessageIn, ReviewRejectIn
from ..schemas_investor import (FundedBatchIn, InvestmentIn, InvestorApproveIn, InvestorInfoRequestIn, InvestorPaymentIn, InvestorStatusIn,
                                InvestorTermsIn, ProfitPaymentIn, WithdrawalDecisionIn, WithdrawalRejectIn)
from ..services import investors, system
from .uploads import resolve

router = APIRouter(prefix="/admin", tags=["অ্যাডমিন · বিনিয়োগকারী ও বার্তা"])


# ---------- applications (KYC) ----------
@router.get("/investor-applications", summary="বিনিয়োগকারীর আবেদন")
def applications(admin: AdminDep, store: StoreDep, status: Literal["submitted", "under_review", "more_info", "approved", "rejected"] | None = None):
    with store.transaction() as tx:
        return investors.list_applications(tx, status)


@router.get("/investor-applications/{app_id}", summary="আবেদনের বিস্তারিত (NID লুকানো)")
def application(app_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.get_application(tx, app_id)


@router.post("/investor-applications/{app_id}/start-review", summary="যাচাই শুরু")
def start_review(app_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.start_review(tx, admin, app_id)


@router.post("/investor-applications/{app_id}/approve", summary="অনুমোদন ও চুক্তির শর্ত")
def approve(app_id: str, body: InvestorApproveIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.approve_application(tx, admin, app_id, body.terms)


@router.post("/investor-applications/{app_id}/reject", summary="বাতিল (কারণসহ)")
def reject(app_id: str, body: ReviewRejectIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.reject_application(tx, admin, app_id, body.reason)


@router.post("/investor-applications/{app_id}/request-info", summary="আরও তথ্য চাওয়া")
def request_info(app_id: str, body: InvestorInfoRequestIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.request_info(tx, admin, app_id, body)


@router.post("/investor-applications/{app_id}/reveal-nid", summary="পুরো NID দেখা (অডিট লগে থাকে)")
def reveal_nid(app_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.reveal_nid(tx, admin, app_id)


@router.get("/investor-applications/{app_id}/documents/{kind}", summary="NID/সেলফি দেখা (অডিট লগে থাকে)")
def document(app_id: str, kind: Literal["nid_front", "nid_back", "selfie"], admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        doc = investors.document_ref(tx, admin, app_id, kind)
    return FileResponse(resolve(doc["file"]), media_type=doc["content_type"], headers={"Cache-Control": "no-store, private"})


# ---------- investors ----------
@router.get("/investors", summary="বিনিয়োগকারী তালিকা")
def list_investors(admin: AdminDep, store: StoreDep, status: Literal["active", "withdrawing", "suspended"] | None = None, q: str | None = None):
    with store.transaction() as tx:
        return investors.list_investors(tx, status, q)


@router.get("/investors/{investor_id}", summary="বিনিয়োগকারীর প্রোফাইল")
def investor(investor_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.investor_detail(tx, investor_id)


@router.post("/investors/{investor_id}/status", summary="সক্রিয় / স্থগিত")
def set_status(investor_id: str, body: InvestorStatusIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.set_status(tx, admin, investor_id, body)


@router.put("/investors/{investor_id}/terms", summary="চুক্তির শর্ত বদল (অনুমোদন না হওয়া মাস থেকে)")
def terms(investor_id: str, body: InvestorTermsIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.update_terms(tx, admin, investor_id, body)


# ---------- money in & funding stock ----------
@router.get("/investor-capital", summary="পুঁজির সারাংশ (কার কত খাটেনি)")
def capital(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.capital_overview(tx)


@router.post("/investments", status_code=201, summary="নতুন বিনিয়োগ রেকর্ড (একই রেফারেন্স দুবার নয়)")
def record_investment(body: InvestmentIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.record_investment(tx, admin, body)


@router.get("/fundings", summary="বিনিয়োগকারীর টাকায় কেনা ব্যাচ")
def fundings(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.list_fundings(tx)


@router.post("/fundings", status_code=201, summary="নতুন ব্যাচ স্টকে তোলা ও কার টাকায় কেনা তা ভাগ করা")
def fund_batch(body: FundedBatchIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.fund_batch(tx, admin, body)


# ---------- monthly profit ----------
@router.get("/investor-profit/{month}", summary="মাসিক লাভ (খসড়া বা অনুমোদিত) · month = YYYY-MM")
def profit(month: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.profit_run(tx, month)


@router.post("/investor-profit/{month}/approve", summary="মাস বন্ধের পর লাভ অনুমোদন")
def approve_profit(month: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.approve_run(tx, admin, month)


@router.post("/investor-profit/{month}/pay", summary="একজনের লাভ পরিশোধ (একই অনুরোধ দুবার নয়)")
def pay_profit(month: str, body: ProfitPaymentIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.pay_profit(tx, admin, month, body)


# ---------- capital withdrawals ----------
@router.get("/investor-withdrawals", summary="মূলধন ফেরতের অনুরোধ")
def withdrawals(admin: AdminDep, store: StoreDep, status: Literal["pending", "approved", "paid", "rejected"] | None = None):
    with store.transaction() as tx:
        return investors.list_withdrawals(tx, status)


@router.post("/investor-withdrawals/{wd_id}/approve", summary="অনুমোদন")
def approve_withdrawal(wd_id: str, body: WithdrawalDecisionIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.approve_withdrawal(tx, admin, wd_id, body.note)


@router.post("/investor-withdrawals/{wd_id}/reject", summary="বাতিল (কারণসহ)")
def reject_withdrawal(wd_id: str, body: WithdrawalRejectIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.reject_withdrawal(tx, admin, wd_id, body.reason)


@router.post("/investor-withdrawals/{wd_id}/pay", summary="ফেরতের পেমেন্ট রেকর্ড (খাটেনি টাকা পর্যন্ত)")
def pay_withdrawal(wd_id: str, body: InvestorPaymentIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return investors.pay_withdrawal(tx, admin, wd_id, body)


# ---------- messages to sellers / investors ----------
@router.post("/messages", status_code=201, summary="সেলার বা বিনিয়োগকারীকে বার্তা (অ্যাপে নোটিফিকেশন)")
def send_message(body: MessageIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return system.send_message(tx, admin, body)


@router.get("/messages", summary="পাঠানো বার্তার ইতিহাস")
def messages(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return system.list_messages(tx)
