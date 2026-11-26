"""App settings, read from environment variables (with safe local defaults)."""

import os
from dataclasses import dataclass, field
from datetime import timedelta, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]

# Bangladesh has no daylight saving time, so a fixed +06:00 offset is exact.
DHAKA = timezone(timedelta(hours=6), name="Asia/Dhaka")


@dataclass(frozen=True)
class Settings:
    app_name: str = "Street Sales API"
    # "local" = JSON file on disk (now). "firestore" = Firebase (later).
    storage: str = os.getenv("STORAGE", "local")
    data_file: Path = Path(os.getenv("DATA_FILE", str(BASE_DIR / "data" / "db.json")))
    upload_dir: Path = Path(os.getenv("UPLOAD_DIR", str(BASE_DIR / "data" / "uploads")))
    # Change in production! Used to sign login tokens.
    secret_key: str = os.getenv("SECRET_KEY", "dev-only-change-me")
    token_ttl_hours: int = int(os.getenv("TOKEN_TTL_HOURS", "72"))
    # Demo products/sellers/sales are only for tests and demos. A real database starts empty.
    seed_demo_data: bool = os.getenv("SEED_DEMO_DATA", "false").lower() == "true"
    # First admin account, created once when the database is empty. Change the password in production.
    admin_name: str = os.getenv("ADMIN_NAME", "অ্যাডমিন")
    admin_mobile: str = os.getenv("ADMIN_MOBILE", "01711000000")
    admin_password: str = os.getenv("ADMIN_PASSWORD", "admin1234")
    cors_origins: list[str] = field(
        default_factory=lambda: os.getenv(
            "CORS_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000"
        ).split(",")
    )
    bulksmsbd_api_key: str = field(
        default_factory=lambda: os.getenv("BULKSMSBD_API_KEY", ""), repr=False
    )
    bulksmsbd_sender_id: str = os.getenv("BULKSMSBD_SENDER_ID", "8809617643542")
    max_upload_bytes: int = 5 * 1024 * 1024


settings = Settings()
