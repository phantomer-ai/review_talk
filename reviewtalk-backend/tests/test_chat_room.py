import pytest
from app.models.schemas import ChatRoomCreate, ChatRoomRead
from app.infrastructure.chat_room_repository import ChatRoomRepository
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

# Pydantic 모델 테스트
def test_chat_room_model():
    data = {"user_id": "user1", "product_id": 1}
    model = ChatRoomCreate(**data)
    assert model.user_id == "user1"
    assert model.product_id == 1

# Repository CRUD 테스트
def test_chat_room_repository_crud():
    repo = ChatRoomRepository()
    user_id = "test_user_crud"
    product_id = 12345
    # 생성
    chat_room_id = repo.create_chat_room(user_id, product_id)
    assert isinstance(chat_room_id, int)
    # 단일 조회
    room = repo.get_chat_room_by_id(chat_room_id)
    assert room["user_id"] == user_id
    assert room["product_id"] == product_id
    # user+product 조회
    room2 = repo.get_chat_room_by_user_and_product(user_id, product_id)
    assert room2["id"] == chat_room_id
    # user별 목록
    rooms = repo.get_chat_rooms_by_user(user_id)
    assert any(r["id"] == chat_room_id for r in rooms)
    # 삭제
    ok = repo.delete_chat_room(chat_room_id)
    assert ok

# FastAPI 엔드포인트 테스트
def test_create_and_get_and_delete_chat_room():
    # 생성
    payload = {"user_id": "api_user1", "product_id": 111}
    resp = client.post("/api/v1/chat-rooms/", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    chat_room_id = data["id"]
    # 단일 조회
    resp2 = client.get(f"/api/v1/chat-rooms/{chat_room_id}")
    assert resp2.status_code == 200
    assert resp2.json()["user_id"] == payload["user_id"]
    # 목록 조회
    resp3 = client.get(f"/api/v1/chat-rooms/?user_id={payload['user_id']}")
    assert resp3.status_code == 200
    assert any(r["id"] == chat_room_id for r in resp3.json()["chat_rooms"])
    # 삭제
    resp4 = client.delete(f"/api/v1/chat-rooms/{chat_room_id}")
    assert resp4.status_code == 204
    # 삭제 후 조회
    resp5 = client.get(f"/api/v1/chat-rooms/{chat_room_id}")
    assert resp5.status_code == 404 