from fastapi import APIRouter

from ..core.deps import StoreDep, UserDep
from ..schemas import ChangePasswordIn, LoginIn, OtpRequestIn, OtpVerifyIn
from ..services import auth, password_recovery

router = APIRouter(prefix="/auth", tags=["লগইন (Auth)"])


@router.post("/login", summary="অ্যাডমিন, সেলার বা বিনিয়োগকারী লগইন")
def login(body: LoginIn, store: StoreDep):
    with store.transaction() as tx:
        return auth.login(tx, body.identifier, body.password)


@router.get("/me", summary="লগইন করা ব্যবহারকারী")
def me(user: UserDep, store: StoreDep):
    with store.transaction() as tx:
        return auth.public_user(tx, user)


@router.post("/password/otp", summary="পাসওয়ার্ড পুনরুদ্ধারের কোড (সেলার)")
def request_otp(body: OtpRequestIn, store: StoreDep):
    password_recovery.request(store, body.mobile)


@router.post("/password/reset", summary="কোড দিয়ে নতুন পাসওয়ার্ড (সেলার)")
def reset_password(body: OtpVerifyIn, store: StoreDep):
    password_recovery.reset(store, body.mobile, body.code, body.new_password)


@router.put("/password")
def change_password(body: ChangePasswordIn, user: UserDep, store: StoreDep):
    with store.transaction() as tx:
        auth.change_password(tx, user, body.current_password, body.new_password)


@router.post("/sessions/revoke")
def revoke_sessions(user: UserDep, store: StoreDep):
    with store.transaction() as tx:
        auth.revoke_sessions(tx, user)


@router.post("/admin/password/otp")
def request_admin_otp(body: OtpRequestIn, store: StoreDep):
    password_recovery.request(store, body.mobile, role="admin")


@router.post("/admin/password/reset")
def reset_admin_password(body: OtpVerifyIn, store: StoreDep):
    password_recovery.reset(store, body.mobile, body.code, body.new_password, role="admin")
