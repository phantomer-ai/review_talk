from app.models.schemas import ChatRequest, ChatResponse
import pytest

def test_chat_request_valid():
    req = ChatRequest(user_id="u1", product_id="p1", question="질문?")
    assert req.user_id == "u1"
    assert req.product_id == "p1"
    assert req.question == "질문?"

@pytest.mark.parametrize("field,value", [
    ("user_id", None),
    ("question", "")
])
def test_chat_request_invalid(field, value):
    data = {"user_id": "u1", "product_id": "p1", "question": "질문?"}
    data[field] = value
    with pytest.raises(Exception):
        ChatRequest(**data) 