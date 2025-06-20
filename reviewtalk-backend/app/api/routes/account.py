"""
Account(게스트 계정) 관련 API 라우터
"""
from fastapi import APIRouter, status
from fastapi.responses import JSONResponse
from loguru import logger
import uuid
from app.database import get_db_connection

router = APIRouter(prefix="/api/v1/account", tags=["Account"])

@router.post("/guest", status_code=status.HTTP_201_CREATED)
def create_guest_account():
    """게스트 계정(user_id=uuid) 발급 및 users 테이블 저장"""
    user_id = str(uuid.uuid4())
    user_name = "GUEST"
    user_type = "human"
    try:
        with get_db_connection() as conn:
            conn.execute(
                """
                INSERT INTO users (user_id, user_name, user_type)
                VALUES (?, ?, ?)
                """,
                (user_id, user_name, user_type)
            )
            conn.commit()
        logger.info(f"게스트 계정 생성: {user_id}")
        return {"user_id": user_id}
    except Exception as e:
        logger.error(f"게스트 계정 생성 실패: {e}")
        return JSONResponse(status_code=500, content={"detail": "계정 생성 실패"}) 