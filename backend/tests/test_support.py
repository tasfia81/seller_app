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


def test_live_updates_are_scoped_and_tickets_are_single_use(client, admin, rakib, investor):
    from starlette.websockets import WebSocketDisconnect

    def ticket(headers):
        response = client.post(f"{API}/support/live-ticket", headers=headers)
        assert response.status_code == 200
        return response.json()["ticket"]

    def sign_in(socket, grant):
        socket.send_text(grant)
        assert socket.receive_text() == "ready"

    assert client.post(f"{API}/support/live-ticket").status_code == 401
    seller_ticket = ticket(rakib)

    with (
        client.websocket_connect(f"{API}/support/live") as seller_live,
        client.websocket_connect(f"{API}/support/live") as investor_live,
        client.websocket_connect(f"{API}/support/live") as admin_live,
    ):
        sign_in(seller_live, seller_ticket)
        sign_in(investor_live, ticket(investor))
        sign_in(admin_live, ticket(admin))
        with client.websocket_connect(f"{API}/support/live") as replay:
            replay.send_text(seller_ticket)
            with pytest.raises(WebSocketDisconnect) as error:
                replay.receive_text()
            assert error.value.code == 1008

        created = client.post(f"{API}/support/threads", headers=rakib,
                              json={"topic": "cash", "text": "সাপোর্ট অনুরোধ", "client_request_id": "live-seller-1"})
        assert created.status_code == 201
        thread_id = created.json()["id"]
        assert seller_live.receive_text() == admin_live.receive_text() == "changed"

        reply = client.post(f"{API}/admin/support/threads/{thread_id}/messages", headers=admin,
                            json={"text": "উত্তর পাঠানো হয়েছে", "client_request_id": "live-admin-1"})
        assert reply.status_code == 200
        assert seller_live.receive_text() == admin_live.receive_text() == "changed"
        assert client.get(f"{API}/support/threads/{thread_id}", headers=rakib).json()["messages"][-1]["text"] == "উত্তর পাঠানো হয়েছে"
        assert client.get(f"{API}/support/threads", headers=investor).json() == []

        # An unrelated owner never appears in an investor's inbox, but their own message routes to both sides.
        created = client.post(f"{API}/support/threads", headers=investor,
                              json={"topic": "profit", "text": "আরেকটি প্রশ্ন", "client_request_id": "live-investor-1"})
        assert created.status_code == 201
        assert investor_live.receive_text() == admin_live.receive_text() == "changed"
