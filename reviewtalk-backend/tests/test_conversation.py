import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_conversation_interface():
    payload = {
        "user_id": "test_user_2",
        "user_question": "이 상품의 단점은 무엇인가요?",
        "product_id": "test_product_2"
    }
    response = client.post("/api/v1/conversation", params=payload)
    assert response.status_code == 200
    data = response.json()
    assert "success" in data
    assert "chat_result" in data 