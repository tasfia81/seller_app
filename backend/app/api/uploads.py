"""Private file storage for photos (NID, seller photo, damage evidence).

Files live outside any public folder and are only served through authenticated,
audited endpoints. Later this moves to Firebase Storage with signed, expiring URLs.
"""

import secrets
from pathlib import Path

from fastapi import UploadFile

from ..core.config import settings
from ..core.errors import AppError, NotFound

ALLOWED = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}


async def save_image(file: UploadFile, folder: str, name: str) -> tuple[str, str]:
    if file.content_type not in ALLOWED:
        raise AppError("শুধু JPG, PNG বা WEBP ছবি দেওয়া যাবে।", code="invalid_file_type")
    data = await file.read()
    if len(data) > settings.max_upload_bytes:
        raise AppError("ছবি ৫MB-এর বেশি হতে পারবে না।", code="file_too_large")
    if len(data) < 10 * 1024:
        raise AppError("ছবিটি খুব ছোট বা অস্পষ্ট। আবার পরিষ্কার ছবি দিন।", code="file_too_small")
    rel = Path(folder) / f"{name}-{secrets.token_hex(4)}.{ALLOWED[file.content_type]}"
    target = settings.upload_dir / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    return rel.as_posix(), file.content_type


def resolve(ref: str) -> Path:
    path = (settings.upload_dir / ref).resolve()
    if settings.upload_dir.resolve() not in path.parents:
        raise AppError("ফাইলের ঠিকানা সঠিক নয়।", code="invalid_file_ref")
    if not path.is_file():
        raise NotFound("ছবির ফাইল পাওয়া যায়নি।", code="file_missing")
    return path
