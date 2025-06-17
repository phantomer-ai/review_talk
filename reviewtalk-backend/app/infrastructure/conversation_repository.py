from typing import Optional, List, Dict, Any
import sqlite3
import os

DB_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
    "data",
    "reviewtalk.db"
)

class ConversationRepository:
    """conversations 테이블에 채팅 내용을 저장/조회하는 Repository"""
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or DB_PATH

    def store_chat(self, user_id: str, product_id: Optional[int], message: str, chat_user_id: str, related_review_ids: Optional[List[str]] = None) -> int:
        """
        채팅 내용을 conversations 테이블에 저장
        Args:
            user_id (str): 실제 대화 주체(사람) user_id
            product_id (Optional[int]): 제품 ID
            message (str): 채팅 메시지
            chat_user_id (str): 메시지 작성자(사람/AI)
            related_review_ids (Optional[List[str]]): 관련 리뷰 ID 목록
        Returns:
            int: 저장된 row의 id (primary key)
        """
        related_review_ids_str = ",".join(related_review_ids) if related_review_ids else None
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO conversations (user_id, product_id, message, chat_user_id, related_review_ids)
                VALUES (?, ?, ?, ?, ?)
                """,
                (user_id, product_id, message, chat_user_id, related_review_ids_str)
            )
            conn.commit()
            return cursor.lastrowid
        finally:
            conn.close()

    def get_conversation_by_id(self, conversation_id: int) -> Optional[Dict[str, Any]]:
        """
        conversation_id로 대화 내용 조회
        """
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT id, product_id, message, chat_user_id, related_review_ids, created_at FROM conversations WHERE id = ?",
                (conversation_id,)
            )
            row = cursor.fetchone()
            if row:
                return {
                    "id": row[0],
                    "product_id": row[1],
                    "message": row[2],
                    "chat_user_id": row[3],
                    "related_review_ids": row[4],
                    "created_at": row[5],
                }
            return None
        finally:
            conn.close()

    def get_recent_conversations(self, user_id: str, product_id: str, limit: int = 30) -> List[Dict[str, Any]]:
        """
        user_id, product_id 조합으로 최근 대화 limit개를 created_at 오름차순(FIFO)으로 조회
        """
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            cursor.execute(
                """
                SELECT message, chat_user_id, related_review_ids, created_at
                FROM conversations
                WHERE user_id = ? AND product_id = ?
                ORDER BY created_at DESC
                LIMIT ?
                """,
                (user_id, product_id, limit)
            )
            rows = cursor.fetchall()
            # 최신순으로 가져오므로 FIFO를 위해 reverse
            return [
                {
                    "message": row[0],
                    "chat_user_id": row[1],
                    "related_review_ids": row[2],
                    "created_at": row[3],
                }
                for row in reversed(rows)
            ]
        finally:
            conn.close() 