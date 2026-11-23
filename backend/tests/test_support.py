"""Support chat between sellers/investors and the office."""

import pytest

from tests.conftest import _login

API = "/api/v1"


@pytest.fixture()
def investor(client):
    return _login(client, "01913000000", "invest1234")


def test_seller_asks_admin_replies_and_resolves(client, admin, rakib, nusrat):
    topics = client.get(f"{API}/support/topics", headers=rakib).json()
    assert [t["id"] for t in topics] == ["stock", "sales", "cash", "account", "other"]

    body = {"topic": "cash", "text": "গতকালের ক্যাশ জমা এখনো যাচাই হয়নি", "client_request_id": "req-support-001"}
    r = client.post(f"{API}/support/threads", headers=rakib, json=body)
    assert r.status_code == 201, r.text
    tid = r.json()["id"]
    assert client.post(f"{API}/support/threads", headers=rakib, json=body).json()["id"] == tid  # double tap → same thread
    assert len(client.get(f"{API}/support/threads", headers=rakib).json()) == 1

    # another seller cannot read it; invalid topic refused
    assert client.get(f"{API}/support/threads/{tid}", headers=nusrat).status_code == 403
    bad = client.post(f"{API}/support/threads", headers=rakib, json={**body, "topic": "profit", "client_request_id": "req-support-002"})
    assert bad.json()["error"]["code"] == "invalid_topic"

    inbox = client.get(f"{API}/admin/support/threads", headers=admin).json()
    assert inbox["counts"]["waiting"] == 1 and inbox["items"][0]["unread"] == 1 and inbox["items"][0]["owner_kind"] == "seller"
    assert client.get(f"{API}/admin/nav-counts", headers=admin).json()["/support"] == 1

    reply = {"text": "দেখছি, ১০ মিনিটে জানাচ্ছি", "client_request_id": "req-support-adm-1"}
    t = client.post(f"{API}/admin/support/threads/{tid}/messages", headers=admin, json=reply).json()
    client.post(f"{API}/admin/support/threads/{tid}/messages", headers=admin, json=reply)  # retry → not duplicated
    assert [m["sender"] for m in t["messages"]] == ["user", "admin"]
    assert client.get(f"{API}/admin/nav-counts", headers=admin).json()["/support"] == 0

    mine = client.get(f"{API}/support/threads", headers=rakib).json()[0]
    assert mine["unread"] == 1 and mine["last_from"] == "admin"
    opened = client.get(f"{API}/support/threads/{tid}", headers=rakib).json()
    assert len(opened["messages"]) == 2 and client.get(f"{API}/support/threads", headers=rakib).json()[0]["unread"] == 0

    assert client.post(f"{API}/admin/support/threads/{tid}/resolve", headers=admin).json()["status"] == "resolved"
    # a new message from the seller opens it again
    again = client.post(f"{API}/support/threads/{tid}/messages", headers=rakib, json={"text": "আবার সমস্যা", "client_request_id": "req-support-003"})
    assert again.json()["status"] == "open"


def test_investor_and_role_walls(client, admin, investor):
    assert [t["id"] for t in client.get(f"{API}/support/topics", headers=investor).json()][0] == "profit"
    r = client.post(f"{API}/support/threads", headers=investor, json={"topic": "profit", "text": "লাভ কবে পাব?", "client_request_id": "req-inv-0001"})
    assert r.status_code == 201
    assert client.get(f"{API}/admin/support/threads?kind=investor", headers=admin).json()["items"][0]["owner_kind"] == "investor"
    assert client.get(f"{API}/support/threads", headers=admin).status_code == 403  # admins use the admin inbox
    assert client.get(f"{API}/admin/support/threads", headers=investor).status_code == 403
    empty = client.post(f"{API}/support/threads/{r.json()['id']}/messages", headers=investor, json={"text": "   ", "client_request_id": "req-inv-0002"})
    assert empty.status_code in (400, 422)
