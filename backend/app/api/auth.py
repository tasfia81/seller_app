from fastapi import APIRouter

from ..core.deps import StoreDep, UserDep
from ..schemas import LoginIn, OtpRequestIn, OtpVerifyIn
from ..services import auth

router = APIRouter(prefix="/auth", tags=["লগইন (Auth)"])


@router.post("/login", summary="অ্যাডমিন বা সেলার লগইন")
def login(body: LoginIn, store: StoreDep):
    with store.transaction() as tx:
        return auth.login(tx, body.identifier, body.password)


@router.get("/me", summary="লগইন করা ব্যবহারকারী")
def me(user: UserDep, store: StoreDep):
    with store.transaction() as tx:
        return auth.public_user(tx, user)


@router.post("/password/otp", summary="পাসওয়ার্ড পুনরুদ্ধারের কোড (এখনো চালু নয়)")
def request_otp(_: OtpRequestIn):
    auth.request_password_otp()


@router.post("/password/reset", summary="কোড দিয়ে নতুন পাসওয়ার্ড (এখনো চালু নয়)")
def reset_password(_: OtpVerifyIn):
    auth.request_password_otp()
