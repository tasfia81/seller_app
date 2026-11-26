"""End-to-end API tests over the seeded demo data."""

from dataclasses import replace
from datetime import date, timedelta

import pytest

API = "/api/v1"


def _product(client, admin, sku):
    return next(p for p in client.get(f"{API}/admin/products", headers=admin).json() if p["sku"] == sku)


def _seller_id(client, admin, name):
    return next(s["id"] for s in client.get(f"{API}/admin/sellers", headers=admin).json() if s["name"] == name)


# ---------- auth ----------
def test_health_and_login(client, admin):
    assert client.get("/health").json()["status"] == "ok"
    me = client.get(f"{API}/auth/me", headers=admin).json()
    assert me["role"] == "admin"


def test_wrong_password_and_role_checks(client, rakib):
    r = client.post(f"{API}/auth/login", json={"identifier": "01711000000", "password": "nope"})
    assert r.status_code == 401 and r.json()["error"]["code"] == "invalid_credentials"
    assert client.get(f"{API}/admin/dashboard", headers=rakib).status_code == 403
    assert client.get(f"{API}/admin/dashboard").status_code == 401


def test_otp_is_not_simulated(client):
    r = client.post(f"{API}/auth/password/otp", json={"mobile": "01712345678"})
    assert r.status_code == 501


# ---------- onboarding ----------
@pytest.mark.parametrize("verify_mobile", [False, True])
def test_application_flow_requires_documents_and_hides_nid(client, admin, monkeypatch, verify_mobile):
    body = {
        "full_name": "পরীক্ষা সেলার", "mobile": "01555000111", "date_of_birth": "2001-01-01",
        "present_address": {"division": "ঢাকা", "district": "ঢাকা", "upazila": "মিরপুর", "detail": "বাড়ি ১"},
        "permanent_address": {"division": "ঢাকা", "district": "ঢাকা", "upazila": "মিরপুর", "detail": "বাড়ি ১"},
        "nid_number": "1112223334", "emergency": {"name": "মা", "relation": "মা", "mobile": "01555000222"},
        "password": "pass12345", "accepted_privacy": True, "accepted_terms": True,
    }
    if verify_mobile:
        from app.api import seller
        from app.services import password_recovery

        configured = replace(seller.settings, bulksmsbd_api_key="test-key")
        monkeypatch.setattr(seller, "settings", configured)
        monkeypatch.setattr(password_recovery, "settings", configured)
        sent = {}
        monkeypatch.setattr(
            password_recovery, "send_otp",
            lambda _, mobile, code: sent.update({mobile: code}),
        )
        assert client.post(f"{API}/seller/application/otp", json={"mobile": body["mobile"]}).status_code == 200
        code = sent[body["mobile"]]
        body["otp_code"] = "000000" if code != "000000" else "111111"
        assert client.post(f"{API}/seller/applications", json=body).json()["error"]["code"] == "invalid_otp"
        body["otp_code"] = code
    r = client.post(f"{API}/seller/applications", json=body)
    assert r.status_code == 201, r.text
    applicant = {"Authorization": f"Bearer {r.json()['access_token']}"}
    app_id = r.json()["application_id"]
    # applicant cannot use seller features yet
    assert client.get(f"{API}/seller/dashboard", headers=applicant).json()["error"]["code"] == "application_pending"
    view = client.get(f"{API}/admin/applications/{app_id}", headers=admin).json()
    assert view["nid_masked"].endswith("3334") and "1112223334" not in str(view)
    # approval needs all three documents
    r = client.post(f"{API}/admin/applications/{app_id}/approve", headers=admin)
    assert r.json()["error"]["code"] == "documents_missing"
    png = b"\x89PNG\r\n\x1a\n" + b"0" * 20_000
    for kind in ("nid_front", "nid_back", "photo"):
        r = client.post(f"{API}/seller/application/documents/{kind}", headers=applicant, files={"file": (f"{kind}.png", png, "image/png")})
        assert r.status_code == 200, r.text
    assert client.post(f"{API}/admin/applications/{app_id}/approve", headers=admin).status_code == 200
    # NID reveal is logged
    client.post(f"{API}/admin/applications/{app_id}/reveal-nid", headers=admin)
    assert any(a["action"] == "application.nid_viewed" for a in client.get(f"{API}/admin/audit-log", headers=admin).json())


def test_underage_application_rejected(client):
    young = (date.today() - timedelta(days=365 * 15)).isoformat()
    body = {
        "full_name": "কম বয়সী", "mobile": "01555000333", "date_of_birth": young,
        "present_address": {"division": "ঢাকা", "district": "ঢাকা", "upazila": "মিরপুর", "detail": "বাড়ি ১"},
        "permanent_address": {"division": "ঢাকা", "district": "ঢাকা", "upazila": "মিরপুর", "detail": "বাড়ি ১"},
        "nid_number": "1112223335", "emergency": {"name": "মা", "relation": "মা", "mobile": "01555000222"},
        "password": "pass12345", "accepted_privacy": True, "accepted_terms": True,
    }
    assert client.post(f"{API}/seller/applications", json=body).json()["error"]["code"] == "underage"


# ---------- products & sales ----------
def test_seller_never_sees_cost(client, rakib):
    products = client.get(f"{API}/seller/products", headers=rakib).json()
    assert products and all("unit_cost" not in p for p in products)


def test_sale_validation_idempotency_and_stock(client, admin, rakib):
    jersey = _product(client, admin, "JRS-BD")
    before = next(p for p in client.get(f"{API}/seller/products", headers=rakib).json() if p["id"] == jersey["id"])["variant_stock"]["L"]
    sale = {"product_id": jersey["id"], "variant": "L", "quantity": 1, "unit_price": 450, "payment": "cash", "client_request_id": "test-sale-0001"}
    r1 = client.post(f"{API}/seller/sales", json=sale, headers=rakib)
    r2 = client.post(f"{API}/seller/sales", json=sale, headers=rakib)
    assert r1.status_code == 201 and r2.json()["duplicate"] is True and r1.json()["id"] == r2.json()["id"]
    after = next(p for p in client.get(f"{API}/seller/products", headers=rakib).json() if p["id"] == jersey["id"])["variant_stock"]["L"]
    assert after == before - 1
    # fixed price cannot change
    bad = {**sale, "unit_price": 400, "client_request_id": "test-sale-0002"}
    assert client.post(f"{API}/seller/sales", json=bad, headers=rakib).json()["error"]["code"] == "price_fixed"
    # not enough stock
    big = {**sale, "quantity": 999, "client_request_id": "test-sale-0003"}
    r = client.post(f"{API}/seller/sales", json=big, headers=rakib)
    assert r.json()["error"]["code"] == "insufficient_stock"


def test_flexible_price_limits_and_commission(client, admin, rakib):
    polo = _product(client, admin, "TS-POLO")
    base = {"product_id": polo["id"], "variant": "XL", "quantity": 1, "payment": "cash"}
    assert client.post(f"{API}/seller/sales", json={**base, "unit_price": 500, "client_request_id": "flex-0001"}, headers=rakib).json()["error"]["code"] == "price_out_of_range"
    r = client.post(f"{API}/seller/sales", json={**base, "unit_price": 400, "client_request_id": "flex-0002"}, headers=rakib)
    assert r.status_code == 201
    detail = client.get(f"{API}/admin/sales/{r.json()['id']}", headers=admin).json()
    assert detail["gross_profit"] == 140 and detail["commission"] == 56  # 40% of (400-260)


# ---------- assignments & returns ----------
def test_assignment_reserved_until_accepted(client, admin, nusrat):
    pending = client.get(f"{API}/seller/assignments", headers=nusrat).json()
    asg = next(a for a in pending if a["status"] == "pending_handover")
    assert not client.get(f"{API}/seller/products", headers=nusrat).json()  # nothing in hand yet
    assert client.post(f"{API}/seller/assignments/{asg['id']}/accept", headers=nusrat).status_code == 200
    assert client.get(f"{API}/seller/products", headers=nusrat).json()


def test_assignment_cannot_exceed_warehouse(client, admin):
    cap = _product(client, admin, "ACC-CAP")
    sid = _seller_id(client, admin, "রাকিব হাসান")
    r = client.post(f"{API}/admin/assignments", headers=admin, json={"seller_id": sid, "items": [{"product_id": cap["id"], "quantity": 999}]})
    assert r.json()["error"]["code"] == "insufficient_warehouse_stock"


def test_return_moves_stock_only_when_received(client, admin, rakib):
    basic = _product(client, admin, "TS-BSC-W")
    r = client.post(f"{API}/seller/returns", headers=rakib, json={"product_id": basic["id"], "variant": "M", "quantity": 2, "reason": "end_of_day"})
    ret_id = r.json()["id"]
    stock = lambda: client.get(f"{API}/seller/inventory", headers=rakib).json()["available"]  # noqa: E731
    before = stock()
    client.post(f"{API}/admin/returns/{ret_id}/approve", headers=admin, json={"destination": "warehouse"})
    assert stock() == before
    client.post(f"{API}/admin/returns/{ret_id}/receive", headers=admin)
    assert stock() == before - 2


# ---------- cash, payouts, settlements ----------
def test_cash_handover_and_shortfall(client, admin, rakib):
    cash = client.get(f"{API}/seller/cash", headers=rakib).json()["summary"]
    assert cash["collected"] == 1130 and cash["pending_verification"] == 1000  # cash sales 380 + 750
    too_much = client.post(f"{API}/seller/cash/handovers", headers=rakib, json={"amount": 5000, "method": "in_person"})
    assert too_much.json()["error"]["code"] == "amount_exceeds_due"
    pending = client.get(f"{API}/admin/cash/handovers?status=pending", headers=admin).json()[0]
    r = client.post(f"{API}/admin/cash/handovers/{pending['id']}/verify", headers=admin, json={"received_amount": 900})
    assert r.json()["shortfall"] == 100
    cash = client.get(f"{API}/seller/cash", headers=rakib).json()["summary"]
    assert cash["verified"] == 900 and cash["due"] == 230


def test_day_close_blocked_then_exception_then_payout(client, admin, rakib):
    sid = _seller_id(client, admin, "রাকিব হাসান")
    today = date.today().isoformat()
    r = client.post(f"{API}/seller/day-closing/submit", headers=rakib)
    assert r.json()["error"]["code"] == "requirements_unmet"
    assert client.post(f"{API}/admin/settlements/{sid}/{today}/close", headers=admin).json()["error"]["code"] == "unresolved_discrepancy"
    client.post(f"{API}/admin/settlements/{sid}/{today}/exception", headers=admin, json={"note": "বাকি স্টক কাল ফেরত দেবেন"})
    closed = client.post(f"{API}/admin/settlements/{sid}/{today}/close", headers=admin)
    assert closed.status_code == 200 and closed.json()["status"] == "closed"
    # earnings approved → payable; payout limited and idempotent
    payable = client.get(f"{API}/admin/sellers/{sid}/earnings", headers=admin).json()["summary"]["outstanding"]
    assert payable > 0
    body = {"seller_id": sid, "amount": payable + 1, "method": "in_person", "client_request_id": "payout-0001"}
    assert client.post(f"{API}/admin/payouts", headers=admin, json=body).json()["error"]["code"] == "exceeds_payable"
    body["amount"] = payable
    p1 = client.post(f"{API}/admin/payouts", headers=admin, json=body).json()
    p2 = client.post(f"{API}/admin/payouts", headers=admin, json=body).json()
    assert p1["id"] == p2["id"]
    # no sales after the day is closed
    jersey = _product(client, admin, "JRS-BD")
    r = client.post(f"{API}/seller/sales", headers=rakib, json={"product_id": jersey["id"], "variant": "L", "quantity": 1, "unit_price": 450, "payment": "cash", "client_request_id": "after-close-1"})
    assert r.json()["error"]["code"] == "day_closed"


def test_correction_keeps_original(client, admin, rakib):
    sale = client.get(f"{API}/seller/sales", headers=rakib).json()["items"][0]
    r = client.post(f"{API}/seller/sales/{sale['id']}/corrections", headers=rakib, json={"payment": "nagad", "reason": "ভুল করে ক্যাশ চাপা হয়েছিল"})
    cid = r.json()["id"]
    client.post(f"{API}/admin/corrections/{cid}/approve", headers=admin, json={"note": "মিলিয়ে দেখা হয়েছে"})
    detail = client.get(f"{API}/admin/sales/{sale['id']}", headers=admin).json()
    assert detail["payment"] == "nagad" and detail["original"]["payment"] == sale["payment"] and detail["corrected"]


def test_compensation_change_cannot_be_backdated(client, admin):
    sid = _seller_id(client, admin, "রাকিব হাসান")
    past = {"model": "profit", "profit_percent": 50, "effective_from": (date.today() - timedelta(days=1)).isoformat(), "reason": "পরীক্ষা"}
    assert client.put(f"{API}/admin/sellers/{sid}/compensation", headers=admin, json=past).json()["error"]["code"] == "effective_date_in_past"
    future = {**past, "effective_from": (date.today() + timedelta(days=1)).isoformat()}
    r = client.put(f"{API}/admin/sellers/{sid}/compensation", headers=admin, json=future)
    assert r.status_code == 200 and r.json()["current"]["profit_percent"] == 40  # still the old rule today


def test_dashboard_and_reports(client, admin):
    d = client.get(f"{API}/admin/dashboard", headers=admin).json()
    assert d["metrics"]["total_sales"] == 2030 and d["pending_actions"]["applications"] == 1
    fin = client.get(f"{API}/admin/reports/financial?period=today", headers=admin).json()
    assert fin["net_sales"] == 2030 and fin["gross_profit"] == 2030 - (700 + 260 + 480)


def test_suspended_seller_is_logged_out(client, admin, rakib):
    sid = _seller_id(client, admin, "রাকিব হাসান")
    client.post(f"{API}/admin/sellers/{sid}/status/suspended", headers=admin)
    assert client.get(f"{API}/seller/dashboard", headers=rakib).status_code == 401
