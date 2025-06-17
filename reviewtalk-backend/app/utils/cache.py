from collections import deque
from threading import Lock
from typing import Any, Dict, List

class ConversationCache:
    """
    chat_room_id를 키로, 최근 대화 30건만 FIFO로 저장하는 in-memory 캐시
    (Write-Behind 패턴 지원)
    """
    def __init__(self, maxlen: int = 30):
        self.cache: Dict[int, deque] = {}
        self.maxlen = maxlen
        self.lock = Lock()

    def add_conversation(self, chat_room_id: int, message: Dict[str, Any]) -> None:
        with self.lock:
            if chat_room_id not in self.cache:
                self.cache[chat_room_id] = deque(maxlen=self.maxlen)
            self.cache[chat_room_id].append(message)

    def get_recent_conversations(self, chat_room_id: int) -> List[Dict[str, Any]]:
        with self.lock:
            if chat_room_id in self.cache:
                return list(self.cache[chat_room_id])
            return []

    def set_conversations(self, chat_room_id: int, messages: List[Dict[str, Any]]) -> None:
        with self.lock:
            self.cache[chat_room_id] = deque(messages[-self.maxlen:], maxlen=self.maxlen) 