from app.infrastructure.conversation_repository import ConversationRepository
import pytest

def test_store_and_get_recent_conversations():
    repo = ConversationRepository()
    user_id = "test_user_4"
    product_id = 4
    message = "테스트 저장 메시지"
    chat_user_id = "test_user_4"
    related_review_ids = ["r10", "r11"]
    # 저장
    row_id = repo.store_chat(user_id, product_id, message, chat_user_id, related_review_ids)
    assert isinstance(row_id, int)
    # 최근 대화 조회
    recent = repo.get_recent_conversations(user_id, str(product_id), limit=5)
    assert isinstance(recent, list)
    assert any(msg["message"] == message for msg in recent) 