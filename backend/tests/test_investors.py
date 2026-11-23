"""Investor flow + admin messages, over the seeded demo data.

Seed: investor আশরাফুল (01913000000) gave ৳50,000 and funded the jersey L batch
(60 × ৳350 = ৳21,000). রাকিব sold 2 jersey L at ৳450 → net (900 − 700 − 80) = ৳120,
investor share 50% = ৳60.
"""

from datetime import date, datetime, timedelta, timezone

import pytest

from app.storage import get_store

API = "/api/v1"
PNG = b"\x89PNG\r\n\x1a\n" + b"0" * 20_000


def _login(client, mobile, password):
    r = client.post(f"{API}/auth/login", json={"identifier": mobile, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture()
def investor(client):
    return _login(client, "01913000000", "invest1234")


def _investor_id(client, admin):
    return next(i["id"] for i in client.get(f"{API}/admin/investors", headers=admin).json() if i["name"] == "আশরাফুল করিম")


def _product(client, admin, sku):
    return next(p for p in client.get(f"{API}/admin/products", headers=admin).json() if p["sku"] == sku)


def test_dashboard_numbers_follow_the_funded_batch(client, investor):
    d = client.get(f"{API}/investor/dashboard", headers=investor).json()
    assert d["active_capital"] == 50000
    assert d["in_stock"] == 58 * 350
    assert d["uninvested"] == 50000 - 58 * 350
    assert d["profit_this_month"] == 60
    assert d["stock"] == {"bought": 60, "sold": 2, "remaining": 58}
    assert d["today"]["pieces"] == 2 and d["today"]["amount"] == 900


def test_portfolio_product_and_sellers_hide_private_data(client, admin, investor):
    p = client.get(f"{API}/investor/portfolio", headers=investor).json()
    lot = p["holdings"][0]
    assert lot["invested"] == 21000 and lot["sold"] == 2 and lot["net"] == 120 and lot["share"] == 60
    detail = client.get(f"{API}/investor/products/{lot['product_id']}", headers=investor).json()
    assert detail["totals"]["revenue"] == 900 and detail["sellers"][0]["name"] == "রাকিব হাসান"
    sellers = client.get(f"{API}/investor/sellers", headers=investor).json()
    assert sellers and "01712345678" not in str(sellers) and "mobile" not in sellers[0]
    # an investor cannot open a product they did not fund
    polo = _product(client, admin, "TS-POLO")
    assert client.get(f"{API}/investor/products/{polo['id']}", headers=investor).json()["error"]["code"] == "not_your_product"


def test_role_walls(client, admin, rakib, investor):
    assert client.get(f"{API}/investor/dashboard", headers=rakib).status_code == 403
    assert client.get(f"{API}/admin/investors", headers=investor).status_code == 403
    assert client.get(f"{API}/seller/dashboard", headers=investor).status_code == 403


def test_application_kyc_flow(client, admin):
    body = {
        "full_name": "নাজমুল হক", "mobile": "01718000421", "date_of_birth": "1988-01-08", "occupation": "চাকরিজীবী", "funds_source": "বেতন / সঞ্চয়",
        "address": {"division": "ঢাকা", "district": "ঢাকা", "upazila": "উত্তরা", "detail": "বাড়ি ১"}, "nid_number": "1234509876",
        "proposed_amount": 200000, "payout": {"method": "bank", "account_name": "MD NAZMUL HAQUE", "account_number": "1234567310", "bank_name": "[ব্যাংক]"},
        "nominee": {"name": "শামীমা হক", "relation": "স্ত্রী", "mobile": "01819000332"}, "password": "pass12345", "accepted_risk": True, "accepted_terms": True,
    }
    r = client.post(f"{API}/investor/applications", json=body)
    assert r.status_code == 201, r.text
    applicant = {"Authorization": f"Bearer {r.json()['access_token']}"}
    app_id = r.json()["application_id"]
    assert client.get(f"{API}/investor/dashboard", headers=applicant).json()["error"]["code"] == "application_pending"
    view = client.get(f"{API}/admin/investor-applications/{app_id}", headers=admin).json()
    assert view["nid_masked"].endswith("9876") and "1234509876" not in str(view) and view["payout"]["account_masked"] == "••••7310"
    assert client.post(f"{API}/admin/investor-applications/{app_id}/approve", headers=admin, json={}).json()["error"]["code"] == "documents_missing"
    for kind in ("nid_front", "nid_back", "selfie"):
        assert client.post(f"{API}/investor/application/documents/{kind}", headers=applicant, files={"file": (f"{kind}.png", PNG, "image/png")}).status_code == 200
    r = client.post(f"{API}/admin/investor-applications/{app_id}/approve", headers=admin,
                    json={"terms": {"share_percent": 45, "payout_day": 5, "notice_days": 30}})
    assert r.status_code == 200 and r.json()["code"].startswith("INV-")
    d = client.get(f"{API}/investor/dashboard", headers=applicant).json()
    assert d["terms"]["share_percent"] == 45 and d["active_capital"] == 0


def test_record_investment_is_safe_against_doubles(client, admin, investor):
    iid = _investor_id(client, admin)
    body = {"investor_id": iid, "amount": 100000, "method": "bank", "reference": "FT-2211-01", "received_on": "2026-11-22",
            "seen_in_statement": True, "client_request_id": "inv-test-0001"}
    r1 = client.post(f"{API}/admin/investments", headers=admin, json=body).json()
    r2 = client.post(f"{API}/admin/investments", headers=admin, json=body).json()
    assert r1["id"] == r2["id"] and r2["duplicate"] is True and r1["receipt"].startswith("I-")
    again = client.post(f"{API}/admin/investments", headers=admin, json={**body, "client_request_id": "inv-test-0002"})
    assert again.json()["error"]["code"] == "duplicate_reference"
    unseen = client.post(f"{API}/admin/investments", headers=admin, json={**body, "reference": "FT-X", "seen_in_statement": False, "client_request_id": "inv-test-0003"})
    assert unseen.json()["error"]["code"] == "statement_unconfirmed"
    assert client.get(f"{API}/investor/dashboard", headers=investor).json()["active_capital"] == 150000


def test_fund_batch_checks_split_and_free_money(client, admin, investor):
    iid = _investor_id(client, admin)
    polo = _product(client, admin, "TS-POLO")
    base = {"product_id": polo["id"], "variant": "M", "quantity": 100, "unit_cost": 260, "batch_ref": "ব্যাচ-৯১"}  # ৳26,000
    bad = client.post(f"{API}/admin/fundings", headers=admin, json={**base, "parts": [{"investor_id": iid, "amount": 20000}], "company_amount": 1000})
    assert bad.json()["error"]["code"] == "split_mismatch"
    big = {**base, "quantity": 200}  # ৳52,000 but only ৳29,700 of the investor's money is free
    too_much = client.post(f"{API}/admin/fundings", headers=admin, json={**big, "parts": [{"investor_id": iid, "amount": 52000}]})
    assert too_much.json()["error"]["code"] == "exceeds_uninvested"
    ok = client.post(f"{API}/admin/fundings", headers=admin, json={**base, "parts": [{"investor_id": iid, "amount": 20000}], "company_amount": 6000})
    assert ok.status_code == 201, ok.text
    assert client.get(f"{API}/investor/dashboard", headers=investor).json()["uninvested"] == 29700 - 20000


def test_withdrawal_flow(client, admin, investor):
    iid = _investor_id(client, admin)
    r = client.post(f"{API}/investor/withdrawals", headers=investor, json={"amount": 40000, "reason": "পারিবারিক প্রয়োজন", "client_request_id": "wd-test-0001"})
    assert r.status_code == 201 and r.json()["status"] == "pending"
    wd = r.json()["id"]
    again = client.post(f"{API}/investor/withdrawals", headers=investor, json={"amount": 1000, "reason": "আরও", "client_request_id": "wd-test-0002"})
    assert again.json()["error"]["code"] == "withdrawal_open"
    # money of an investor asking to withdraw cannot go into new stock
    cap = _product(client, admin, "ACC-CAP")
    blocked = client.post(f"{API}/admin/fundings", headers=admin, json={"product_id": cap["id"], "quantity": 10, "unit_cost": 110, "batch_ref": "B-1",
                                                                       "parts": [{"investor_id": iid, "amount": 1100}]})
    assert blocked.json()["error"]["code"] == "investor_withdrawing"
    assert client.post(f"{API}/admin/investor-withdrawals/{wd}/approve", headers=admin, json={}).json()["status"] == "approved"
    over = client.post(f"{API}/admin/investor-withdrawals/{wd}/pay", headers=admin, json={"amount": 35000, "reference": "FT-W1", "client_request_id": "wdp-0001"})
    assert over.json()["error"]["code"] == "insufficient_cash"  # only ৳29,700 is not in stock
    p1 = client.post(f"{API}/admin/investor-withdrawals/{wd}/pay", headers=admin, json={"amount": 29700, "reference": "FT-W1", "client_request_id": "wdp-0002"}).json()
    p2 = client.post(f"{API}/admin/investor-withdrawals/{wd}/pay", headers=admin, json={"amount": 29700, "reference": "FT-W1", "client_request_id": "wdp-0002"}).json()
    assert p1["paid"] == 29700 and p2["duplicate"] is True and p1["status"] == "approved" and p1["remaining"] == 10300
    d = client.get(f"{API}/investor/dashboard", headers=investor).json()
    assert d["active_capital"] == 20300 and d["uninvested"] == 0


def _move_sales_to_last_month():
    first = date.today().replace(day=1)
    last_month_day = datetime.combine(first - timedelta(days=3), datetime.min.time(), tzinfo=timezone(timedelta(hours=6))).replace(hour=12)
    store = get_store()
    with store.transaction() as tx:
        for s in tx.list("sales"):
            s["created_at"] = last_month_day.isoformat()
            tx.put("sales", s)
    return f"{last_month_day.year:04d}-{last_month_day.month:02d}"


def test_profit_run_approve_and_pay(client, admin, investor):
    this_month = f"{date.today().year:04d}-{date.today().month:02d}"
    assert client.post(f"{API}/admin/investor-profit/{this_month}/approve", headers=admin).json()["error"]["code"] == "month_open"
    month = _move_sales_to_last_month()
    draft = client.get(f"{API}/admin/investor-profit/{month}", headers=admin).json()
    assert draft["status"] == "draft" and draft["can_approve"] and draft["totals"]["investors_share"] == 60
    run = client.post(f"{API}/admin/investor-profit/{month}/approve", headers=admin).json()
    assert run["status"] == "approved"
    assert client.post(f"{API}/admin/investor-profit/{month}/approve", headers=admin).json()["error"]["code"] == "already_approved"
    iid = _investor_id(client, admin)
    no_ref = client.post(f"{API}/admin/investor-profit/{month}/pay", headers=admin, json={"investor_id": iid, "client_request_id": "pay-prof-0001"})
    assert no_ref.json()["error"]["code"] == "reference_required"
    paid = client.post(f"{API}/admin/investor-profit/{month}/pay", headers=admin, json={"investor_id": iid, "reference": "BK-77", "client_request_id": "pay-prof-0002"}).json()
    assert paid["status"] == "paid"
    twice = client.post(f"{API}/admin/investor-profit/{month}/pay", headers=admin, json={"investor_id": iid, "reference": "BK-77", "client_request_id": "pay-prof-0003"}).json()
    assert twice["duplicate"] is True
    ledger = client.get(f"{API}/investor/ledger", headers=investor).json()
    assert sum(1 for t in ledger if t["kind"] == "profit") == 1
    report = next(m for m in client.get(f"{API}/investor/reports", headers=investor).json() if m["month"] == month)
    assert report["status"] == "paid" and report["share"] == 60


def test_admin_messages_reach_sellers_and_investors(client, admin, rakib, nusrat, investor):
    body = {"audience": "all_sellers", "title": "কাল হাট বন্ধ", "body": "কাল বিক্রি বন্ধ থাকবে।", "client_request_id": "msg-test-0001"}
    r1 = client.post(f"{API}/admin/messages", headers=admin, json=body).json()
    r2 = client.post(f"{API}/admin/messages", headers=admin, json=body).json()
    assert r1["recipient_count"] == 2 and r2["duplicate"] is True
    for h in (rakib, nusrat):
        titles = [n["title"] for n in client.get(f"{API}/seller/notifications", headers=h).json()]
        assert titles.count("কাল হাট বন্ধ") == 1
    iid = _investor_id(client, admin)
    one = client.post(f"{API}/admin/messages", headers=admin, json={"audience": "investors", "recipient_ids": [iid], "title": "রিপোর্ট প্রস্তুত",
                                                                   "body": "অক্টোবরের রিপোর্ট দেখুন।", "client_request_id": "msg-test-0002"})
    assert one.json()["recipient_count"] == 1
    assert any(n["title"] == "রিপোর্ট প্রস্তুত" for n in client.get(f"{API}/investor/notifications", headers=investor).json())
    bad = client.post(f"{API}/admin/messages", headers=admin, json={"audience": "sellers", "recipient_ids": ["nope"], "title": "x১", "body": "y১",
                                                                   "client_request_id": "msg-test-0003"})
    assert bad.json()["error"]["code"] == "unknown_recipients"
    assert client.get(f"{API}/admin/messages", headers=admin).json()[0]["title"] == "রিপোর্ট প্রস্তুত"


def test_mobile_check_and_rejected_applicant_can_read_reason(client, admin):
    assert client.post(f"{API}/investor/mobile-check", json={"mobile": "01913000000"}).json() == {"available": False}
    assert client.post(f"{API}/investor/mobile-check", json={"mobile": "01718000777"}).json() == {"available": True}
    assert client.post(f"{API}/investor/mobile-check", json={"mobile": "123"}).status_code == 422
    body = {
        "full_name": "রহিম উদ্দিন", "mobile": "01718000777", "date_of_birth": "1990-02-02", "occupation": "ব্যবসায়ী", "funds_source": "ব্যবসার আয়",
        "address": {"division": "ঢাকা", "district": "ঢাকা", "upazila": "মিরপুর", "detail": "বাড়ি ২"}, "nid_number": "1234509877",
        "proposed_amount": 50000, "payout": {"method": "bkash", "account_name": "রহিম উদ্দিন", "account_number": "01718000777"},
        "nominee": {"name": "করিম", "relation": "ভাই", "mobile": "01819000333"}, "password": "pass12345", "accepted_risk": True, "accepted_terms": True,
    }
    app_id = client.post(f"{API}/investor/applications", json=body).json()["application_id"]
    r = client.post(f"{API}/admin/investor-applications/{app_id}/reject", headers=admin, json={"reason": "তথ্য মেলেনি"})
    assert r.status_code == 200, r.text
    login = client.post(f"{API}/auth/login", json={"identifier": "01718000777", "password": "pass12345"})
    assert login.status_code == 200 and login.json()["user"]["status"] == "rejected"
    h = {"Authorization": f"Bearer {login.json()['access_token']}"}
    mine = client.get(f"{API}/investor/application", headers=h).json()
    assert mine["status"] == "rejected" and mine["rejection_reason"] == "তথ্য মেলেনি"
    assert client.get(f"{API}/investor/dashboard", headers=h).json()["error"]["code"] == "application_pending"
    assert client.post(f"{API}/investor/application/documents/selfie", headers=h, files={"file": ("s.png", PNG, "image/png")}).status_code == 403
