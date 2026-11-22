"""Endpoints used by the Admin web panel. Every route requires an admin login."""

from datetime import date
from typing import Literal

from fastapi import APIRouter
from fastapi.responses import FileResponse

from ..core.deps import AdminDep, StoreDep
from ..core.utils import period_range, today
from ..schemas import (AdminNoteIn, AssignmentIn, CategoryIn, CompensationIn, DamageIn, ExceptionIn, ExpenseIn, PayoutIn, ProductIn, ProductUpdateIn,
                       RequestInfoIn, ReturnApproveIn, ReviewRejectIn, SellerUpdateIn, SettingsIn, StockReceiptIn, TransferIn, VerifyHandoverIn)
from ..services import applications, catalog, finance, inventory, reports, sales, sellers, settlements, system
from ..services.common import ASSIGNMENTS, DAMAGES, PRODUCTS, SELLERS, require
from .uploads import resolve

router = APIRouter(prefix="/admin", tags=["অ্যাডমিন (Admin)"])
Period = Literal["today", "yesterday", "last7", "month", "custom"]


# ================= dashboard & reports =================
@router.get("/dashboard", summary="ড্যাশবোর্ড")
def dashboard(admin: AdminDep, store: StoreDep, period: Period = "today"):
    with store.transaction() as tx:
        return reports.admin_dashboard(tx, period)


@router.get("/nav-counts", summary="মেনুর ব্যাজ: কোথায় কতটি কাজ বাকি")
def nav_counts(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return reports.nav_counts(tx)


@router.get("/reports/financial", summary="আর্থিক সারাংশ")
def financial(admin: AdminDep, store: StoreDep, period: Period = "month", date_from: date | None = None, date_to: date | None = None):
    d1, d2 = period_range(period, date_from, date_to)
    with store.transaction() as tx:
        return reports.financial(tx, d1, d2)


@router.get("/reports/sellers", summary="সেলারের পারফরম্যান্স")
def seller_report(admin: AdminDep, store: StoreDep, period: Period = "month", date_from: date | None = None, date_to: date | None = None):
    d1, d2 = period_range(period, date_from, date_to)
    with store.transaction() as tx:
        return reports.seller_performance(tx, d1, d2)


@router.get("/reports/products", summary="পণ্যের পারফরম্যান্স")
def product_report(admin: AdminDep, store: StoreDep, period: Period = "month", date_from: date | None = None, date_to: date | None = None):
    d1, d2 = period_range(period, date_from, date_to)
    with store.transaction() as tx:
        return reports.product_performance(tx, d1, d2)


# ================= seller applications =================
@router.get("/applications", summary="সেলার আবেদনের তালিকা")
def list_applications(admin: AdminDep, store: StoreDep, status: Literal["submitted", "under_review", "more_info", "approved", "rejected"] | None = None, q: str | None = None):
    with store.transaction() as tx:
        return applications.list_applications(tx, status, q)


@router.get("/applications/{app_id}", summary="আবেদনের বিস্তারিত (পরিচয়পত্র নম্বর লুকানো)")
def get_application(app_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return applications.public_view(require(tx, "applications", app_id, "আবেদন পাওয়া যায়নি।"), include_private=True)


@router.post("/applications/{app_id}/start-review", summary="যাচাই শুরু")
def start_review(app_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return applications.start_review(tx, admin, app_id)


@router.post("/applications/{app_id}/approve", summary="অনুমোদন")
def approve(app_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return applications.approve(tx, admin, app_id)


@router.post("/applications/{app_id}/reject", summary="বাতিল (কারণসহ)")
def reject(app_id: str, body: ReviewRejectIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return applications.reject(tx, admin, app_id, body.reason)


@router.post("/applications/{app_id}/request-info", summary="আরও তথ্য চাওয়া")
def request_info(app_id: str, body: RequestInfoIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return applications.request_info(tx, admin, app_id, body)


@router.post("/applications/{app_id}/reveal-nid", summary="পুরো পরিচয়পত্র নম্বর দেখা (অডিট লগে থাকে)")
def reveal_nid(app_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return applications.reveal_nid(tx, admin, app_id)


@router.get("/applications/{app_id}/documents/{kind}", summary="পরিচয়পত্র/ছবি দেখা (অডিট লগে থাকে)")
def application_document(app_id: str, kind: Literal["nid_front", "nid_back", "photo"], admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        doc = applications.document_ref(tx, admin, app_id, kind)
    return FileResponse(resolve(doc["file"]), media_type=doc["content_type"], headers={"Cache-Control": "no-store, private"})


# ================= sellers & compensation =================
@router.get("/sellers", summary="সেলার তালিকা")
def list_sellers(admin: AdminDep, store: StoreDep, status: Literal["active", "inactive", "suspended"] | None = None,
                 model: Literal["profit", "daily", "per_unit", "hybrid"] | None = None, q: str | None = None):
    with store.transaction() as tx:
        return sellers.list_sellers(tx, status, model, q)


@router.get("/sellers/{seller_id}", summary="সেলারের প্রোফাইল ও সারাংশ")
def seller_overview(seller_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return sellers.overview(tx, seller_id)


@router.patch("/sellers/{seller_id}", summary="সেলারের তথ্য সম্পাদনা")
def update_seller(seller_id: str, body: SellerUpdateIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return sellers.update_seller(tx, admin, seller_id, body)


@router.post("/sellers/{seller_id}/status/{status}", summary="সক্রিয় / নিষ্ক্রিয় / স্থগিত")
def set_seller_status(seller_id: str, status: Literal["active", "inactive", "suspended"], admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return sellers.set_status(tx, admin, seller_id, status)


@router.post("/sellers/{seller_id}/revoke-sessions", summary="সব ডিভাইস থেকে লগআউট")
def revoke_sessions(seller_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return sellers.revoke_sessions(tx, admin, seller_id)


@router.put("/sellers/{seller_id}/compensation", summary="আয়ের নিয়ম বদলানো (কার্যকর তারিখসহ)")
def set_compensation(seller_id: str, body: CompensationIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return sellers.set_compensation(tx, admin, seller_id, body)


@router.get("/sellers/{seller_id}/compensation/history", summary="আয়ের নিয়মের ইতিহাস")
def compensation_history(seller_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return sellers.compensation_history(require(tx, SELLERS, seller_id, "সেলার পাওয়া যায়নি।"))


@router.get("/sellers/{seller_id}/earnings", summary="সেলারের আয়ের হিসাব")
def seller_earnings(seller_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        require(tx, SELLERS, seller_id, "সেলার পাওয়া যায়নি।")
        return {"summary": finance.earnings_summary(tx, seller_id), "history": finance.earnings_history(tx, seller_id)}


# ================= catalog =================
@router.get("/categories", summary="ক্যাটাগরি")
def list_categories(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return catalog.list_categories(tx)


@router.post("/categories", status_code=201, summary="ক্যাটাগরি যোগ")
def create_category(body: CategoryIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return catalog.create_category(tx, admin, body)


@router.patch("/categories/{cat_id}", summary="ক্যাটাগরির নাম বদল")
def rename_category(cat_id: str, body: CategoryIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return catalog.rename_category(tx, admin, cat_id, body)


@router.post("/categories/{cat_id}/archive", summary="আর্কাইভ")
def archive_category(cat_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return catalog.set_category_archived(tx, admin, cat_id, True)


@router.post("/categories/{cat_id}/restore", summary="আর্কাইভ থেকে ফেরত")
def restore_category(cat_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return catalog.set_category_archived(tx, admin, cat_id, False)


@router.get("/products", summary="পণ্যের তালিকা")
def list_products(admin: AdminDep, store: StoreDep, category_id: str | None = None,
                  status: Literal["active", "inactive", "low_stock", "out_of_stock"] | None = None, q: str | None = None):
    with store.transaction() as tx:
        return catalog.list_products(tx, category_id, status, q)


@router.post("/products", status_code=201, summary="পণ্য যোগ")
def create_product(body: ProductIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return catalog.create_product(tx, admin, body)


@router.get("/products/{product_id}", summary="পণ্যের বিস্তারিত")
def get_product(product_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return catalog.admin_view(tx, require(tx, PRODUCTS, product_id, "পণ্য পাওয়া যায়নি।"))


@router.patch("/products/{product_id}", summary="পণ্য সম্পাদনা")
def update_product(product_id: str, body: ProductUpdateIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return catalog.update_product(tx, admin, product_id, body)


# ================= inventory & assignments =================
@router.get("/inventory", summary="মূল স্টকের সারাংশ")
def inventory_overview(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.inventory_overview(tx)


@router.post("/inventory/receipts", status_code=201, summary="স্টক গ্রহণ")
def receive_stock(body: StockReceiptIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.receive_stock(tx, admin, body)


@router.get("/inventory/movements", summary="স্টকের আসা-যাওয়া")
def movements(admin: AdminDep, store: StoreDep, product_id: str | None = None, seller_id: str | None = None, limit: int = 100):
    with store.transaction() as tx:
        return inventory.list_movements(tx, product_id, seller_id, min(limit, 500))


@router.post("/inventory/transfers", status_code=201, summary="সেলারের কাছ থেকে ফেরত ডাকা বা অন্য সেলারকে দেওয়া")
def transfer(body: TransferIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.transfer(tx, admin, body)


@router.post("/inventory/damages", status_code=201, summary="ক্ষতিগ্রস্ত/হারানো স্টক রেকর্ড")
def damage(body: DamageIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.record_damage(tx, admin, body)


@router.get("/inventory/damages", summary="ক্ষতিগ্রস্ত/হারানো স্টকের তালিকা")
def list_damages(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return sorted(tx.list(DAMAGES), key=lambda d: d["at"], reverse=True)


@router.get("/assignments", summary="স্টক বরাদ্দের তালিকা")
def list_assignments(admin: AdminDep, store: StoreDep, seller_id: str | None = None,
                     status: Literal["pending_handover", "active", "partially_returned", "closed", "cancelled"] | None = None):
    with store.transaction() as tx:
        return inventory.list_assignments(tx, seller_id, status)


@router.post("/assignments", status_code=201, summary="সেলারকে স্টক দেওয়া (হস্তান্তর বাকি অবস্থায় শুরু হয়)")
def create_assignment(body: AssignmentIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.create_assignment(tx, admin, body)


@router.get("/assignments/{assignment_id}", summary="বরাদ্দের বিস্তারিত")
def get_assignment(assignment_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.assignment_view(require(tx, ASSIGNMENTS, assignment_id, "বরাদ্দ পাওয়া যায়নি।"))


@router.post("/assignments/{assignment_id}/cancel", summary="হস্তান্তরের আগে বাতিল")
def cancel_assignment(assignment_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.cancel_assignment(tx, admin, assignment_id)


@router.post("/assignments/{assignment_id}/close", summary="বরাদ্দ বন্ধ")
def close_assignment(assignment_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.close_assignment(tx, admin, assignment_id)


# ================= returns =================
@router.get("/returns", summary="স্টক ফেরতের অনুরোধ")
def list_returns(admin: AdminDep, store: StoreDep, status: Literal["pending", "approved", "rejected", "completed"] | None = None):
    with store.transaction() as tx:
        return inventory.list_returns(tx, status=status)


@router.post("/returns/{return_id}/approve", summary="অনুমোদন (স্টক এখনো সরবে না)")
def approve_return(return_id: str, body: ReturnApproveIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.approve_return(tx, admin, return_id, body)


@router.post("/returns/{return_id}/reject", summary="বাতিল")
def reject_return(return_id: str, body: AdminNoteIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.reject_return(tx, admin, return_id, body.note)


@router.post("/returns/{return_id}/receive", summary="গুদামে হাতে পেয়েছি (এখন স্টক সরবে)")
def receive_return(return_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.receive_return(tx, admin, return_id)


# ================= sales & corrections =================
@router.get("/sales", summary="বিক্রি মনিটর")
def list_sales(admin: AdminDep, store: StoreDep, period: Period = "today", date_from: date | None = None, date_to: date | None = None,
               seller_id: str | None = None, product_id: str | None = None, payment: str | None = None, q: str | None = None):
    with store.transaction() as tx:
        return sales.list_sales(tx, seller_id=seller_id, period=period, start=date_from, end=date_to, payment=payment, product_id=product_id, q=q, admin=True)


@router.get("/sales/{sale_id}", summary="বিক্রির বিস্তারিত (ক্রয়মূল্য, লাভ, কমিশনসহ)")
def get_sale(sale_id: str, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return sales.get_sale(tx, sale_id, admin=True)


@router.get("/corrections", summary="সংশোধনের অনুরোধ")
def list_corrections(admin: AdminDep, store: StoreDep, status: Literal["pending", "clarification", "approved", "rejected"] | None = None):
    with store.transaction() as tx:
        return sales.list_corrections(tx, status)


@router.post("/corrections/{correction_id}/{decision}", summary="অনুমোদন / বাতিল / আরও জানতে চাওয়া")
def decide_correction(correction_id: str, decision: Literal["approve", "reject", "clarify"], body: AdminNoteIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return sales.decide_correction(tx, admin, correction_id, decision, body.note)


# ================= cash, payouts, expenses =================
@router.get("/cash", summary="ক্যাশ সংগ্রহের সারাংশ")
def cash_overview(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return finance.cash_overview(tx)


@router.get("/cash/handovers", summary="ক্যাশ জমার অনুরোধ")
def list_handovers(admin: AdminDep, store: StoreDep, status: Literal["pending", "verified", "rejected"] | None = None, seller_id: str | None = None):
    with store.transaction() as tx:
        return finance.list_handovers(tx, status, seller_id)


@router.post("/cash/handovers/{handover_id}/verify", summary="ক্যাশ গ্রহণ নিশ্চিত (কম পেলে গরমিল থাকে)")
def verify_handover(handover_id: str, body: VerifyHandoverIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return finance.verify_handover(tx, admin, handover_id, body)


@router.post("/cash/handovers/{handover_id}/reject", summary="ক্যাশ জমা প্রত্যাখ্যান")
def reject_handover(handover_id: str, body: AdminNoteIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return finance.reject_handover(tx, admin, handover_id, body.note)


@router.get("/payouts", summary="সেলার পেমেন্টের সারাংশ ও ইতিহাস")
def payouts(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return finance.payouts_overview(tx)


@router.post("/payouts", status_code=201, summary="সেলারকে পেমেন্ট (একই অনুরোধ দুবার হয় না)")
def create_payout(body: PayoutIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return finance.create_payout(tx, admin, body)


@router.get("/expenses", summary="খরচের তালিকা")
def list_expenses(admin: AdminDep, store: StoreDep, period: Period = "month", date_from: date | None = None, date_to: date | None = None, category: str | None = None):
    d1, d2 = period_range(period, date_from, date_to)
    with store.transaction() as tx:
        return finance.list_expenses(tx, d1, d2, category)


@router.post("/expenses", status_code=201, summary="খরচ যোগ")
def add_expense(body: ExpenseIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return finance.add_expense(tx, admin, body)


# ================= settlements =================
@router.get("/settlements", summary="দিনের হিসাবের তালিকা")
def list_settlements(admin: AdminDep, store: StoreDep, day: date | None = None, status: Literal["open", "submitted", "review", "discrepancy", "closed"] | None = None):
    with store.transaction() as tx:
        return settlements.list_for_date(tx, day or today(), status)


@router.get("/settlements/{seller_id}/{day}", summary="দিনের হিসাবের বিস্তারিত")
def settlement_detail(seller_id: str, day: date, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return settlements.detail(tx, seller_id, day)


@router.post("/settlements/{seller_id}/{day}/close", summary="হিসাব অনুমোদন ও দিন বন্ধ")
def close_day(seller_id: str, day: date, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return settlements.close_day(tx, admin, seller_id, day)


@router.post("/settlements/{seller_id}/{day}/exception", summary="অনুমোদিত ব্যতিক্রম রেকর্ড")
def settlement_exception(seller_id: str, day: date, body: ExceptionIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return settlements.record_exception(tx, admin, seller_id, day, body.note)


@router.post("/settlements/{seller_id}/{day}/request-correction", summary="সেলারের কাছে সংশোধন চাওয়া")
def settlement_correction(seller_id: str, day: date, body: ExceptionIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return settlements.request_correction(tx, admin, seller_id, day, body.note)


# ================= notifications, audit, settings =================
@router.get("/notifications", summary="অ্যাডমিন নোটিফিকেশন")
def notifications(admin: AdminDep, store: StoreDep, unread_only: bool = False):
    with store.transaction() as tx:
        return system.list_notifications(tx, "admin", unread_only)


@router.post("/notifications/read", summary="সব পড়া হয়েছে")
def read_all(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return {"updated": system.mark_read(tx, "admin")}


@router.get("/audit-log", summary="কার্যক্রম ও অডিট লগ")
def audit_log(admin: AdminDep, store: StoreDep, action: str | None = None, actor_id: str | None = None, limit: int = 200):
    with store.transaction() as tx:
        return system.list_audit(tx, action, actor_id, min(limit, 1000))


@router.get("/settings", summary="ব্যবসার সেটিংস")
def get_settings(admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return system.get_settings(tx)


@router.put("/settings", summary="সেটিংস হালনাগাদ")
def update_settings(body: SettingsIn, admin: AdminDep, store: StoreDep):
    with store.transaction() as tx:
        return system.update_settings(tx, admin, body.model_dump())
