"""Endpoints used by the Seller mobile app."""

from datetime import date
from typing import Literal

from fastapi import APIRouter, File, UploadFile

from ..core.config import settings
from ..core.deps import SellerDep, StoreDep, UserDep
from ..core.errors import AppError, Forbidden
from ..storage import Tx
from ..schemas import ApplicationIn, CorrectionIn, HandoverIn, ProfileChangeIn, ReturnIn, SaleIn, OtpRequestIn
from ..services import applications, auth, catalog, finance, inventory, password_recovery, reports, sales, sellers, settlements, system
from ..services.common import APPLICATIONS, ASSIGNMENTS, CATEGORIES, PRODUCTS, RETURNS, SELLER_CASH_METHODS, SELLER_STOCK, SETTINGS, require
from ..services.compensation import current_rule, rule_text
from .uploads import save_image

router = APIRouter(prefix="/seller", tags=["সেলার অ্যাপ (Seller)"])
DocKind = Literal["nid_front", "nid_back", "photo"]


# ---------- onboarding (no seller account yet) ----------
@router.post("/application/otp", summary="সেলার আবেদনের জন্য মোবাইল যাচাইয়ের কোড")
def request_application_otp(body: OtpRequestIn, store: StoreDep):
    password_recovery.request(store, body.mobile, signup=True)


@router.post("/applications", status_code=201, summary="সেলার হিসেবে আবেদন")
def submit_application(body: ApplicationIn, store: StoreDep):
    with store.transaction() as tx:
        require_otp = bool(settings.bulksmsbd_api_key) or settings.storage == "firestore"
        verified = not require_otp or password_recovery.verify_signup(
            tx, body.mobile, body.otp_code
        )
        if verified:
            created = applications.submit(tx, body)
            session = auth.login(tx, body.mobile, body.password)
    if not verified:
        raise AppError("কোডটি ভুল অথবা মেয়াদ শেষ হয়েছে।", code="invalid_otp")
    return {**created, **session, "message": "আবেদন জমা হয়েছে। এখন পরিচয়পত্র ও ছবি আপলোড করুন।"}


@router.post("/application/documents/{kind}", summary="পরিচয়পত্র বা ছবি আপলোড")
async def upload_document(kind: DocKind, user: UserDep, store: StoreDep, file: UploadFile = File(...)):
    if user["role"] != "seller" or not user.get("application_id"):
        raise Forbidden("আবেদন পাওয়া যায়নি।")
    ref, ctype = await save_image(file, f"applications/{user['application_id']}", kind)
    with store.transaction() as tx:
        return applications.record_document(tx, user, kind, ref, ctype)


@router.get("/application", summary="আবেদনের অবস্থা")
def my_application(user: UserDep, store: StoreDep):
    if user["role"] != "seller":
        raise Forbidden("আবেদন পাওয়া যায়নি।")
    with store.transaction() as tx:
        app = require(tx, APPLICATIONS, user.get("application_id") or "", "আবেদন পাওয়া যায়নি।")
        return applications.public_view(app)


@router.post("/application/resubmit", summary="চাওয়া তথ্য দিয়ে আবার জমা")
def resubmit(user: UserDep, store: StoreDep):
    if user["role"] != "seller":
        raise Forbidden("আবেদন পাওয়া যায়নি।")
    with store.transaction() as tx:
        return applications.resubmit(tx, user)


# ---------- home & products ----------
@router.get("/dashboard", summary="হোম স্ক্রিনের তথ্য")
def dashboard(ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return reports.seller_dashboard(tx, ctx.seller)


def _product_for_seller(tx: Tx, product: dict, seller: dict, qty: float) -> dict:
    result = catalog.seller_view(product, qty)
    result["category_name"] = (tx.get(CATEGORIES, product["category_id"]) or {}).get("name")
    fixed = tx.first(ASSIGNMENTS, lambda a: a["seller_id"] == seller["id"]
                     and a["status"] in ("active", "partially_returned") and a["price_mode"] == "fixed"
                     and any(item["product_id"] == product["id"] for item in a["items"]))
    result["price_editable"] = product["price_editable"] and seller["permissions"].get("can_edit_price", False) and not fixed
    methods = (tx.get(SETTINGS, "main") or {}).get("payments", {})
    result["payment_methods"] = [method for method in sales.PAYMENT_LABEL
                                 if methods.get(method, {}).get("enabled", True)
                                 and (method in SELLER_CASH_METHODS or seller["permissions"].get("can_take_digital", True))]
    return result


@router.get("/products", summary="আমাকে দেওয়া পণ্য")
def my_products(ctx: SellerDep, store: StoreDep, q: str | None = None, category_id: str | None = None, in_stock: bool | None = None):
    with store.transaction() as tx:
        by_product: dict[str, float] = {}
        variants: dict[str, dict[str, float]] = {}
        for s in tx.find(SELLER_STOCK, lambda s: s["seller_id"] == ctx.id):
            by_product[s["product_id"]] = by_product.get(s["product_id"], 0) + s["qty"]
            if s["variant"]:
                variants.setdefault(s["product_id"], {})[s["variant"]] = s["qty"]
        out = []
        for pid, qty in by_product.items():
            p = tx.get(PRODUCTS, pid)
            if not p or (category_id and p["category_id"] != category_id) or (q and q not in p["name"]):
                continue
            if in_stock is not None and (qty > 0) != in_stock:
                continue
            view = _product_for_seller(tx, p, ctx.seller, qty)
            view["variant_stock"] = variants.get(pid, {})
            out.append(view)
        return sorted(out, key=lambda p: (p["available_qty"] <= 0, p["name"]))


@router.get("/products/{product_id}", summary="পণ্যের বিস্তারিত")
def product_detail(product_id: str, ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        p = require(tx, PRODUCTS, product_id, "পণ্য পাওয়া যায়নি।")
        stocks = tx.find(SELLER_STOCK, lambda s: s["seller_id"] == ctx.id and s["product_id"] == product_id)
        if not stocks:
            raise Forbidden("এই পণ্য আপনাকে দেওয়া হয়নি।")
        view = _product_for_seller(tx, p, ctx.seller, sum(s["qty"] for s in stocks))
        view["variant_stock"] = {s["variant"]: s["qty"] for s in stocks if s["variant"]}
        return view


# ---------- assignments ----------
@router.get("/assignments", summary="আমার স্টক বরাদ্দ")
def my_assignments(ctx: SellerDep, store: StoreDep, status: str | None = None):
    with store.transaction() as tx:
        return inventory.list_assignments(tx, seller_id=ctx.id, status=status)


@router.post("/assignments/{assignment_id}/accept", summary="স্টক হাতে পেয়েছি")
def accept_assignment(assignment_id: str, ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.accept_assignment(tx, ctx.seller, assignment_id)


# ---------- sales ----------
@router.post("/sales", status_code=201, summary="নতুন বিক্রি (সার্ভার যাচাই করে নিশ্চিত করে)")
def create_sale(body: SaleIn, ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return sales.create_sale(tx, ctx.seller, body)


@router.get("/sales", summary="বিক্রির ইতিহাস")
def my_sales(ctx: SellerDep, store: StoreDep, period: Literal["today", "yesterday", "last7", "custom"] = "today",
             date_from: date | None = None, date_to: date | None = None, q: str | None = None):
    with store.transaction() as tx:
        return sales.list_sales(tx, seller_id=ctx.id, period=period, start=date_from, end=date_to, q=q)


@router.get("/sales/{sale_id}", summary="বিক্রির বিস্তারিত / রসিদ")
def my_sale(sale_id: str, ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return sales.get_sale(tx, sale_id, seller_id=ctx.id)


@router.post("/sales/{sale_id}/corrections", status_code=201, summary="বিক্রি সংশোধনের অনুরোধ")
def request_correction(sale_id: str, body: CorrectionIn, ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return sales.request_correction(tx, ctx.seller, sale_id, body)


# ---------- earnings / inventory / returns ----------
@router.get("/earnings", summary="আমার আয়")
def my_earnings(ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        rule = current_rule(ctx.seller)
        return {"rule": rule, "rule_text": rule_text(rule), "summary": finance.earnings_summary(tx, ctx.id),
                "history": finance.earnings_history(tx, ctx.id), "payouts": [p for p in tx.list("payouts") if p["seller_id"] == ctx.id]}


@router.get("/inventory", summary="আমার স্টক")
def my_inventory(ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.seller_inventory(tx, ctx.seller)


@router.post("/returns", status_code=201, summary="স্টক ফেরতের অনুরোধ")
def create_return(body: ReturnIn, ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.request_return(tx, ctx.seller, body)


@router.post("/returns/{return_id}/photo", summary="ক্ষতির ছবি যোগ")
async def return_photo(return_id: str, ctx: SellerDep, store: StoreDep, file: UploadFile = File(...)):
    ref, _ = await save_image(file, f"returns/{ctx.id}", return_id)
    with store.transaction() as tx:
        r = require(tx, RETURNS, return_id, "ফেরতের অনুরোধ পাওয়া যায়নি।")
        if r["seller_id"] != ctx.id:
            raise Forbidden("এই অনুরোধ আপনার নয়।")
        if r["status"] != "pending":
            raise AppError("এই অবস্থায় ছবি যোগ করা যাবে না।", code="return_locked")
        r["photo"] = ref
        tx.put(RETURNS, r)
        return inventory.return_view(tx, r)


@router.get("/returns", summary="আমার ফেরতের অনুরোধ")
def my_returns(ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return inventory.list_returns(tx, seller_id=ctx.id)


# ---------- cash & day closing ----------
@router.get("/cash", summary="ক্যাশের হিসাব ও জমার ইতিহাস")
def my_cash(ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return {"summary": finance.cash_summary(tx, ctx.id), "history": finance.list_handovers(tx, seller_id=ctx.id)}


@router.post("/cash/handovers", status_code=201, summary="ক্যাশ জমার তথ্য পাঠান")
def submit_handover(body: HandoverIn, ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return finance.submit_handover(tx, ctx.seller, body)


@router.get("/day-closing", summary="আজকের দিনের হিসাব")
def day_closing(ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return settlements.seller_day(tx, ctx.seller)


@router.post("/day-closing/submit", summary="দিনের হিসাব জমা দিন")
def submit_day(ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return settlements.seller_submit(tx, ctx.seller)


# ---------- notifications & profile ----------
@router.get("/notifications", summary="নোটিফিকেশন")
def notifications(ctx: SellerDep, store: StoreDep, unread_only: bool = False):
    with store.transaction() as tx:
        return system.list_notifications(tx, f"seller:{ctx.id}", unread_only)


@router.post("/notifications/read", summary="সব পড়া হয়েছে")
def read_all(ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return {"updated": system.mark_read(tx, f"seller:{ctx.id}")}


@router.post("/notifications/{notification_id}/read", summary="একটি নোটিফিকেশন পড়া হয়েছে")
def read_one(notification_id: str, ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return {"updated": system.mark_read(tx, f"seller:{ctx.id}", notification_id)}


@router.get("/profile", summary="আমার প্রোফাইল (পরিচয়পত্র নম্বর লুকানো)")
def profile(ctx: SellerDep):
    return sellers.profile_view(ctx.seller)


@router.post("/profile/change-requests", status_code=201, summary="তথ্য পরিবর্তনের অনুরোধ")
def change_request(body: ProfileChangeIn, ctx: SellerDep, store: StoreDep):
    with store.transaction() as tx:
        return sellers.request_profile_change(tx, ctx.seller, body)
