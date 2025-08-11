"""
데이터베이스 마이그레이션 관리 모듈
"""
import sqlite3
from pathlib import Path
from loguru import logger
from typing import Dict, List
from app.core.config import settings


def extract_sqlite_path(db_url: str) -> str:
    if db_url.startswith("sqlite:///"):
        return db_url.replace("sqlite:///", "")
    raise ValueError("Only sqlite:/// URLs are supported")


DB_PATH = Path(extract_sqlite_path(settings.database_url))

# 데이터베이스 스키마 버전 관리
SCHEMA_VERSION = 3

# 마이그레이션 스크립트들
MIGRATIONS = {
    1: {
        "description": "Initial schema with basic tables",
        "up": """
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
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
    },
    2: {
        "description": "Add is_crawled column to products table",
        "up": """
        -- 컬럼이 존재하지 않을 때만 추가
        ALTER TABLE products ADD COLUMN is_crawled BOOLEAN DEFAULT FALSE;
        """
    },
    3: {
        "description": "Add chat_room, reviews, and conversations tables",
        "up": """
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

        CREATE TABLE IF NOT EXISTS conversations (
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
    }
}


def get_schema_version() -> int:
    """현재 데이터베이스 스키마 버전 조회"""
    try:
        with sqlite3.connect(DB_PATH) as conn:
            cursor = conn.cursor()
            
            # schema_version 테이블 존재 확인
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name='schema_version'
            """)
            
            if not cursor.fetchone():
                # schema_version 테이블이 없으면 버전 0
                return 0
            
            # 현재 버전 조회
            cursor.execute("SELECT version FROM schema_version ORDER BY id DESC LIMIT 1")
            result = cursor.fetchone()
            return result[0] if result else 0
            
    except Exception as e:
        logger.warning(f"스키마 버전 조회 실패: {e}")
        return 0


def set_schema_version(version: int):
    """스키마 버전 설정"""
    try:
        with sqlite3.connect(DB_PATH) as conn:
            cursor = conn.cursor()
            
            # schema_version 테이블 생성
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS schema_version (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    version INTEGER NOT NULL,
                    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # 새 버전 기록
            cursor.execute("""
                INSERT INTO schema_version (version) VALUES (?)
            """, (version,))
            
            conn.commit()
            logger.info(f"스키마 버전 {version}으로 업데이트")
            
    except Exception as e:
        logger.error(f"스키마 버전 설정 실패: {e}")
        raise


def column_exists(table_name: str, column_name: str) -> bool:
    """특정 테이블에 컬럼이 존재하는지 확인"""
    try:
        with sqlite3.connect(DB_PATH) as conn:
            cursor = conn.cursor()
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = [row[1] for row in cursor.fetchall()]
            return column_name in columns
    except Exception:
        return False


def apply_migration(version: int) -> bool:
    """특정 버전의 마이그레이션 적용"""
    if version not in MIGRATIONS:
        logger.warning(f"마이그레이션 버전 {version}을 찾을 수 없습니다")
        return False
    
    migration = MIGRATIONS[version]
    logger.info(f"마이그레이션 {version} 적용 중: {migration['description']}")
    
    try:
        with sqlite3.connect(DB_PATH) as conn:
            cursor = conn.cursor()
            
            # 특별 처리: is_crawled 컬럼 추가
            if version == 2:
                if not column_exists('products', 'is_crawled'):
                    cursor.execute("ALTER TABLE products ADD COLUMN is_crawled BOOLEAN DEFAULT FALSE")
                    logger.info("✅ is_crawled 컬럼 추가 완료")
                else:
                    logger.info("✅ is_crawled 컬럼이 이미 존재합니다")
            else:
                # 일반 마이그레이션 실행
                cursor.executescript(migration['up'])
            
            conn.commit()
            set_schema_version(version)
            return True
            
    except Exception as e:
        logger.error(f"마이그레이션 {version} 적용 실패: {e}")
        return False


def migrate_database():
    """데이터베이스 마이그레이션 실행"""
    current_version = get_schema_version()
    target_version = SCHEMA_VERSION
    
    logger.info(f"데이터베이스 마이그레이션 시작: {current_version} → {target_version}")
    
    # 스키마 검증으로 실제 마이그레이션 필요 여부 확인
    if current_version >= target_version:
        # 버전은 최신이지만 실제 컬럼이 누락된 경우 처리
        if not column_exists('products', 'is_crawled'):
            logger.warning("스키마 버전은 최신이지만 is_crawled 컬럼이 누락됨. 강제 마이그레이션 실행")
            if not apply_migration(2):
                logger.error("강제 마이그레이션 실패")
                return False
        else:
            logger.info("마이그레이션이 필요하지 않습니다")
        return True
    
    # 순차적으로 마이그레이션 적용
    for version in range(current_version + 1, target_version + 1):
        if not apply_migration(version):
            logger.error(f"마이그레이션 {version} 실패로 중단")
            return False
    
    logger.info(f"✅ 데이터베이스 마이그레이션 완료: 버전 {target_version}")
    return True


def verify_schema():
    """스키마 무결성 검증"""
    try:
        with sqlite3.connect(DB_PATH) as conn:
            cursor = conn.cursor()
            
            # 필수 테이블 확인
            required_tables = ['users', 'products', 'chat_room', 'reviews', 'conversations']
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name IN ({})
            """.format(','.join('?' * len(required_tables))), required_tables)
            
            existing_tables = [row[0] for row in cursor.fetchall()]
            missing_tables = set(required_tables) - set(existing_tables)
            
            if missing_tables:
                logger.error(f"누락된 테이블: {missing_tables}")
                return False
            
            # 필수 컬럼 확인
            required_columns = {
                'products': ['is_crawled', 'is_special', 'product_id']
            }
            
            for table, columns in required_columns.items():
                for column in columns:
                    if not column_exists(table, column):
                        logger.error(f"누락된 컬럼: {table}.{column}")
                        return False
            
            logger.info("✅ 스키마 무결성 검증 통과")
            return True
            
    except Exception as e:
        logger.error(f"스키마 검증 실패: {e}")
        return False