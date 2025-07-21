import pytest
from app.services.ai_service import AIService
import asyncio

@pytest.mark.asyncio
async def test_chat_with_reviews():
    ai_service = AIService()
    result = await ai_service.chat_with_reviews(
        user_id="test_user_3",
        user_question="이 상품의 특징은?",
        product_id="test_product_3",
        n_results=3
    )
    assert isinstance(result, dict)
    assert "success" in result
    assert "ai_response" in result or "answer" in result

@pytest.mark.asyncio
async def test_store_chat():
    ai_service = AIService()
    row_id = await ai_service.store_chat(
        user_id="test_user_3",
        product_id="3",
        message="테스트 메시지",
        chat_user_id="test_user_3",
        related_review_ids=["r1", "r2"]
    )
    assert isinstance(row_id, int) 