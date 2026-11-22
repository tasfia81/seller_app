import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.storage import reset_store
from app.storage.local import LocalStore
from app.storage.seed import seed


@pytest.fixture()
def client():
    store = LocalStore(None)  # in memory, fresh for every test
    seed(store)
    reset_store(store)
    with TestClient(app) as c:
        yield c
    reset_store(None)


def _login(client: TestClient, identifier: str, password: str) -> dict[str, str]:
    r = client.post("/api/v1/auth/login", json={"identifier": identifier, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture()
def admin(client):
    return _login(client, "01711000000", "admin1234")


@pytest.fixture()
def rakib(client):
    return _login(client, "01712345678", "seller1234")


@pytest.fixture()
def nusrat(client):
    return _login(client, "01819223344", "seller1234")
