"""Street Sales API — FastAPI backend for the Seller app and the Admin panel.

Run:  uvicorn app.main:app --reload       Docs: http://127.0.0.1:8000/docs
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api import admin, admin_investors, auth, investor, seller, support
from .core.config import settings
from .core.errors import register_error_handlers
from .storage import get_store
from .storage.seed import bootstrap, seed


@asynccontextmanager
async def lifespan(_: FastAPI):
    store = get_store()
    if store.is_empty():
        if settings.seed_demo_data:
            seed(store)
        else:
            bootstrap(store, settings.admin_name, settings.admin_mobile, settings.admin_password)
            if settings.admin_password == "admin1234":
                logging.getLogger("street_sales").warning("Default admin password in use — set ADMIN_PASSWORD before going live.")
    yield


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="স্ট্রিট সেলস — সেলার অ্যাপ ও অ্যাডমিন প্যানেলের API। সব টাকা BDT, সময় Asia/Dhaka।",
    lifespan=lifespan,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
register_error_handlers(app)

API = "/api/v1"
app.include_router(auth.router, prefix=API)
app.include_router(seller.router, prefix=API)
app.include_router(admin.router, prefix=API)
app.include_router(admin_investors.router, prefix=API)
app.include_router(investor.router, prefix=API)
app.include_router(support.router, prefix=API)
app.include_router(support.admin_router, prefix=API)


@app.get("/health", tags=["সিস্টেম"])
def health():
    return {"status": "ok", "storage": settings.storage}
