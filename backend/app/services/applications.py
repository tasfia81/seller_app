"""Seller onboarding: application → review → approve / reject / request more info."""

from typing import Any

from ..core.errors import Conflict, Forbidden, AppError
from ..core.security import hash_password
from ..core.utils import mask_nid, new_id, now_iso, today
from ..schemas import ApplicationIn, RequestInfoIn
from ..storage import Tx
from .common import APPLICATIONS, SELLERS, SETTINGS, USERS, audit, notify, require

DOC_KINDS = ("nid_front", "nid_back", "photo")
STATUS_LABEL = {
    "submitted": "জমা হয়েছে",
    "under_review": "যাচাই চলছে",
    "more_info": "আরও তথ্য প্রয়োজন",
    "approved": "অনুমোদিত",
    "rejected": "বাতিল",
}


def _address(a: dict[str, Any]) -> str:
    return f"{a['detail']}, {a['upazila']}, {a['district']}"


def public_view(app: dict[str, Any], *, include_private: bool = False) -> dict[str, Any]:
    """Never exposes the full NID or document file paths."""
    out = {
        "id": app["id"],
        "status": app["status"],
        "status_label": STATUS_LABEL[app["status"]],
        "submitted_at": app["submitted_at"],
        "full_name": app["full_name"],
        "mobile": app["mobile"],
        "date_of_birth": app["date_of_birth"],
        "gender": app.get("gender"),
        "email": app.get("email"),
        "guardian_name": app.get("guardian_name"),
        "present_address": app["present_address"],
        "permanent_address": app["permanent_address"],
        "nid_masked": mask_nid(app["nid_number"]),
        "emergency": app["emergency"],
        "documents": {k: {"uploaded": k in app["documents"], "uploaded_at": app["documents"].get(k, {}).get("uploaded_at")} for k in DOC_KINDS},
        "requested_fields": app.get("requested_fields", []),
        "admin_message": app.get("admin_message"),
        "rejection_reason": app.get("rejection_reason"),
        "timeline": app.get("timeline", []),
    }
    if include_private:
        out["checklist"] = app.get("checklist", {})
    return out


def submit(tx: Tx, data: ApplicationIn) -> dict[str, Any]:
    if not (data.accepted_privacy and data.accepted_terms):
        raise AppError("গোপনীয়তা নীতি ও শর্তাবলি মেনে নিতে হবে।", code="consent_required")
    if tx.first(USERS, lambda u: u.get("mobile") == data.mobile):
        raise Conflict("এই মোবাইল নম্বরে আগেই অ্যাকাউন্ট বা আবেদন আছে।", code="mobile_exists")
    if tx.first(APPLICATIONS, lambda a: a["nid_number"] == data.nid_number and a["status"] != "rejected"):
        raise Conflict("এই পরিচয়পত্র দিয়ে আগেই আবেদন করা হয়েছে।", code="nid_exists")
    dob = data.date_of_birth
    t = today()
    age = t.year - dob.year - ((t.month, t.day) < (dob.month, dob.day))
    min_age = (tx.get(SETTINGS, "main") or {}).get("onboarding", {}).get("minimum_age", 18)
    if dob > t:
        raise AppError("ভবিষ্যতের জন্মতারিখ দেওয়া যাবে না।", code="invalid_dob")
    if age < min_age:
        raise AppError(f"আবেদনের জন্য বয়স কমপক্ষে {min_age} বছর হতে হবে।", code="underage")

    app_id = new_id("app")
    user_id = new_id("usr")
    at = now_iso()
    tx.put(APPLICATIONS, {
        "id": app_id, "user_id": user_id, "status": "submitted", "submitted_at": at,
        "full_name": data.full_name, "mobile": data.mobile, "date_of_birth": dob.isoformat(),
        "gender": data.gender, "email": data.email, "guardian_name": data.guardian_name,
        "present_address": _address(data.present_address.model_dump()),
        "permanent_address": _address(data.permanent_address.model_dump()),
        "nid_number": data.nid_number,  # restricted: only returned masked, reveal is audited
        "emergency": data.emergency.model_dump(),
        "documents": {}, "requested_fields": [], "checklist": {},
        "timeline": [{"title": "আবেদন জমা হয়েছে", "at": at, "by": data.full_name}],
    })
    tx.put(USERS, {
        "id": user_id, "role": "seller", "name": data.full_name, "mobile": data.mobile, "email": data.email,
        "password_hash": hash_password(data.password), "status": "applicant", "application_id": app_id,
        "seller_id": None, "session_version": 0, "created_at": at,
    })
    notify(tx, "admin", "new_application", "নতুন সেলার আবেদন", f"{data.full_name} আবেদন করেছেন।", f"/applications/{app_id}")
    return {"application_id": app_id, "user_id": user_id}


def record_document(tx: Tx, user: dict[str, Any], kind: str, file_ref: str, content_type: str) -> dict[str, Any]:
    app = require(tx, APPLICATIONS, user.get("application_id") or "", "আবেদন পাওয়া যায়নি।")
    if app["status"] in ("approved", "rejected", "under_review") and kind not in app.get("requested_fields", []):
        raise Forbidden("এই অবস্থায় ছবি বদলানো যাবে না।", code="documents_locked")
    app["documents"][kind] = {"file": file_ref, "content_type": content_type, "uploaded_at": now_iso()}
    tx.put(APPLICATIONS, app)
    return public_view(app)


def resubmit(tx: Tx, user: dict[str, Any]) -> dict[str, Any]:
    app = require(tx, APPLICATIONS, user.get("application_id") or "", "আবেদন পাওয়া যায়নি।")
    if app["status"] != "more_info":
        raise AppError("এখন আবার জমা দেওয়ার কিছু নেই।", code="nothing_to_resubmit")
    app["status"] = "submitted"
    app["timeline"].append({"title": "চাওয়া তথ্য আবার জমা দিয়েছেন", "at": now_iso(), "by": app["full_name"]})
    tx.put(APPLICATIONS, app)
    notify(tx, "admin", "application_resubmitted", "আবেদনে তথ্য যোগ হয়েছে", f"{app['full_name']} চাওয়া তথ্য দিয়েছেন।", f"/applications/{app['id']}")
    return public_view(app)


def list_applications(tx: Tx, status: str | None, q: str | None) -> list[dict[str, Any]]:
    apps = tx.list(APPLICATIONS)
    if status:
        apps = [a for a in apps if a["status"] == status]
    if q:
        apps = [a for a in apps if q in a["full_name"] or q in a["mobile"]]
    apps.sort(key=lambda a: a["submitted_at"], reverse=True)
    return [{"id": a["id"], "full_name": a["full_name"], "mobile": a["mobile"], "submitted_at": a["submitted_at"], "status": a["status"], "status_label": STATUS_LABEL[a["status"]], "has_photo": "photo" in a["documents"]} for a in apps]


def _transition(tx: Tx, admin: dict[str, Any], app_id: str, allowed: tuple[str, ...], new_status: str, title: str) -> dict[str, Any]:
    app = require(tx, APPLICATIONS, app_id, "আবেদন পাওয়া যায়নি।")
    if app["status"] not in allowed:
        raise Conflict(f"“{STATUS_LABEL[app['status']]}” অবস্থায় এই কাজ করা যাবে না।", code="invalid_status")
    app["status"] = new_status
    app["timeline"].append({"title": title, "at": now_iso(), "by": admin["name"]})
    return app


def start_review(tx: Tx, admin: dict[str, Any], app_id: str) -> dict[str, Any]:
    app = _transition(tx, admin, app_id, ("submitted",), "under_review", "যাচাই শুরু হয়েছে")
    tx.put(APPLICATIONS, app)
    audit(tx, admin, "application.review_started", app_id, app["full_name"])
    return public_view(app, include_private=True)


def approve(tx: Tx, admin: dict[str, Any], app_id: str) -> dict[str, Any]:
    app = _transition(tx, admin, app_id, ("submitted", "under_review"), "approved", "অনুমোদিত")
    missing = [k for k in DOC_KINDS if k not in app["documents"]]
    if missing:
        raise AppError("সব ছবি জমা না হলে অনুমোদন দেওয়া যাবে না।", code="documents_missing", details={"missing": missing})
    settings = tx.get(SETTINGS, "main") or {}
    defaults = settings.get("onboarding", {})
    seller_id = new_id("slr")
    rule = defaults.get("default_compensation", {"model": "profit", "profit_percent": 40})
    tx.put(SELLERS, {
        "id": seller_id, "user_id": app["user_id"], "application_id": app_id,
        "name": app["full_name"], "mobile": app["mobile"], "status": "active",
        "compensation": {**rule, "effective_from": today().isoformat()},
        "compensation_history": [{"from": None, "to": rule, "effective_from": today().isoformat(), "by": admin["name"], "reason": "যোগদান", "at": now_iso()}],
        "policy": settings.get("inventory", {}).get("default_policy", "daily_return"),
        "permissions": {"can_edit_price": True, "can_discount": False, "can_take_digital": True},
        "present_address": app["present_address"], "permanent_address": app["permanent_address"],
        "emergency": app["emergency"], "nid_last4": app["nid_number"][-4:], "joined_at": now_iso(),
    })
    user = require(tx, USERS, app["user_id"])
    user["status"] = "active"
    user["seller_id"] = seller_id
    tx.put(USERS, user)
    tx.put(APPLICATIONS, app)
    audit(tx, admin, "application.approved", app_id, f"{app['full_name']} অনুমোদিত")
    notify(tx, f"seller:{seller_id}", "application_approved", "আবেদন অনুমোদিত", "আপনার অ্যাকাউন্ট চালু হয়েছে। এখন লগইন করে কাজ শুরু করুন।")
    return {**public_view(app, include_private=True), "seller_id": seller_id}


def reject(tx: Tx, admin: dict[str, Any], app_id: str, reason: str) -> dict[str, Any]:
    app = _transition(tx, admin, app_id, ("submitted", "under_review", "more_info"), "rejected", "বাতিল")
    app["rejection_reason"] = reason
    tx.put(APPLICATIONS, app)
    user = require(tx, USERS, app["user_id"])
    user["status"] = "disabled"
    user["session_version"] = user.get("session_version", 0) + 1
    tx.put(USERS, user)
    audit(tx, admin, "application.rejected", app_id, f"কারণ: {reason}")
    return public_view(app, include_private=True)


def request_info(tx: Tx, admin: dict[str, Any], app_id: str, data: RequestInfoIn) -> dict[str, Any]:
    app = _transition(tx, admin, app_id, ("submitted", "under_review"), "more_info", "আরও তথ্য চাওয়া হয়েছে")
    app["requested_fields"] = data.fields
    app["admin_message"] = data.message
    for f in data.fields:
        app["documents"].pop(f, None)
    tx.put(APPLICATIONS, app)
    audit(tx, admin, "application.more_info", app_id, ", ".join(data.fields))
    return public_view(app, include_private=True)


def reveal_nid(tx: Tx, admin: dict[str, Any], app_id: str) -> dict[str, Any]:
    app = require(tx, APPLICATIONS, app_id, "আবেদন পাওয়া যায়নি।")
    audit(tx, admin, "application.nid_viewed", app_id, "পুরো পরিচয়পত্র নম্বর দেখা হয়েছে")
    return {"nid_number": app["nid_number"]}


def document_ref(tx: Tx, admin: dict[str, Any], app_id: str, kind: str) -> dict[str, Any]:
    app = require(tx, APPLICATIONS, app_id, "আবেদন পাওয়া যায়নি।")
    doc = app["documents"].get(kind)
    if not doc:
        raise AppError("এই ছবি এখনো জমা হয়নি।", code="document_missing")
    audit(tx, admin, "application.document_viewed", app_id, kind)
    return doc
