"""
데이터베이스 초기화 및 연결 관리 모듈
"""
import sqlite3
import os
from pathlib import Path
from loguru import logger
from contextlib import contextmanager
from app.core.config import settings

# 데이터베이스 경로를 환경변수에서 읽어옴 (sqlite:///...) 형태 지원
def extract_sqlite_path(db_url: str) -> str:
    if db_url.startswith("sqlite:///"):
        return db_url.replace("sqlite:///", "")
    raise ValueError("Only sqlite:/// URLs are supported")

DB_PATH = Path(extract_sqlite_path(settings.database_url))
DB_DIR = DB_PATH.parent

# DDL 스크립트
CREATE_TABLES_SQL = """
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT UNIQUE NOT NULL,
    user_name TEXT NOT NULL,
    user_type TEXT NOT NULL CHECK(user_type IN ('human', 'ai')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id TEXT UNIQUE NOT NULL,
    product_name TEXT NOT NULL,
    product_url TEXT NOT NULL,
    image_url TEXT,
    price TEXT,
    original_price TEXT,
    discount_rate TEXT,
    brand TEXT,
    category TEXT,
    rating REAL,
    review_count INTEGER DEFAULT 0,
    is_special BOOLEAN DEFAULT FALSE,
    is_crawled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS chat_room (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    product_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS reviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    review_id TEXT UNIQUE NOT NULL,
    content TEXT NOT NULL,
    rating INTEGER,
    author TEXT,
    date TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS special_products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id TEXT UNIQUE NOT NULL,
    product_name TEXT NOT NULL,
    product_url TEXT NOT NULL,
    image_url TEXT,
    price TEXT,
    original_price TEXT,
    discount_rate TEXT,
    brand TEXT,
    category TEXT,
    rating REAL,
    review_count INTEGER DEFAULT 0,
    is_crawled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS conversations;

CREATE TABLE conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    chat_room_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    chat_user_id TEXT NOT NULL,
    related_review_ids TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (chat_room_id) REFERENCES chat_room(id) ON DELETE CASCADE,
    FOREIGN KEY (chat_user_id) REFERENCES user(user_id) ON DELETE SET NULL
);
    
"""


def init_database():
    """데이터베이스 초기화 함수 (마이그레이션 포함)"""
    try:
        # data 디렉터리가 없으면 생성
        DB_DIR.mkdir(parents=True, exist_ok=True)
        logger.info(f"Database directory ensured at: {DB_DIR}")
        
        # 데이터베이스 파일 존재 여부 확인
        if not DB_PATH.exists():
            logger.info(f"Database file not found. Creating new database at: {DB_PATH}")
            
            # 데이터베이스 생성 및 테이블 초기화
            with sqlite3.connect(DB_PATH) as conn:
                conn.executescript(CREATE_TABLES_SQL)
                conn.commit()
                logger.info("Database tables created successfully")
        else:
            logger.info(f"Database file already exists at: {DB_PATH}")
            
            # 🔄 마이그레이션 실행
            from app.database_migration import migrate_database, verify_schema
            
            if not migrate_database():
                logger.error("데이터베이스 마이그레이션 실패")
                raise RuntimeError("Database migration failed")
            
            if not verify_schema():
                logger.error("스키마 검증 실패")
                raise RuntimeError("Schema verification failed")
                    
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        raise


@contextmanager
def get_db_connection():
    """데이터베이스 연결 컨텍스트 매니저"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # 딕셔너리 형태로 결과 반환
    try:
        yield conn
    finally:
        conn.close()


def get_db():
    """FastAPI 의존성 주입을 위한 데이터베이스 연결 함수"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()