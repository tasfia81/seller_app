"""Request bodies for the investor app and the admin's investor management."""

from datetime import date
from typing import Literal

from pydantic import Field, field_validator

from .schemas import AddressIn, In, _mobile

PayoutMethod = Literal["bank", "bkash", "nagad"]


class PayoutAccountIn(In):
    method: PayoutMethod
    account_name: str = Field(min_length=2, max_length=80)
    account_number: str = Field(min_length=4, max_length=34)
    bank_name: str | None = None
    branch: str | None = None


class NomineeIn(In):
    name: str = Field(min_length=2)
    relation: str = Field(min_length=2)
    mobile: str

    @field_validator("mobile")
    @classmethod
    def check_mobile(cls, v: str) -> str:
        return _mobile(v)


class InvestorApplicationIn(In):
    full_name: str = Field(min_length=2, max_length=80)
    mobile: str
    date_of_birth: date
    email: str | None = None
    occupation: str = Field(min_length=2)
    funds_source: str = Field(min_length=2)
    address: AddressIn
    nid_number: str
    proposed_amount: float = Field(gt=0)
    payout: PayoutAccountIn
    nominee: NomineeIn
    password: str = Field(min_length=8)
    accepted_risk: bool
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


class InvestorTermsIn(In):
    share_percent: float = Field(gt=0, lt=100)
    payout_day: int = Field(ge=1, le=28)
    notice_days: int = Field(ge=0, le=180)


class InvestorApproveIn(In):
    terms: InvestorTermsIn | None = None


class InvestorInfoRequestIn(In):
    fields: list[Literal["nid_front", "nid_back", "selfie", "payout", "nominee", "address"]] = Field(min_length=1)
    message: str = Field(min_length=3)


class InvestorStatusIn(In):
    status: Literal["active", "suspended"]
    reason: str = Field(min_length=3)


class InvestmentIn(In):
    investor_id: str
    amount: float = Field(gt=0)
    method: Literal["bank", "cheque", "bkash", "nagad"]
    reference: str = Field(min_length=3, max_length=60)
    received_on: date
    seen_in_statement: bool
    client_request_id: str = Field(min_length=8, max_length=64)


class FundingPartIn(In):
    investor_id: str
    amount: float = Field(gt=0)


class FundedBatchIn(In):
    product_id: str
    variant: str | None = None
    quantity: float = Field(gt=0)
    unit_cost: float = Field(gt=0)
    batch_ref: str = Field(min_length=2, max_length=40)
    supplier: str | None = None
    parts: list[FundingPartIn] = Field(default_factory=list)
    company_amount: float = Field(ge=0, default=0)


class PreferenceIn(In):
    preference: Literal["cash", "reinvest"]


class WithdrawalRequestIn(In):
    amount: float = Field(gt=0)
    reason: str = Field(min_length=3, max_length=200)
    client_request_id: str = Field(min_length=8, max_length=64)


class WithdrawalDecisionIn(In):
    note: str | None = Field(default=None, max_length=200)


class WithdrawalRejectIn(In):
    reason: str = Field(min_length=3, max_length=200)


class InvestorPaymentIn(In):
    amount: float = Field(gt=0)
    reference: str = Field(min_length=3, max_length=60)
    client_request_id: str = Field(min_length=8, max_length=64)


class ProfitPaymentIn(In):
    investor_id: str
    reference: str | None = Field(default=None, max_length=60)
    client_request_id: str = Field(min_length=8, max_length=64)
