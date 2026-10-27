from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_home_page() -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert "Code to Cloud: DevSecOps" in response.text


def test_health_endpoint() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["version"]
    assert payload["timestamp"]
