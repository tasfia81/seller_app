"""Investors: KYC onboarding, money in, funding stock lots, profit attribution,
monthly profit runs and capital withdrawals.

How an investor's profit is worked out (product/lot based):
- Every stock receipt is a *lot*. When investors fund a lot, it stores each
  investor's amount; the rest is the company's own money.
- Sold units are matched to lots of the same product and size oldest-first (FIFO).
- Net profit of a matched sale = revenue − lot cost − seller commission.
  An investor gets (their amount ÷ lot cost) of that net, times their share %.
- Money of an investor not tied up in unsold units is "uninvested" (cash
  available for new stock or for withdrawal).
Approved monthly runs are frozen; later corrections never change them.
"""

from calendar import monthrange
from datetime import date, timedelta
from typing import Any

from ..core.errors import AppError, Conflict, Forbidden
from ..core.security import hash_password
from ..core.utils import day_of, mask_mobile, mask_nid, money, new_id, now_iso, today
from ..schemas import StockReceiptIn
from ..schemas_investor import (FundedBatchIn, InvestmentIn, InvestorApplicationIn, InvestorInfoRequestIn, InvestorPaymentIn, InvestorStatusIn,
                                InvestorTermsIn, ProfitPaymentIn, WithdrawalRequestIn)
from ..storage import Tx
from . import inventory
from .common import (CORRECTIONS, INV_APPS, INV_RUNS, INV_TXNS, INV_WITHDRAWALS, INVESTORS, LOTS, PRODUCTS, SALES, SELLER_STOCK, SELLERS, SETTINGS, USERS,
                     audit, effective_sale, notify, product_name, require)

DOC_KINDS = ("nid_front", "nid_back", "selfie")
DEFAULT_TERMS = {"share_percent": 50.0, "payout_day": 5, "notice_days": 30}
APP_LABEL = {"submitted": "অপেক্ষমাণ", "under_review": "যাচাই চলছে", "more_info": "আরও তথ্য চাওয়া", "approved": "অনুমোদিত", "rejected": "বাতিল"}
WD_LABEL = {"pending": "সিদ্ধান্ত বাকি", "approved": "অনুমোদিত · পেমেন্ট বাকি", "paid": "সম্পন্ন", "rejected": "বাতিল"}
TXN_LABEL = {"invest": "বিনিয়োগ", "reinvest": "লাভ আবার বিনিয়োগ", "profit": "লাভ প্রদান", "withdraw": "মূলধন ফেরত"}
METHOD_LABEL = {"bank": "ব্যাংক", "cheque": "চেক", "bkash": "বিকাশ", "nagad": "নগদ"}
EPS = 0.009


# ---------------------------------------------------------------- helpers
def _settings_terms(tx: Tx) -> dict[str, Any]:
    s = tx.get(SETTINGS, "main") or {}
    return {**DEFAULT_TERMS, **s.get("investor_terms", {})}


def _mask_account(number: str) -> str:
    chars = "".join(c for c in number if c.isalnum())
    return f"••••{chars[-4:]}" if chars else ""


def _payout_view(p: dict[str, Any]) -> dict[str, Any]:
    return {"method": p["method"], "method_label": METHOD_LABEL.get(p["method"], p["method"]), "account_name": p["account_name"],
            "account_masked": _mask_account(p["account_number"]), "bank_name": p.get("bank_name"), "branch": p.get("branch")}


def _month_of(iso: str) -> str:
    d = day_of(iso)
    return f"{d.year:04d}-{d.month:02d}"


def _check_month(month: str) -> tuple[int, int]:
    try:
        y, m = (int(x) for x in month.split("-"))
        date(y, m, 1)
        return y, m
    except (ValueError, TypeError):
        raise AppError("মাস YYYY-MM আকারে দিন।", code="invalid_month") from None


def _month_end(month: str) -> date:
    y, m = _check_month(month)
    return date(y, m, monthrange(y, m)[1])


def _next_no(tx: Tx, prefix: str) -> str:
    n = sum(1 for t in tx.list(INV_TXNS) if t.get("receipt", "").startswith(prefix)) + 1
    return f"{prefix}-{n:04d}"


def _age(born: date) -> int:
    t = today()
    return t.year - born.year - ((t.month, t.day) < (born.month, born.day))


def _area(seller: dict[str, Any]) -> str:
    """Only the area (upazila) of a seller — never the full address."""
    pa = seller.get("present_address")
    if isinstance(pa, dict):
        return pa.get("upazila", "")
    return str(pa or "").split(",")[0].strip()


def _require_active(inv: dict[str, Any]) -> None:
    if inv["status"] != "active":
        raise Forbidden("এই বিনিয়োগকারীর অ্যাকাউন্ট এখন সক্রিয় নেই।", code="investor_inactive")


def open_withdrawal(tx: Tx, investor_id: str) -> dict[str, Any] | None:
    return tx.first(INV_WITHDRAWALS, lambda w: w["investor_id"] == investor_id and w["status"] in ("pending", "approved"))


# ---------------------------------------------------------------- applications (KYC)
def mobile_available(tx: Tx, mobile: str) -> dict[str, Any]:
    """Lets the sign-up form stop early instead of failing after five steps."""
    return {"available": tx.first(USERS, lambda u: u.get("mobile") == mobile) is None}


def submit_application(tx: Tx, data: InvestorApplicationIn) -> dict[str, Any]:
    if not (data.accepted_risk and data.accepted_terms):
        raise AppError("ঝুঁকি ও চুক্তির শর্ত মেনে নিতে হবে।", code="consent_required")
    if _age(data.date_of_birth) < 18:
        raise AppError("বিনিয়োগ করতে বয়স কমপক্ষে ১৮ বছর হতে হবে।", code="underage")
    if tx.first(USERS, lambda u: u.get("mobile") == data.mobile):
        raise Conflict("এই মোবাইল নম্বরে আগেই অ্যাকাউন্ট বা আবেদন আছে।", code="mobile_exists")
    if tx.first(INV_APPS, lambda a: a["nid_number"] == data.nid_number and a["status"] != "rejected"):
        raise Conflict("এই পরিচয়পত্র দিয়ে আগেই আবেদন করা হয়েছে।", code="nid_exists")
    app_id, user_id = new_id("iap"), new_id("usr")
    tx.put(USERS, {"id": user_id, "role": "investor", "name": data.full_name, "mobile": data.mobile, "email": data.email,
                   "password_hash": hash_password(data.password), "status": "applicant", "seller_id": None, "investor_id": None,
                   "application_id": app_id, "session_version": 0, "created_at": now_iso()})
    tx.put(INV_APPS, {
        "id": app_id, "user_id": user_id, "status": "submitted", "full_name": data.full_name, "mobile": data.mobile,
        "date_of_birth": data.date_of_birth.isoformat(), "email": data.email, "occupation": data.occupation, "funds_source": data.funds_source,
        "address": data.address.model_dump(), "nid_number": data.nid_number, "proposed_amount": money(data.proposed_amount),
        "payout": data.payout.model_dump(), "nominee": data.nominee.model_dump(), "documents": {}, "requested_fields": [],
        "timeline": [{"title": "আবেদন জমা হয়েছে", "at": now_iso(), "by": data.full_name}], "submitted_at": now_iso(),
    })
    notify(tx, "admin", "investor_application", "নতুন বিনিয়োগকারীর আবেদন", f"{data.full_name} · প্রস্তাবিত ৳{data.proposed_amount:,.0f}", "/investors/applications")
    return {"application_id": app_id, "user_id": user_id}


def application_view(app: dict[str, Any], *, private: bool = False) -> dict[str, Any]:
    out = {
        "id": app["id"], "status": app["status"], "status_label": APP_LABEL[app["status"]], "full_name": app["full_name"],
        "mobile_masked": mask_mobile(app["mobile"]), "submitted_at": app["submitted_at"], "proposed_amount": app["proposed_amount"],
        "documents": {k: k in app["documents"] for k in DOC_KINDS}, "requested_fields": app.get("requested_fields", []),
        "admin_message": app.get("admin_message"), "rejection_reason": app.get("rejection_reason"), "timeline": app["timeline"],
    }
    if private:
        out.update({"mobile": app["mobile"], "date_of_birth": app["date_of_birth"], "email": app.get("email"), "occupation": app["occupation"],
                    "funds_source": app["funds_source"], "address": app["address"], "nid_masked": mask_nid(app["nid_number"]),
                    "payout": _payout_view(app["payout"]), "nominee": {**app["nominee"], "mobile": mask_mobile(app["nominee"]["mobile"])}})
    return out


def my_application(tx: Tx, user: dict[str, Any]) -> dict[str, Any]:
    return application_view(require(tx, INV_APPS, user.get("application_id") or "", "আবেদন পাওয়া যায়নি।"))


def record_document(tx: Tx, user: dict[str, Any], kind: str, file_ref: str, content_type: str) -> dict[str, Any]:
    app = require(tx, INV_APPS, user.get("application_id") or "", "আবেদন পাওয়া যায়নি।")
    if app["status"] in ("approved", "rejected", "under_review") and kind not in app.get("requested_fields", []):
        raise Forbidden("এই অবস্থায় ছবি বদলানো যাবে না।", code="documents_locked")
    app["documents"][kind] = {"file": file_ref, "content_type": content_type, "uploaded_at": now_iso()}
    tx.put(INV_APPS, app)
    return application_view(app)


def resubmit(tx: Tx, user: dict[str, Any]) -> dict[str, Any]:
    app = require(tx, INV_APPS, user.get("application_id") or "", "আবেদন পাওয়া যায়নি।")
    if app["status"] != "more_info":
        raise AppError("এখন আবার জমা দেওয়ার কিছু নেই।", code="nothing_to_resubmit")
    missing = [k for k in app.get("requested_fields", []) if k in DOC_KINDS and k not in app["documents"]]
    if missing:
        raise AppError("চাওয়া ছবিগুলো আগে আপলোড করুন।", code="documents_missing", details={"missing": missing})
    app["status"] = "submitted"
    app["timeline"].append({"title": "চাওয়া তথ্য আবার জমা দিয়েছেন", "at": now_iso(), "by": app["full_name"]})
    tx.put(INV_APPS, app)
    notify(tx, "admin", "investor_application", "আবেদনে তথ্য যোগ হয়েছে", f"{app['full_name']} চাওয়া তথ্য দিয়েছেন।", "/investors/applications")
    return application_view(app)


def list_applications(tx: Tx, status: str | None = None) -> list[dict[str, Any]]:
    apps = [a for a in tx.list(INV_APPS) if not status or a["status"] == status]
    apps.sort(key=lambda a: a["submitted_at"], reverse=True)
    return [application_view(a) for a in apps]


def get_application(tx: Tx, app_id: str) -> dict[str, Any]:
    return application_view(require(tx, INV_APPS, app_id, "আবেদন পাওয়া যায়নি।"), private=True)


def _transition(tx: Tx, admin: dict[str, Any], app_id: str, allowed: tuple[str, ...], new_status: str, title: str) -> dict[str, Any]:
    app = require(tx, INV_APPS, app_id, "আবেদন পাওয়া যায়নি।")
    if app["status"] not in allowed:
        raise Conflict(f"“{APP_LABEL[app['status']]}” অবস্থায় এই কাজ করা যাবে না।", code="invalid_status")
    app["status"] = new_status
    app["timeline"].append({"title": title, "at": now_iso(), "by": admin["name"]})
    return app


def start_review(tx: Tx, admin: dict[str, Any], app_id: str) -> dict[str, Any]:
    app = _transition(tx, admin, app_id, ("submitted",), "under_review", "যাচাই শুরু হয়েছে")
    tx.put(INV_APPS, app)
    audit(tx, admin, "investor_application.review_started", app_id, app["full_name"])
    return application_view(app, private=True)


def approve_application(tx: Tx, admin: dict[str, Any], app_id: str, terms: InvestorTermsIn | None) -> dict[str, Any]:
    current = require(tx, INV_APPS, app_id, "আবেদন পাওয়া যায়নি।")
    missing = [k for k in DOC_KINDS if k not in current["documents"]]
    if missing:
        raise AppError("সব ছবি জমা না হলে অনুমোদন দেওয়া যাবে না।", code="documents_missing", details={"missing": missing})
    app = _transition(tx, admin, app_id, ("submitted", "under_review"), "approved", "অনুমোদিত")
    t = terms.model_dump() if terms else _settings_terms(tx)
    inv_id = new_id("inv")
    code = f"INV-{len(tx.list(INVESTORS)) + 1:04d}"
    tx.put(INVESTORS, {
        "id": inv_id, "code": code, "user_id": app["user_id"], "application_id": app_id, "name": app["full_name"], "mobile": app["mobile"],
        "status": "active", "terms": t, "terms_history": [{"terms": t, "from": today().isoformat(), "by": admin["name"], "at": now_iso()}],
        "preference": "cash", "payout": app["payout"], "nominee": app["nominee"], "address": app["address"],
        "nid_last4": app["nid_number"][-4:], "joined_at": now_iso(),
    })
    user = require(tx, USERS, app["user_id"])
    user["status"] = "active"
    user["investor_id"] = inv_id
    tx.put(USERS, user)
    tx.put(INV_APPS, app)
    audit(tx, admin, "investor_application.approved", app_id, f"{app['full_name']} · লাভের ভাগ {t['share_percent']:g}%")
    notify(tx, f"investor:{inv_id}", "application_approved", "আবেদন অনুমোদিত",
           "আপনার অ্যাকাউন্ট চালু হয়েছে। চুক্তিপত্র অ্যাপে দেখুন; টাকা শুধু অ্যাপে দেখানো কোম্পানির অ্যাকাউন্টে পাঠাবেন।")
    return {**application_view(app, private=True), "investor_id": inv_id, "code": code}


def reject_application(tx: Tx, admin: dict[str, Any], app_id: str, reason: str) -> dict[str, Any]:
    app = _transition(tx, admin, app_id, ("submitted", "under_review", "more_info"), "rejected", "বাতিল")
    app["rejection_reason"] = reason
    tx.put(INV_APPS, app)
    # The applicant can still sign in, but only to read the decision and reason (investor endpoints need investor_id).
    user = require(tx, USERS, app["user_id"])
    user["status"] = "rejected"
    tx.put(USERS, user)
    audit(tx, admin, "investor_application.rejected", app_id, f"কারণ: {reason}")
    return application_view(app, private=True)


def request_info(tx: Tx, admin: dict[str, Any], app_id: str, data: InvestorInfoRequestIn) -> dict[str, Any]:
    app = _transition(tx, admin, app_id, ("submitted", "under_review"), "more_info", "আরও তথ্য চাওয়া হয়েছে")
    app["requested_fields"] = data.fields
    app["admin_message"] = data.message
    for f in data.fields:
        app["documents"].pop(f, None)
    tx.put(INV_APPS, app)
    audit(tx, admin, "investor_application.more_info", app_id, ", ".join(data.fields))
    return application_view(app, private=True)


def reveal_nid(tx: Tx, admin: dict[str, Any], app_id: str) -> dict[str, Any]:
    app = require(tx, INV_APPS, app_id, "আবেদন পাওয়া যায়নি।")
    audit(tx, admin, "investor_application.nid_viewed", app_id, "পুরো পরিচয়পত্র নম্বর দেখা হয়েছে")
    return {"nid_number": app["nid_number"]}


def document_ref(tx: Tx, admin: dict[str, Any], app_id: str, kind: str) -> dict[str, Any]:
    app = require(tx, INV_APPS, app_id, "আবেদন পাওয়া যায়নি।")
    doc = app["documents"].get(kind)
    if not doc:
        raise AppError("এই ছবি জমা হয়নি।", code="document_missing")
    audit(tx, admin, "investor_application.document_viewed", app_id, kind)
    return doc


# ---------------------------------------------------------------- attribution engine
class Book:
    """Sales matched to lots (FIFO) — built once per request."""

    def __init__(self, tx: Tx) -> None:
        self.lots = sorted(tx.list(LOTS), key=lambda lot: (lot["received_at"], lot.get("seq", 0)))
        self.left = {lot["id"]: float(lot["qty"]) for lot in self.lots}
        self.rows: list[dict[str, Any]] = []
        by_item: dict[tuple[str, str | None], list[dict[str, Any]]] = {}
        for lot in self.lots:
            by_item.setdefault((lot["product_id"], lot.get("variant")), []).append(lot)
        for s in sorted(tx.list(SALES), key=lambda s: s["created_at"]):
            eff = effective_sale(s)
            q = float(eff["qty"])
            if q <= 0:
                continue
            per_unit_commission = eff["commission"] / q
            for lot in by_item.get((s["product_id"], s.get("variant")), []):
                if q <= 1e-9:
                    break
                take = min(q, self.left[lot["id"]])
                if take <= 0:
                    continue
                self.left[lot["id"]] -= take
                q -= take
                revenue = take * eff["unit_price"]
                cost = take * lot["unit_cost"]
                commission = take * per_unit_commission
                self.rows.append({"lot_id": lot["id"], "product_id": s["product_id"], "seller_id": s["seller_id"], "qty": take, "revenue": revenue,
                                  "cost": cost, "commission": commission, "net": revenue - cost - commission, "at": s["created_at"],
                                  "month": _month_of(s["created_at"]), "day": day_of(s["created_at"])})
        self.lot_by_id = {lot["id"]: lot for lot in self.lots}

    @staticmethod
    def fraction(lot: dict[str, Any], investor_id: str) -> float:
        total = lot["qty"] * lot["unit_cost"]
        part = sum(p["amount"] for p in lot.get("funding", []) if p["investor_id"] == investor_id)
        return part / total if total else 0.0

    def investor_lots(self, investor_id: str) -> list[dict[str, Any]]:
        return [lot for lot in self.lots if any(p["investor_id"] == investor_id for p in lot.get("funding", []))]

    def investor_rows(self, investor_id: str, month: str | None = None) -> list[tuple[dict[str, Any], float]]:
        out = []
        for r in self.rows:
            if month and r["month"] != month:
                continue
            f = self.fraction(self.lot_by_id[r["lot_id"]], investor_id)
            if f > 0:
                out.append((r, f))
        return out


def _txn_totals(tx: Tx, investor_id: str) -> dict[str, float]:
    t = {"invest": 0.0, "reinvest": 0.0, "profit": 0.0, "withdraw": 0.0}
    for x in tx.find(INV_TXNS, lambda x: x["investor_id"] == investor_id):
        t[x["kind"]] += x["amount"]
    return t


def _approved_lines(tx: Tx, investor_id: str) -> list[tuple[dict[str, Any], dict[str, Any]]]:
    out = []
    for run in tx.list(INV_RUNS):
        for line in run["lines"]:
            if line["investor_id"] == investor_id:
                out.append((run, line))
    return out


def position(tx: Tx, inv: dict[str, Any], book: Book | None = None) -> dict[str, Any]:
    """Money picture of one investor (all derived — nothing stored twice)."""
    book = book or Book(tx)
    t = _txn_totals(tx, inv["id"])
    invested = t["invest"] + t["reinvest"]
    active = invested - t["withdraw"]
    in_stock = sum(book.fraction(lot, inv["id"]) * book.left[lot["id"]] * lot["unit_cost"] for lot in book.investor_lots(inv["id"]))
    share = inv["terms"]["share_percent"] / 100
    month = f"{today().year:04d}-{today().month:02d}"
    approved = _approved_lines(tx, inv["id"])
    earned = sum(line["amount"] for _, line in approved)
    month_frozen = any(run["month"] == month for run, _ in approved)
    draft = 0.0 if month_frozen else sum(r["net"] * f for r, f in book.investor_rows(inv["id"], month)) * share
    due = sum(line["amount"] for _, line in approved if not line["paid"])
    wd = open_withdrawal(tx, inv["id"])
    return {
        "invested": money(invested), "withdrawn": money(t["withdraw"]), "active_capital": money(active), "in_stock": money(in_stock),
        "uninvested": money(active - in_stock), "profit_earned": money(earned), "profit_this_month": money(draft),
        "profit_total": money(earned + draft), "profit_paid": money(t["profit"] + t["reinvest"]), "profit_due": money(due),
        "return_percent": round((earned + draft) * 100 / invested, 2) if invested else 0.0,
        "open_withdrawal": wd["id"] if wd else None,
    }


def _status_view(tx: Tx, inv: dict[str, Any]) -> tuple[str, str]:
    if inv["status"] == "suspended":
        return "suspended", "স্থগিত"
    if open_withdrawal(tx, inv["id"]):
        return "withdrawing", "ফেরত চেয়েছেন"
    return "active", "সক্রিয়"


def holdings(tx: Tx, inv: dict[str, Any], book: Book) -> list[dict[str, Any]]:
    share = inv["terms"]["share_percent"] / 100
    out = []
    for lot in book.investor_lots(inv["id"]):
        f = book.fraction(lot, inv["id"])
        rows = [r for r in book.rows if r["lot_id"] == lot["id"]]
        sold = lot["qty"] - book.left[lot["id"]]
        net = sum(r["net"] for r in rows)
        out.append({
            "lot_id": lot["id"], "product_id": lot["product_id"], "product_name": product_name(tx, lot["product_id"], lot.get("variant")),
            "batch": lot["ref"], "received_at": lot["received_at"], "bought": lot["qty"], "unit_cost": lot["unit_cost"],
            "invested": money(f * lot["qty"] * lot["unit_cost"]), "fraction": round(f, 4), "sold": sold, "remaining": book.left[lot["id"]],
            "sold_ratio": round(sold / lot["qty"], 4) if lot["qty"] else 0.0,
            "remaining_value": money(f * book.left[lot["id"]] * lot["unit_cost"]),
            "revenue": money(f * sum(r["revenue"] for r in rows)), "cost": money(f * sum(r["cost"] for r in rows)),
            "commission": money(f * sum(r["commission"] for r in rows)), "net": money(f * net), "share": money(f * net * share),
        })
    return out


# ---------------------------------------------------------------- money in / stock funding
def record_investment(tx: Tx, admin: dict[str, Any], data: InvestmentIn) -> dict[str, Any]:
    existing = tx.first(INV_TXNS, lambda t: t.get("client_request_id") == data.client_request_id)
    if existing:
        return {**existing, "duplicate": True}
    inv = require(tx, INVESTORS, data.investor_id, "বিনিয়োগকারী পাওয়া যায়নি।")
    _require_active(inv)
    if not data.seen_in_statement:
        raise AppError("কোম্পানির স্টেটমেন্টে টাকা ঢুকেছে কিনা নিশ্চিত হয়ে তারপর রেকর্ড করুন।", code="statement_unconfirmed")
    ref = data.reference.strip().lower()
    if tx.first(INV_TXNS, lambda t: t["kind"] == "invest" and (t.get("reference") or "").lower() == ref):
        raise Conflict("এই রেফারেন্সে আগেই একটি বিনিয়োগ রেকর্ড আছে।", code="duplicate_reference")
    txn = {"id": new_id("itx"), "investor_id": inv["id"], "kind": "invest", "amount": money(data.amount), "method": data.method,
           "reference": data.reference, "received_on": data.received_on.isoformat(), "receipt": _next_no(tx, "I"),
           "client_request_id": data.client_request_id, "by": admin["name"], "at": now_iso()}
    tx.put(INV_TXNS, txn)
    audit(tx, admin, "investor.investment_recorded", inv["id"], f"{inv['name']} · ৳{data.amount:,.0f} · {txn['receipt']}")
    notify(tx, f"investor:{inv['id']}", "investment_received", "বিনিয়োগ জমা হয়েছে", f"৳{data.amount:,.0f} পাওয়া গেছে · রসিদ {txn['receipt']}")
    return {**txn, "duplicate": False}


def fund_batch(tx: Tx, admin: dict[str, Any], data: FundedBatchIn) -> dict[str, Any]:
    total = money(data.quantity * data.unit_cost)
    split = money(sum(p.amount for p in data.parts) + data.company_amount)
    if abs(split - total) > EPS:
        raise AppError(f"ভাগের যোগফল ৳{split:,.2f}, কিন্তু মোট খরচ ৳{total:,.2f} — দুটো সমান হতে হবে।", code="split_mismatch",
                       details={"split": split, "total": total})
    ids = [p.investor_id for p in data.parts]
    if len(ids) != len(set(ids)):
        raise AppError("একই বিনিয়োগকারী দুবার দেওয়া হয়েছে।", code="duplicate_investor")
    book = Book(tx)
    for p in data.parts:
        inv = require(tx, INVESTORS, p.investor_id, "বিনিয়োগকারী পাওয়া যায়নি।")
        _require_active(inv)
        if open_withdrawal(tx, inv["id"]):
            raise AppError(f"{inv['name']} মূলধন ফেরত চেয়েছেন — ওনার টাকা নতুন স্টকে লাগানো যাবে না।", code="investor_withdrawing")
        free = position(tx, inv, book)["uninvested"]
        if p.amount > free + EPS:
            raise AppError(f"{inv['name']}-এর খাটেনি টাকা ৳{free:,.2f} — এর বেশি লাগানো যাবে না।", code="exceeds_uninvested",
                           details={"investor_id": inv["id"], "uninvested": free})
    rec = inventory.receive_stock(tx, admin, StockReceiptIn(product_id=data.product_id, variant=data.variant, quantity=data.quantity,
                                                            unit_cost=data.unit_cost, supplier=data.supplier, batch_ref=data.batch_ref))
    lot = require(tx, LOTS, rec["lot_id"])
    lot["funding"] = [{"investor_id": p.investor_id, "amount": money(p.amount)} for p in data.parts]
    lot["company_amount"] = money(data.company_amount)
    tx.put(LOTS, lot)
    name = product_name(tx, data.product_id, data.variant)
    for p in data.parts:
        notify(tx, f"investor:{p.investor_id}", "stock_funded", "নতুন স্টক কেনা হয়েছে",
               f"আপনার ৳{p.amount:,.0f} দিয়ে {name} কেনা হলো · {data.quantity:g} পিস · {data.batch_ref}")
    audit(tx, admin, "investor.batch_funded", lot["id"], f"{name} · ৳{total:,.0f} · {len(data.parts)} জন বিনিয়োগকারী")
    return lot_view(tx, lot)


def lot_view(tx: Tx, lot: dict[str, Any]) -> dict[str, Any]:
    names = {i["id"]: i["name"] for i in tx.list(INVESTORS)}
    return {**lot, "product_name": product_name(tx, lot["product_id"], lot.get("variant")), "total_cost": money(lot["qty"] * lot["unit_cost"]),
            "funding": [{**p, "investor_name": names.get(p["investor_id"], "")} for p in lot.get("funding", [])]}


def list_fundings(tx: Tx) -> list[dict[str, Any]]:
    lots = [lot for lot in tx.list(LOTS) if lot.get("funding")]
    lots.sort(key=lambda lot: lot["received_at"], reverse=True)
    return [lot_view(tx, lot) for lot in lots]


def capital_overview(tx: Tx) -> dict[str, Any]:
    book = Book(tx)
    rows = []
    for inv in tx.list(INVESTORS):
        pos = position(tx, inv, book)
        rows.append({"investor_id": inv["id"], "name": inv["name"], "code": inv["code"], "status": inv["status"],
                     "active_capital": pos["active_capital"], "in_stock": pos["in_stock"], "uninvested": pos["uninvested"],
                     "blocked": inv["status"] != "active" or pos["open_withdrawal"] is not None})
    totals = {k: money(sum(r[k] for r in rows if r["status"] == "active")) for k in ("active_capital", "in_stock", "uninvested")}
    return {"totals": totals, "investors": sorted(rows, key=lambda r: -r["active_capital"])}


# ---------------------------------------------------------------- admin views & control
def list_investors(tx: Tx, status: str | None = None, q: str | None = None) -> list[dict[str, Any]]:
    book = Book(tx)
    out = []
    for inv in tx.list(INVESTORS):
        st, label = _status_view(tx, inv)
        if status and st != status:
            continue
        if q and q not in inv["name"] and q not in inv["code"]:
            continue
        out.append({"id": inv["id"], "code": inv["code"], "name": inv["name"], "mobile_masked": mask_mobile(inv["mobile"]), "joined_at": inv["joined_at"],
                    "status": st, "status_label": label, "share_percent": inv["terms"]["share_percent"], **position(tx, inv, book)})
    return sorted(out, key=lambda r: -r["active_capital"])


def investor_detail(tx: Tx, investor_id: str) -> dict[str, Any]:
    inv = require(tx, INVESTORS, investor_id, "বিনিয়োগকারী পাওয়া যায়নি।")
    book = Book(tx)
    st, label = _status_view(tx, inv)
    return {
        "id": inv["id"], "code": inv["code"], "name": inv["name"], "mobile": inv["mobile"], "joined_at": inv["joined_at"],
        "status": st, "status_label": label, "terms": inv["terms"], "preference": inv["preference"], "payout": _payout_view(inv["payout"]),
        "nominee": {**inv["nominee"], "mobile": mask_mobile(inv["nominee"]["mobile"])}, "nid_masked": f"•••• •••• {inv['nid_last4']}",
        "position": position(tx, inv, book), "holdings": holdings(tx, inv, book), "transactions": ledger(tx, inv),
        "withdrawals": [withdrawal_view(tx, w) for w in tx.find(INV_WITHDRAWALS, lambda w: w["investor_id"] == inv["id"])],
    }


def set_status(tx: Tx, admin: dict[str, Any], investor_id: str, data: InvestorStatusIn) -> dict[str, Any]:
    inv = require(tx, INVESTORS, investor_id, "বিনিয়োগকারী পাওয়া যায়নি।")
    inv["status"] = data.status
    tx.put(INVESTORS, inv)
    audit(tx, admin, f"investor.{data.status}", inv["id"], f"{inv['name']} · কারণ: {data.reason}")
    if data.status == "suspended":
        notify(tx, f"investor:{inv['id']}", "account_suspended", "অ্যাকাউন্ট স্থগিত",
               "আপনি হিসাব দেখতে পারবেন; লাভ ও ফেরত নিয়ম অনুযায়ী চলবে। বিস্তারিত জানতে অফিসে যোগাযোগ করুন।")
    return investor_detail(tx, investor_id)


def update_terms(tx: Tx, admin: dict[str, Any], investor_id: str, terms: InvestorTermsIn) -> dict[str, Any]:
    """New terms apply to months not yet approved; approved runs never change."""
    inv = require(tx, INVESTORS, investor_id, "বিনিয়োগকারী পাওয়া যায়নি।")
    t = terms.model_dump()
    inv["terms"] = t
    inv.setdefault("terms_history", []).append({"terms": t, "from": today().isoformat(), "by": admin["name"], "at": now_iso()})
    tx.put(INVESTORS, inv)
    audit(tx, admin, "investor.terms_changed", inv["id"], f"লাভের ভাগ {t['share_percent']:g}% · নোটিশ {t['notice_days']} দিন")
    notify(tx, f"investor:{inv['id']}", "terms_changed", "চুক্তির শর্ত বদলেছে", f"লাভের ভাগ এখন {t['share_percent']:g}% — অনুমোদন না হওয়া মাস থেকে কার্যকর।")
    return investor_detail(tx, investor_id)


# ---------------------------------------------------------------- monthly profit runs
def _draft(tx: Tx, month: str, book: Book) -> dict[str, Any]:
    lines = []
    for inv in tx.list(INVESTORS):
        rows = book.investor_rows(inv["id"], month)
        net = sum(r["net"] * f for r, f in rows)
        if not rows:
            continue
        share = inv["terms"]["share_percent"]
        lines.append({"investor_id": inv["id"], "name": inv["name"], "net": money(net), "share_percent": share, "amount": money(net * share / 100),
                      "pieces": round(sum(r["qty"] * f for r, f in rows), 2), "preference": inv["preference"],
                      "payout": _payout_view(inv["payout"]), "paid": False, "txn_id": None})
    by_product: dict[str, dict[str, float]] = {}
    for r in book.rows:
        if r["month"] != month:
            continue
        lot = book.lot_by_id[r["lot_id"]]
        f = sum(book.fraction(lot, p["investor_id"]) for p in lot.get("funding", []))
        if f <= 0:
            continue
        agg = by_product.setdefault(r["product_id"], {"revenue": 0.0, "cost": 0.0, "commission": 0.0, "net": 0.0})
        for k in agg:
            agg[k] += r[k] * f
    products = [{"product_id": pid, "product_name": product_name(tx, pid), **{k: money(v) for k, v in agg.items()}} for pid, agg in by_product.items()]
    return {"month": month, "status": "draft", "closes_on": _month_end(month).isoformat(), "lines": lines, "products": products}


def _totals(run: dict[str, Any]) -> dict[str, Any]:
    lines = run["lines"]
    return {"net": money(sum(x["net"] for x in lines)), "investors_share": money(sum(x["amount"] for x in lines)),
            "cash": money(sum(x["amount"] for x in lines if x["preference"] == "cash")),
            "reinvest": money(sum(x["amount"] for x in lines if x["preference"] == "reinvest")),
            "paid": money(sum(x["amount"] for x in lines if x["paid"]))}


def profit_run(tx: Tx, month: str) -> dict[str, Any]:
    _check_month(month)
    run = tx.get(INV_RUNS, f"run_{month}")
    if not run:
        run = _draft(tx, month, Book(tx))
        run["can_approve"] = _month_end(month) < today()
    else:
        run = {**run, "can_approve": False}
    return {**run, "totals": _totals(run)}


def approve_run(tx: Tx, admin: dict[str, Any], month: str) -> dict[str, Any]:
    _check_month(month)
    if tx.get(INV_RUNS, f"run_{month}"):
        raise Conflict("এই মাসের লাভ বিতরণ আগেই অনুমোদিত হয়েছে।", code="already_approved")
    if _month_end(month) >= today():
        raise AppError("মাস শেষ হওয়ার পর অনুমোদন করা যাবে।", code="month_open")
    open_corr = [c for c in tx.list(CORRECTIONS) if c["status"] == "pending"
                 and (s := tx.get(SALES, c["sale_id"])) is not None and _month_of(s["created_at"]) == month]
    if open_corr:
        raise AppError("এই মাসের বিক্রিতে খোলা সংশোধনের অনুরোধ আছে — আগে সেগুলো শেষ করুন।", code="open_corrections")
    draft = _draft(tx, month, Book(tx))
    run = {"id": f"run_{month}", "month": month, "status": "approved", "lines": draft["lines"], "products": draft["products"],
           "approved_by": admin["name"], "approved_at": now_iso()}
    tx.put(INV_RUNS, run)
    for line in run["lines"]:
        notify(tx, f"investor:{line['investor_id']}", "profit_approved", "মাসিক লাভের হিসাব প্রস্তুত",
               f"{month}: আপনার ভাগ ৳{line['amount']:,.0f}। পেমেন্টের দিন অ্যাপে দেখুন।")
    audit(tx, admin, "investor.profit_approved", run["id"], f"{len(run['lines'])} জন · ৳{_totals(run)['investors_share']:,.0f}")
    return {**run, "totals": _totals(run), "can_approve": False}


def pay_profit(tx: Tx, admin: dict[str, Any], month: str, data: ProfitPaymentIn) -> dict[str, Any]:
    run = require(tx, INV_RUNS, f"run_{month}", "এই মাসের অনুমোদিত হিসাব নেই।")
    line = next((x for x in run["lines"] if x["investor_id"] == data.investor_id), None)
    if not line:
        raise AppError("এই মাসে এই বিনিয়োগকারীর লাভ নেই।", code="no_line")
    if line["paid"]:
        return {**run, "totals": _totals(run), "duplicate": True}
    if line["preference"] == "cash" and not (data.reference or "").strip():
        raise AppError("টাকা পাঠানোর রেফারেন্স দিন।", code="reference_required")
    kind = "profit" if line["preference"] == "cash" else "reinvest"
    txn = {"id": new_id("itx"), "investor_id": line["investor_id"], "kind": kind, "amount": line["amount"], "month": month,
           "method": line["payout"]["method"] if kind == "profit" else None, "reference": data.reference,
           "receipt": _next_no(tx, "P" if kind == "profit" else "R"), "client_request_id": data.client_request_id, "by": admin["name"], "at": now_iso()}
    tx.put(INV_TXNS, txn)
    line["paid"], line["txn_id"] = True, txn["id"]
    if all(x["paid"] for x in run["lines"]):
        run["status"] = "paid"
    tx.put(INV_RUNS, run)
    text = f"{month}-এর লাভ ৳{line['amount']:,.0f} " + ("পাঠানো হয়েছে" if kind == "profit" else "আবার বিনিয়োগ হিসেবে যোগ হয়েছে") + f" · রসিদ {txn['receipt']}"
    notify(tx, f"investor:{line['investor_id']}", "profit_paid", "লাভ জমা হয়েছে", text)
    audit(tx, admin, "investor.profit_paid", line["investor_id"], text)
    return {**run, "totals": _totals(run), "duplicate": False}


# ---------------------------------------------------------------- withdrawals
def withdrawal_view(tx: Tx, w: dict[str, Any]) -> dict[str, Any]:
    inv = tx.get(INVESTORS, w["investor_id"]) or {}
    return {**{k: v for k, v in w.items() if k != "client_request_id"}, "status_label": WD_LABEL[w["status"]], "investor_name": inv.get("name", ""),
            "remaining": money(w["amount"] - w["paid"])}


def request_withdrawal(tx: Tx, inv: dict[str, Any], user: dict[str, Any], data: WithdrawalRequestIn) -> dict[str, Any]:
    existing = tx.first(INV_WITHDRAWALS, lambda w: w["investor_id"] == inv["id"] and w.get("client_request_id") == data.client_request_id)
    if existing:
        return {**withdrawal_view(tx, existing), "duplicate": True}
    _require_active(inv)
    if open_withdrawal(tx, inv["id"]):
        raise Conflict("আগের একটি ফেরতের অনুরোধ এখনো খোলা আছে।", code="withdrawal_open")
    pos = position(tx, inv)
    if data.amount > pos["active_capital"] + EPS:
        raise AppError(f"সক্রিয় মূলধন ৳{pos['active_capital']:,.0f} — এর বেশি ফেরত চাওয়া যাবে না।", code="exceeds_capital")
    w = {"id": new_id("iwd"), "investor_id": inv["id"], "amount": money(data.amount), "reason": data.reason, "status": "pending",
         "requested_at": now_iso(), "deadline": (today() + timedelta(days=int(inv["terms"]["notice_days"]))).isoformat(),
         "paid": 0.0, "payments": [], "client_request_id": data.client_request_id}
    tx.put(INV_WITHDRAWALS, w)
    notify(tx, "admin", "investor_withdrawal", "মূলধন ফেরতের অনুরোধ", f"{inv['name']} · ৳{data.amount:,.0f}", "/investor-withdrawals")
    audit(tx, user, "investor.withdrawal_requested", w["id"], f"৳{data.amount:,.0f}")
    return {**withdrawal_view(tx, w), "duplicate": False}


def list_withdrawals(tx: Tx, status: str | None = None, investor_id: str | None = None) -> list[dict[str, Any]]:
    items = [w for w in tx.list(INV_WITHDRAWALS) if (not status or w["status"] == status) and (not investor_id or w["investor_id"] == investor_id)]
    items.sort(key=lambda w: w["requested_at"], reverse=True)
    return [withdrawal_view(tx, w) for w in items]


def approve_withdrawal(tx: Tx, admin: dict[str, Any], wd_id: str, note: str | None) -> dict[str, Any]:
    w = require(tx, INV_WITHDRAWALS, wd_id, "অনুরোধ পাওয়া যায়নি।")
    if w["status"] != "pending":
        raise Conflict("শুধু অপেক্ষমাণ অনুরোধ অনুমোদন করা যায়।", code="invalid_status")
    w["status"], w["decided_by"], w["decided_at"], w["note"] = "approved", admin["name"], now_iso(), note
    tx.put(INV_WITHDRAWALS, w)
    notify(tx, f"investor:{w['investor_id']}", "withdrawal_approved", "ফেরতের অনুরোধ অনুমোদিত",
           f"৳{w['amount']:,.0f} · শেষ তারিখ {w['deadline']}। খাটেনি টাকা আগে, বাকিটা বিক্রির টাকা থেকে।")
    audit(tx, admin, "investor.withdrawal_approved", wd_id, f"৳{w['amount']:,.0f}")
    return withdrawal_view(tx, w)


def reject_withdrawal(tx: Tx, admin: dict[str, Any], wd_id: str, reason: str) -> dict[str, Any]:
    w = require(tx, INV_WITHDRAWALS, wd_id, "অনুরোধ পাওয়া যায়নি।")
    if w["status"] not in ("pending", "approved") or w["paid"] > 0:
        raise Conflict("এই অনুরোধ এখন বাতিল করা যাবে না।", code="invalid_status")
    w["status"], w["decided_by"], w["decided_at"], w["reject_reason"] = "rejected", admin["name"], now_iso(), reason
    tx.put(INV_WITHDRAWALS, w)
    notify(tx, f"investor:{w['investor_id']}", "withdrawal_rejected", "ফেরতের অনুরোধ বাতিল", f"কারণ: {reason}")
    audit(tx, admin, "investor.withdrawal_rejected", wd_id, reason)
    return withdrawal_view(tx, w)


def pay_withdrawal(tx: Tx, admin: dict[str, Any], wd_id: str, data: InvestorPaymentIn) -> dict[str, Any]:
    w = require(tx, INV_WITHDRAWALS, wd_id, "অনুরোধ পাওয়া যায়নি।")
    if any(p["client_request_id"] == data.client_request_id for p in w["payments"]):
        return {**withdrawal_view(tx, w), "duplicate": True}
    if w["status"] != "approved":
        raise Conflict("শুধু অনুমোদিত অনুরোধে পেমেন্ট দেওয়া যায়।", code="invalid_status")
    remaining = money(w["amount"] - w["paid"])
    if data.amount > remaining + EPS:
        raise AppError(f"বাকি আছে ৳{remaining:,.0f} — এর বেশি দেওয়া যাবে না।", code="exceeds_remaining")
    inv = require(tx, INVESTORS, w["investor_id"])
    free = position(tx, inv)["uninvested"]
    if data.amount > free + EPS:
        raise AppError(f"এখন ওনার খাটেনি টাকা ৳{free:,.0f} — বাকিটা স্টক বিক্রি হলে দেওয়া যাবে।", code="insufficient_cash",
                       details={"uninvested": free})
    txn = {"id": new_id("itx"), "investor_id": inv["id"], "kind": "withdraw", "amount": money(data.amount), "method": inv["payout"]["method"],
           "reference": data.reference, "receipt": _next_no(tx, "W"), "withdrawal_id": wd_id, "client_request_id": data.client_request_id,
           "by": admin["name"], "at": now_iso()}
    tx.put(INV_TXNS, txn)
    w["paid"] = money(w["paid"] + data.amount)
    w["payments"].append({"txn_id": txn["id"], "amount": txn["amount"], "reference": data.reference, "at": txn["at"], "client_request_id": data.client_request_id})
    if w["paid"] >= w["amount"] - EPS:
        w["status"] = "paid"
    tx.put(INV_WITHDRAWALS, w)
    notify(tx, f"investor:{inv['id']}", "withdrawal_paid", "মূলধন ফেরত পাঠানো হয়েছে", f"৳{data.amount:,.0f} · রসিদ {txn['receipt']}")
    audit(tx, admin, "investor.withdrawal_paid", wd_id, f"৳{data.amount:,.0f} · {txn['receipt']}")
    return {**withdrawal_view(tx, w), "duplicate": False}


# ---------------------------------------------------------------- investor app views
def ledger(tx: Tx, inv: dict[str, Any]) -> list[dict[str, Any]]:
    items = sorted(tx.find(INV_TXNS, lambda t: t["investor_id"] == inv["id"]), key=lambda t: t["at"], reverse=True)
    return [{"id": t["id"], "kind": t["kind"], "label": TXN_LABEL[t["kind"]], "amount": t["amount"], "receipt": t["receipt"],
             "method": METHOD_LABEL.get(t.get("method") or "", "—"), "reference": t.get("reference"), "month": t.get("month"), "at": t["at"]} for t in items]


def self_profile(inv: dict[str, Any]) -> dict[str, Any]:
    nominee = inv.get("nominee") or {}
    return {
        "name": inv["name"], "mobile": mask_mobile(inv["mobile"]),
        "nid_masked": "••••" + inv.get("nid_last4", ""),
        "address": inv.get("address") or {}, "terms": inv["terms"],
        "payout": _payout_view(inv["payout"]) if inv.get("payout") else {},
        "nominee": {"name": nominee.get("name"), "relation": nominee.get("relation"),
                    "mobile": mask_mobile(nominee.get("mobile") or "")},
    }


def dashboard(tx: Tx, inv: dict[str, Any]) -> dict[str, Any]:
    book = Book(tx)
    pos = position(tx, inv, book)
    t = today()
    today_rows = [(r, f) for r, f in book.investor_rows(inv["id"]) if r["day"] == t]
    lots = book.investor_lots(inv["id"])
    unread = len(tx.find("notifications", lambda n: n["audience"] == f"investor:{inv['id']}" and not n["read"]))
    return {
        "name": inv["name"], "code": inv["code"], "status": _status_view(tx, inv)[0], "terms": inv["terms"], "preference": inv["preference"],
        "joined_at": inv.get("joined_at"), "profit_paid_count": sum(1 for _, line in _approved_lines(tx, inv["id"]) if line["paid"]),
        **pos,
        "stock": {"bought": sum(lot["qty"] for lot in lots), "sold": sum(lot["qty"] - book.left[lot["id"]] for lot in lots),
                  "remaining": sum(book.left[lot["id"]] for lot in lots)},
        "today": {"pieces": round(sum(r["qty"] for r, _ in today_rows), 2), "amount": money(sum(r["revenue"] for r, _ in today_rows))},
        "unread_notifications": unread,
    }


def portfolio(tx: Tx, inv: dict[str, Any]) -> dict[str, Any]:
    book = Book(tx)
    pos = position(tx, inv, book)
    return {"active_capital": pos["active_capital"], "in_stock": pos["in_stock"], "uninvested": pos["uninvested"], "holdings": holdings(tx, inv, book)}


def product_detail(tx: Tx, inv: dict[str, Any], product_id: str) -> dict[str, Any]:
    book = Book(tx)
    lots = [h for h in holdings(tx, inv, book) if h["product_id"] == product_id]
    if not lots:
        raise Forbidden("এই প্রোডাক্টে আপনার বিনিয়োগ নেই।", code="not_your_product")
    sellers = []
    for s in tx.list(SELLERS):
        in_hand = sum(x["qty"] for x in tx.find(SELLER_STOCK, lambda x: x["seller_id"] == s["id"] and x["product_id"] == product_id))
        sold = sum(r["qty"] for r in book.rows if r["seller_id"] == s["id"] and r["product_id"] == product_id)
        if in_hand or sold:
            sellers.append({"name": s["name"], "area": _area(s), "in_hand": in_hand, "sold": sold})
    keys = ("invested", "revenue", "cost", "commission", "net", "share")
    return {"product_id": product_id, "product_name": product_name(tx, product_id), "lots": lots,
            "totals": {k: money(sum(h[k] for h in lots)) for k in keys}, "share_percent": inv["terms"]["share_percent"],
            "sellers": sorted(sellers, key=lambda x: -x["in_hand"])}


def sellers_view(tx: Tx, inv: dict[str, Any]) -> list[dict[str, Any]]:
    """Sellers holding the investor's products. Never includes phone, NID or address detail."""
    book = Book(tx)
    products = {lot["product_id"] for lot in book.investor_lots(inv["id"])}
    t = today()
    out = []
    for s in tx.list(SELLERS):
        stock = [x for x in tx.find(SELLER_STOCK, lambda x: x["seller_id"] == s["id"] and x["product_id"] in products) if x["qty"] > 0]
        rows = [r for r in book.rows if r["seller_id"] == s["id"] and r["product_id"] in products]
        if not stock and not rows:
            continue
        today_rows = [r for r in rows if r["day"] == t]
        week_rows = [r for r in rows if t - timedelta(days=t.weekday()) <= r["day"] <= t]
        month_rows = [r for r in rows if t.replace(day=1) <= r["day"] <= t]
        items: dict[str, float] = {}
        for x in stock:
            items[x["product_id"]] = items.get(x["product_id"], 0) + x["qty"]
        out.append({"name": s["name"], "area": _area(s), "in_hand": sum(items.values()),
                    "items": [{"product_name": product_name(tx, pid), "qty": q} for pid, q in items.items()],
                    "sold_today": round(sum(r["qty"] for r in today_rows), 2), "amount_today": money(sum(r["revenue"] for r in today_rows)),
                    "sold_week": round(sum(r["qty"] for r in week_rows), 2), "amount_week": money(sum(r["revenue"] for r in week_rows)),
                    "sold_month": round(sum(r["qty"] for r in month_rows), 2), "amount_month": money(sum(r["revenue"] for r in month_rows)),
                    "last_sale_at": max((r["at"] for r in rows), default=None)})
    return sorted(out, key=lambda x: -x["in_hand"])


def reports(tx: Tx, inv: dict[str, Any]) -> list[dict[str, Any]]:
    book = Book(tx)
    share = inv["terms"]["share_percent"] / 100
    frozen = {run["month"]: line for run, line in _approved_lines(tx, inv["id"])}
    months = sorted({r["month"] for r, _ in book.investor_rows(inv["id"])} | set(frozen), reverse=True)
    txns = tx.find(INV_TXNS, lambda x: x["investor_id"] == inv["id"])
    out = []
    for m in months:
        rows = book.investor_rows(inv["id"], m)
        capital = sum(x["amount"] for x in txns if x["kind"] in ("invest", "reinvest") and _month_of(x["at"]) == m) \
            - sum(x["amount"] for x in txns if x["kind"] == "withdraw" and _month_of(x["at"]) == m)
        line = frozen.get(m)
        out.append({
            "month": m, "status": ("paid" if line["paid"] else "approved") if line else "draft",
            "pieces": round(sum(r["qty"] * f for r, f in rows), 2), "capital_change": money(capital),
            **{k: money(sum(r[k] * f for r, f in rows)) for k in ("revenue", "cost", "commission", "net")},
            "share": line["amount"] if line else money(sum(r["net"] * f for r, f in rows) * share),
        })
    return out


def set_preference(tx: Tx, inv: dict[str, Any], user: dict[str, Any], preference: str) -> dict[str, Any]:
    inv["preference"] = preference
    tx.put(INVESTORS, inv)
    audit(tx, user, "investor.preference_changed", inv["id"], "টাকা নেবেন" if preference == "cash" else "আবার বিনিয়োগ")
    return {"preference": preference}
