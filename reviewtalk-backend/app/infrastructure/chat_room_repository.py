import sqlite3
import os
from typing import Optional, List, Dict, Any
from pathlib import Path
from app.core.config import settings

def extract_sqlite_path(db_url: str) -> str:
    if db_url.startswith("sqlite:///"):
        return db_url.replace("sqlite:///", "")
    raise ValueError("Only sqlite:/// URLs are supported")

DB_PATH = Path(extract_sqlite_path(settings.database_url))

class ChatRoomRepository:
    """chat_room 테이블 CRUD Repository"""
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or DB_PATH

    def create_chat_room(self, user_id: str, product_id: int) -> int:
        """
        채팅방 생성 (user_id + product_id 조합)
        이미 존재하면 기존 id 반환
        """
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            # 이미 존재하는지 확인
            cursor.execute(
                "SELECT id FROM chat_room WHERE user_id = ? AND product_id = ?",
                (user_id, product_id)
            )
            row = cursor.fetchone()
            if row:
                return row[0]
            # 새로 생성
            cursor.execute(
                "INSERT INTO chat_room (user_id, product_id) VALUES (?, ?)",
                (user_id, product_id)
            )
            conn.commit()
            return cursor.lastrowid
        finally:
            conn.close()

    def get_chat_room_by_id(self, chat_room_id: int) -> Optional[Dict[str, Any]]:
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT id, user_id, product_id, created_at FROM chat_room WHERE id = ?",
                (chat_room_id,)
            )
            row = cursor.fetchone()
            if row:
                return {
                    "id": row[0],
                    "user_id": row[1],
                    "product_id": row[2],
                    "created_at": row[3],
                }
            return None
        finally:
            conn.close()

    def get_chat_room_by_user_and_product(self, user_id: str, product_id: int) -> Optional[Dict[str, Any]]:
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT id, user_id, product_id, created_at FROM chat_room WHERE user_id = ? AND product_id = ?",
                (user_id, product_id)
            )
            row = cursor.fetchone()
            if row:
                return {
                    "id": row[0],
                    "user_id": row[1],
                    "product_id": row[2],
                    "created_at": row[3],
                }
            return None
        finally:
            conn.close()

    def get_chat_rooms_by_user(self, user_id: str) -> List[Dict[str, Any]]:
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT id, user_id, product_id, created_at FROM chat_room WHERE user_id = ? ORDER BY created_at DESC",
                (user_id,)
            )
            rows = cursor.fetchall()
            return [
                {
                    "id": row[0],
                    "user_id": row[1],
                    "product_id": row[2],
                    "created_at": row[3],
                }
                for row in rows
            ]
        finally:
            conn.close()

    def delete_chat_room(self, chat_room_id: int) -> bool:
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            cursor.execute(
                "DELETE FROM chat_room WHERE id = ?",
                (chat_room_id,)
            )
            conn.commit()
            return cursor.rowcount > 0
        finally:
            conn.close()

    def get_product_ids_by_user(self, user_id: str) -> List[str]:
        """특정 사용자의 채팅방에서 사용된 모든 product_id 목록 조회"""
        conn = sqlite3.connect(self.db_path)
        try:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT DISTINCT product_id FROM chat_room WHERE user_id = ? ORDER BY created_at DESC",
                (user_id,)
            )
            rows = cursor.fetchall()
            return [str(row[0]) for row in rows]
        finally:
            conn.close() 