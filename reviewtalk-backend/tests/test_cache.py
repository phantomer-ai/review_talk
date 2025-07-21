from app.utils.cache import ConversationCache

def test_conversation_cache():
    cache = ConversationCache(maxlen=3)
    user_id = "test_user_5"
    product_id = "test_product_5"
    # add_conversation
    cache.add_conversation(user_id, product_id, {"message": "m1"})
    cache.add_conversation(user_id, product_id, {"message": "m2"})
    cache.add_conversation(user_id, product_id, {"message": "m3"})
    # FIFO 유지
    cache.add_conversation(user_id, product_id, {"message": "m4"})
    recent = cache.get_recent_conversations(user_id, product_id)
    assert len(recent) == 3
    assert recent[0]["message"] == "m2"
    # set_conversations
    cache.set_conversations(user_id, product_id, [{"message": "mA"}, {"message": "mB"}])
    recent2 = cache.get_recent_conversations(user_id, product_id)
    assert len(recent2) == 2
    assert recent2[0]["message"] == "mA" 