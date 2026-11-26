from dataclasses import replace
from urllib.parse import parse_qs

import httpx
import pytest

from app.services import sms


@pytest.fixture
def configure_sms(monkeypatch):
    monkeypatch.setattr(sms, "settings", replace(sms.settings, bulksmsbd_api_key="test-key"))


def test_send_otp_uses_https_and_formats_bulk_sms_request(configure_sms):
    def accept(request):
        assert str(request.url) == sms.SMS_URL
        assert request.method == "POST"
        assert parse_qs(request.content.decode()) == {
            "api_key": ["test-key"],
            "senderid": [sms.settings.bulksmsbd_sender_id],
            "type": ["text"],
            "number": ["8801712345678"],
            "message": ["Your Street Sales OTP is 123456"],
        }
        return httpx.Response(200, json={"response_code": 202})

    with httpx.Client(transport=httpx.MockTransport(accept)) as client:
        sms.send_otp(client, "+8801712345678", "123456")


def test_send_otp_surfaces_provider_rejection(configure_sms):
    transport = httpx.MockTransport(
        lambda request: httpx.Response(200, json={"response_code": 1003})
    )
    with httpx.Client(transport=transport) as client, pytest.raises(sms.SmsDeliveryError):
        sms.send_otp(client, "01712345678", "123456")


def test_seller_can_reset_password_with_single_use_sms(client, rakib, monkeypatch):
    from app.services import password_recovery

    messages = {}
    monkeypatch.setattr(
        password_recovery,
        "settings",
        replace(password_recovery.settings, bulksmsbd_api_key="test-key"),
    )
    monkeypatch.setattr(
        password_recovery, "send_otp",
        lambda _, mobile, code: messages.update({mobile: code}),
    )

    mobile = "01712345678"
    auth = "/api/v1/auth"
    assert client.post(f"{auth}/password/otp", json={"mobile": mobile}).status_code == 200
    code = messages[mobile]
    wrong_code = "000000" if code != "000000" else "111111"
    payload = {"mobile": mobile, "new_password": "new-seller-123", "code": wrong_code}
    assert client.post(f"{auth}/password/reset", json=payload).status_code == 400
    payload["code"] = code
    assert client.post(f"{auth}/password/reset", json=payload).status_code == 200
    assert client.post(f"{auth}/password/reset", json=payload).status_code == 400
    assert client.get(f"{auth}/me", headers=rakib).status_code == 401
    assert client.post(
        f"{auth}/login", json={"identifier": mobile, "password": payload["new_password"]}
    ).status_code == 200
