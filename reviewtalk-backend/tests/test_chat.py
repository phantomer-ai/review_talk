import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_chat_with_ai():
    payload = {
        "user_id": "test_user_1",
        "product_id": "test_product_1",
        "question": "이 상품의 장점은 무엇인가요?"
    }
    response = client.post("/api/v1/chat", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "success" in data
    assert "ai_response" in data or "answer" in data 