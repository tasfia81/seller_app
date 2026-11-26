"""Send Street Sales OTP messages through BulkSMSBD."""

import re

import httpx

from ..core.config import settings
from ..core.errors import AppError
from ..core.utils import is_bd_mobile, normalize_mobile

SMS_URL = "https://bulksmsbd.net/api/smsapi"


class SmsDeliveryError(AppError):
    status_code = 502
    code = "sms_delivery_failed"


class SmsNotConfigured(AppError):
    status_code = 503
    code = "sms_not_configured"


def send_otp(client: httpx.Client, mobile: str, code: str) -> None:
    if not is_bd_mobile(mobile):
        raise ValueError("Expected a Bangladeshi mobile number")
    if not re.fullmatch(r"[0-9]{6}", code):
        raise ValueError("Expected a six-digit OTP")
    if not settings.bulksmsbd_api_key or not settings.bulksmsbd_sender_id:
        raise SmsNotConfigured("SMS সেবা এখনো কনফিগার করা হয়নি।")

    error_message = "SMS পাঠানো যায়নি। পরে আবার চেষ্টা করুন।"
    try:
        response = client.post(
            SMS_URL,
            data={
                "api_key": settings.bulksmsbd_api_key,
                "senderid": settings.bulksmsbd_sender_id,
                "type": "text",
                "number": "88" + normalize_mobile(mobile),
                "message": f"Your Street Sales OTP is {code}",
            },
            timeout=10,
            follow_redirects=False,
        )
        response.raise_for_status()
        result = response.json()
    except (httpx.HTTPError, ValueError):
        raise SmsDeliveryError(error_message) from None

    if not isinstance(result, dict) or str(result.get("response_code")) != "202":
        raise SmsDeliveryError(error_message)
