from typing import Optional, List, Dict, Any
import sqlite3
import os
from pathlib import Path
from app.core.config import settings

def extract_sqlite_path(db_url: str) -> str:
    if db_url.startswith("sqlite:///"):
        return db_url.replace("sqlite:///", "")
    raise ValueError("Only sqlite:/// URLs are supported")

DB_PATH = Path(extract_sqlite_path(settings.database_url))

class ConversationRepository:
    """conversations 테이블에 채팅 내용을 저장/조회하는 Repository (chat_room_id 기준)"""
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or DB_PATH

    def store_chat(self, chat_room_id: int, message: str, chat_user_id: str, related_review_ids: Optional[List[str]] = None) -> int:
        """
        채팅 내용을 conversations 테이블에 저장 (chat_room_id 기준)
        Args:
            chat_room_id (int): 채팅방 ID (FK)
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
                INSERT INTO conversations (chat_room_id, message, chat_user_id, related_review_ids)
                VALUES (?, ?, ?, ?)
                """,
                (chat_room_id, message, chat_user_id, related_review_ids_str)
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
                "SELECT id, chat_room_id, message, chat_user_id, related_review_ids, created_at FROM conversations WHERE id = ?",
                (conversation_id,)
            )
            row = cursor.fetchone()
            if row:
                return {
                    "id": row[0],
                    "chat_room_id": row[1],
                    "message": row[2],
                    "chat_user_id": row[3],
                    "related_review_ids": row[4],
                    "created_at": row[5],
                }
            return None
        finally:
            conn.close()

    def get_recent_conversations(self, chat_room_id: int, limit: int = 30) -> List[Dict[str, Any]]:
        """
        chat_room_id로 최근 대화 limit개를 created_at 오름차순(FIFO)으로 조회
        """
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            cursor.execute(
                """
                SELECT message, chat_user_id, related_review_ids, created_at
                FROM conversations
                WHERE chat_room_id = ?
                ORDER BY created_at DESC
                LIMIT ?
                """,
                (chat_room_id, limit)
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


# 전역 Repository 인스턴스
conversation_repository = ConversationRepository() 