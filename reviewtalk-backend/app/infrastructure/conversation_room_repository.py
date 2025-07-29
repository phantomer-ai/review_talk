import sqlite3
import os
from typing import List, Dict, Any, Optional
from pathlib import Path
from app.core.config import settings

def extract_sqlite_path(db_url: str) -> str:
    if db_url.startswith("sqlite:///"):
        return db_url.replace("sqlite:///", "")
    raise ValueError("Only sqlite:/// URLs are supported")

DB_PATH = Path(extract_sqlite_path(settings.database_url))

class ConversationRoomRepository:
    """chat_room과 conversations 테이블을 join하여 데이터를 조회하는 Repository"""
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or DB_PATH

    def get_conversations_by_user_and_product(
        self, user_id: str, product_id: int, limit: int = 30
    ) -> List[Dict[str, Any]]:
        """
        user_id와 product_id로 chat_room을 찾고, 해당 채팅방의 대화 내용을 limit만큼 조회 (오래된 순)
        """
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            # 서브쿼리를 사용하여 chat_room_id를 찾고, 해당 id로 conversations를 조회 후 limit 적용
            cursor.execute(
                """
                SELECT
                    conv.id,
                    conv.chat_room_id,
                    conv.message,
                    conv.chat_user_id,
                    conv.related_review_ids,
                    conv.created_at
                FROM conversations conv
                JOIN chat_room cr ON conv.chat_room_id = cr.id
                WHERE cr.user_id = ? AND cr.product_id = ?
                ORDER BY conv.created_at DESC
                LIMIT ?
                """,
                (user_id, product_id, limit)
            )
            rows = cursor.fetchall()
            # 최신순으로 가져오므로 FIFO를 위해 reverse
            return [
                {
                    "id": row[0],
                    "chat_room_id": row[1],
                    "message": row[2],
                    "chat_user_id": row[3],
                    "related_review_ids": row[4],
                    "created_at": row[5],
                }
                for row in reversed(rows)
            ]
        finally:
            conn.close()

# 전역 Repository 인스턴스 (필요시 사용)
# conversation_room_repository = ConversationRoomRepository() 