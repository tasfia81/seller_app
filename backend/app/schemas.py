"""Request bodies for every endpoint. Pydantic validates input before any service runs."""

from datetime import date
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from .core.utils import is_bd_mobile, normalize_mobile

Unit = Literal["piece", "kg", "gram", "liter", "packet", "bottle", "box"]
Payment = Literal["cash", "bkash", "nagad", "bank", "other"]
HandoverMethod = Literal["in_person", "bkash", "nagad", "bank"]
Policy = Literal["daily_return", "carry_forward"]
Model = Literal["profit", "daily", "per_unit", "hybrid"]


class In(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


def _mobile(v: str) -> str:
    if not is_bd_mobile(v):
        raise ValueError("সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন")
    return normalize_mobile(v)


# ---------- auth ----------
class LoginIn(In):
    identifier: str = Field(min_length=3, description="মোবাইল নম্বর বা ইমেইল")
    password: str = Field(min_length=1)


class ChangePasswordIn(In):
    current_password: str = Field(min_length=1)
    new_password: str = Field(min_length=8)


class OtpRequestIn(In):
    mobile: str


class OtpVerifyIn(In):
    mobile: str
    code: str = Field(min_length=6, max_length=6)
    new_password: str = Field(min_length=8)


# ---------- seller application ----------
class AddressIn(In):
    division: str = Field(min_length=2)
    district: str = Field(min_length=2)
    upazila: str = Field(min_length=2)
    detail: str = Field(min_length=2)


class EmergencyIn(In):
    name: str = Field(min_length=2)
    relation: str = Field(min_length=2)
    mobile: str
    @field_validator("mobile")
    @classmethod
    def check_mobile(cls, v: str) -> str:
        return _mobile(v)


class ApplicationIn(In):
    otp_code: str | None = Field(default=None, pattern=r"^[0-9]{6}$")
    full_name: str = Field(min_length=2, max_length=80)
    mobile: str
    date_of_birth: date
    gender: str | None = None
    email: str | None = None
    guardian_name: str | None = None
    present_address: AddressIn
    permanent_address: AddressIn
    nid_number: str
    emergency: EmergencyIn
    password: str = Field(min_length=8)
    accepted_privacy: bool
    accepted_terms: bool

    @field_validator("mobile")
    @classmethod
    def check_mobile(cls, v: str) -> str:
        return _mobile(v)

    @field_validator("nid_number")
    @classmethod
    def check_nid(cls, v: str) -> str:
        digits = "".join(c for c in v if c.isdigit())
        if len(digits) not in (10, 13, 17):
            raise ValueError("১০, ১৩ বা ১৭ সংখ্যার পরিচয়পত্র নম্বর দিন")
        return digits

    @field_validator("password")
    @classmethod
    def check_password(cls, v: str) -> str:
        if not any(c.isdigit() for c in v):
            raise ValueError("পাসওয়ার্ডে অন্তত একটি সংখ্যা দিন")
        return v


class ReviewRejectIn(In):
    reason: str = Field(min_length=3)


class RequestInfoIn(In):
    fields: list[Literal["nid_front", "nid_back", "photo", "present_address", "permanent_address", "emergency"]] = Field(min_length=1)
    message: str = Field(min_length=3)


# ---------- sellers ----------
class SellerUpdateIn(In):
    mobile: str | None = None
    present_address: str | None = None
    policy: Policy | None = None
    can_edit_price: bool | None = None
    can_discount: bool | None = None
    can_take_digital: bool | None = None

    @field_validator("mobile")
    @classmethod
    def check_optional_mobile(cls, v: str | None) -> str | None:
        return _mobile(v) if v else v


class CompensationIn(In):
    model: Model
    profit_percent: float | None = Field(default=None, gt=0, le=100)
    daily_wage: float | None = Field(default=None, gt=0)
    per_unit: float | None = Field(default=None, gt=0)
    effective_from: date
    reason: str = Field(min_length=3)


class ProfileChangeIn(In):
    field: Literal["mobile", "present_address", "emergency_contact"]
    new_value: str = Field(min_length=3)
    note: str | None = None


# ---------- catalog ----------
class CategoryIn(In):
    name: str = Field(min_length=2, max_length=40)


class ProductIn(In):
    name: str = Field(min_length=2, max_length=80)
    category_id: str
    sku: str = Field(min_length=2, max_length=30)
    description: str | None = None
    unit: Unit = "piece"
    quantity_step: float = Field(default=1, gt=0)
    unit_cost: float = Field(ge=0)
    price: float = Field(gt=0)
    min_price: float | None = Field(default=None, gt=0)
    max_price: float | None = Field(default=None, gt=0)
    price_editable: bool = False
    variant_label: str | None = None
    variants: list[str] = []
    low_stock_at: float = Field(default=10, ge=0)
    track_stock: bool = True
    track_expiry: bool = False
    discount_allowed: bool = False
    commission_override: dict[str, float] | None = None
    active: bool = True


class ProductUpdateIn(In):
    name: str | None = None
    category_id: str | None = None
    description: str | None = None
    unit_cost: float | None = Field(default=None, ge=0)
    price: float | None = Field(default=None, gt=0)
    min_price: float | None = None
    max_price: float | None = None
    price_editable: bool | None = None
    variants: list[str] | None = None
    low_stock_at: float | None = None
    discount_allowed: bool | None = None
    active: bool | None = None


# ---------- inventory ----------
class StockReceiptIn(In):
    product_id: str
    variant: str | None = None
    quantity: float = Field(gt=0)
    unit_cost: float = Field(ge=0)
    supplier: str | None = None
    purchase_date: date | None = None
    batch_ref: str | None = None
    expiry_date: date | None = None
    note: str | None = None


class AssignItemIn(In):
    product_id: str
    variant: str | None = None
    quantity: float = Field(gt=0)


class AssignmentIn(In):
    seller_id: str
    items: list[AssignItemIn] = Field(min_length=1)
    price_mode: Literal["fixed", "flexible"] = "fixed"
    discount_allowed: bool = False
    policy: Literal["seller_default", "daily_return", "carry_forward"] = "seller_default"


class TransferIn(In):
    kind: Literal["recall", "seller_to_seller"]
    seller_id: str
    to_seller_id: str | None = None
    product_id: str
    variant: str | None = None
    quantity: float = Field(gt=0)
    reason: str = Field(min_length=3)


class DamageIn(In):
    product_id: str
    variant: str | None = None
    quantity: float = Field(gt=0)
    seller_id: str | None = None
    reason: str = Field(min_length=3)


# ---------- sales ----------
class SaleIn(In):
    product_id: str
    variant: str | None = None
    quantity: float = Field(gt=0)
    unit_price: float = Field(gt=0)
    payment: Payment
    note: str | None = Field(default=None, max_length=200)
    client_request_id: str = Field(min_length=8, max_length=80, description="Idempotency key")


class CorrectionIn(In):
    quantity: float | None = Field(default=None, gt=0)
    unit_price: float | None = Field(default=None, gt=0)
    payment: Payment | None = None
    reason: str = Field(min_length=3)


class AdminNoteIn(In):
    note: str | None = None


# ---------- money ----------
class HandoverIn(In):
    amount: float = Field(gt=0)
    method: HandoverMethod
    reference: str | None = None
    note: str | None = None


class VerifyHandoverIn(In):
    received_amount: float = Field(gt=0)
    note: str | None = None


class PayoutIn(In):
    seller_id: str
    amount: float = Field(gt=0)
    method: HandoverMethod
    reference: str | None = None
    note: str | None = None
    client_request_id: str = Field(min_length=8, max_length=80)


class ExpenseIn(In):
    category: Literal["transport", "packaging", "storage", "rent", "marketing", "wastage", "misc"]
    amount: float = Field(gt=0)
    date: date
    description: str = Field(min_length=2)
    seller_id: str | None = None
    product_id: str | None = None


# ---------- returns / settlements ----------
class ReturnIn(In):
    product_id: str
    variant: str | None = None
    quantity: float = Field(gt=0)
    reason: Literal["end_of_day", "damaged", "expired", "other"]
    note: str | None = None


class ReturnApproveIn(In):
    destination: Literal["warehouse", "damaged"] = "warehouse"


class ExceptionIn(In):
    note: str = Field(min_length=5)


# ---------- settings ----------
class SettingsIn(In):
    business: dict | None = None
    inventory: dict | None = None
    payments: dict | None = None


# ---------- admin messages to sellers / investors ----------
class MessageIn(In):
    audience: Literal["sellers", "investors", "all_sellers", "all_investors", "everyone"]
    recipient_ids: list[str] = Field(default_factory=list, description="sellers/investors হলে যাদের পাঠাবেন তাদের আইডি")
    title: str = Field(min_length=2, max_length=80)
    body: str = Field(min_length=2, max_length=1000)
    client_request_id: str = Field(min_length=8, max_length=64)


# ---------- support chat ----------
class SupportStartIn(In):
    topic: str
    text: str = Field(min_length=1, max_length=2000)
    client_request_id: str = Field(min_length=8, max_length=80, description="Idempotency key")


class SupportMessageIn(In):
    text: str = Field(min_length=1, max_length=2000)
    client_request_id: str = Field(min_length=8, max_length=80, description="Idempotency key")
