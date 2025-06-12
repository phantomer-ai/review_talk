from collections import deque
from threading import Lock
from typing import Any, Dict, List, Tuple

class ConversationCache:
    """
    user_id+product_id 조합을 키로, 최근 대화 30건만 FIFO로 저장하는 in-memory 캐시
    (Write-Behind 패턴 지원)
    """
    def __init__(self, maxlen: int = 30):
        self.cache: Dict[str, deque] = {}
        self.maxlen = maxlen
        self.lock = Lock()

    def _make_key(self, user_id: str, product_id: str) -> str:
        return f"{user_id}:{product_id}"

    def add_conversation(self, user_id: str, product_id: str, message: Dict[str, Any]) -> None:
        key = self._make_key(user_id, product_id)
        with self.lock:
            if key not in self.cache:
                self.cache[key] = deque(maxlen=self.maxlen)
            self.cache[key].append(message)

    def get_recent_conversations(self, user_id: str, product_id: str) -> List[Dict[str, Any]]:
        key = self._make_key(user_id, product_id)
        with self.lock:
            if key in self.cache:
                return list(self.cache[key])
            return []

    def set_conversations(self, user_id: str, product_id: str, messages: List[Dict[str, Any]]) -> None:
        key = self._make_key(user_id, product_id)
        with self.lock:
            self.cache[key] = deque(messages[-self.maxlen:], maxlen=self.maxlen) 