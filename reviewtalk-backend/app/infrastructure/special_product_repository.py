"""
특가 상품 데이터 관리 Repository
"""
import sqlite3
from typing import List, Optional, Dict, Any
from datetime import datetime
import json

from loguru import logger
from app.core.config import settings
from app.models.schemas import SpecialProduct


class SpecialProductRepository:
    """특가 상품 데이터 관리"""
    
    def __init__(self):
        self.db_path = settings.database_url.replace("sqlite:///", "")
    
    def init_db(self):
        """데이터베이스 초기화 - 특가 상품 테이블 생성"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # 특가 상품 테이블 생성
                cursor.execute("""
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
                    )
                """)
                
                # 인덱스 생성
                cursor.execute("CREATE INDEX IF NOT EXISTS idx_product_id ON special_products(product_id)")
                cursor.execute("CREATE INDEX IF NOT EXISTS idx_created_at ON special_products(created_at)")
                cursor.execute("CREATE INDEX IF NOT EXISTS idx_is_crawled ON special_products(is_crawled)")
                
                conn.commit()
                logger.info("✅ 특가 상품 테이블 초기화 완료")
                
        except Exception as e:
            logger.error(f"❌ 데이터베이스 초기화 오류: {e}")
            raise
    
    def save_special_products(self, products: List[SpecialProduct]) -> int:
        """특가 상품 목록 저장 (UPSERT)"""
        if not products:
            return 0
        
        saved_count = 0
        
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                for product in products:
                    # UPSERT 쿼리 (INSERT OR REPLACE)
                    cursor.execute("""
                        INSERT OR REPLACE INTO special_products (
                            product_id, product_name, product_url, image_url,
                            price, original_price, discount_rate, brand, category,
                            rating, review_count, is_crawled, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                    """, (
                        product.product_id,
                        product.product_name,
                        product.product_url,
                        product.image_url,
                        product.price,
                        product.original_price,
                        product.discount_rate,
                        product.brand,
                        product.category,
                        product.rating,
                        product.review_count,
                        product.is_crawled
                    ))
                    saved_count += 1
                
                conn.commit()
                logger.info(f"✅ {saved_count}개의 특가 상품을 저장했습니다")
                
        except Exception as e:
            logger.error(f"❌ 특가 상품 저장 오류: {e}")
            raise
        
        return saved_count
    
    def get_special_products(self, limit: int = 50, offset: int = 0) -> List[SpecialProduct]:
        """특가 상품 목록 조회"""
        products = []
        
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT 
                        product_id, product_name, product_url, image_url,
                        price, original_price, discount_rate, brand, category,
                        rating, review_count, is_crawled, created_at, updated_at
                    FROM special_products 
                    ORDER BY created_at DESC 
                    LIMIT ? OFFSET ?
                """, (limit, offset))
                
                rows = cursor.fetchall()
                
                for row in rows:
                    products.append(SpecialProduct(
                        product_id=row[0],
                        product_name=row[1],
                        product_url=row[2],
                        image_url=row[3],
                        price=row[4],
                        original_price=row[5],
                        discount_rate=row[6],
                        brand=row[7],
                        category=row[8],
                        rating=row[9],
                        review_count=row[10],
                        is_crawled=bool(row[11]),
                        created_at=row[12],
                        updated_at=row[13]
                    ))
                
                logger.info(f"✅ {len(products)}개의 특가 상품을 조회했습니다")
                
        except Exception as e:
            logger.error(f"❌ 특가 상품 조회 오류: {e}")
            raise
        
        return products
    
    def get_special_product_by_id(self, product_id: str) -> Optional[SpecialProduct]:
        """특정 특가 상품 조회"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT 
                        product_id, product_name, product_url, image_url,
                        price, original_price, discount_rate, brand, category,
                        rating, review_count, is_crawled, created_at, updated_at
                    FROM special_products 
                    WHERE product_id = ?
                """, (product_id,))
                
                row = cursor.fetchone()
                
                if row:
                    return SpecialProduct(
                        product_id=row[0],
                        product_name=row[1],
                        product_url=row[2],
                        image_url=row[3],
                        price=row[4],
                        original_price=row[5],
                        discount_rate=row[6],
                        brand=row[7],
                        category=row[8],
                        rating=row[9],
                        review_count=row[10],
                        is_crawled=bool(row[11]),
                        created_at=row[12],
                        updated_at=row[13]
                    )
                
        except Exception as e:
            logger.error(f"❌ 특가 상품 조회 오류: {e}")
            raise
        
        return None
    
    def update_crawl_status(self, product_id: str, is_crawled: bool, review_count: int = 0) -> bool:
        """특가 상품의 크롤링 상태 업데이트"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    UPDATE special_products 
                    SET is_crawled = ?, review_count = ?, updated_at = CURRENT_TIMESTAMP
                    WHERE product_id = ?
                """, (is_crawled, review_count, product_id))
                
                success = cursor.rowcount > 0
                conn.commit()
                
                if success:
                    logger.info(f"✅ 상품 {product_id} 크롤링 상태 업데이트 완료")
                
                return success
                
        except Exception as e:
            logger.error(f"❌ 크롤링 상태 업데이트 오류: {e}")
            raise
        
        return False
    
    def get_uncrawled_products(self, limit: int = 10) -> List[SpecialProduct]:
        """아직 리뷰가 크롤링되지 않은 특가 상품 조회"""
        products = []
        
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT 
                        product_id, product_name, product_url, image_url,
                        price, original_price, discount_rate, brand, category,
                        rating, review_count, is_crawled, created_at, updated_at
                    FROM special_products 
                    WHERE is_crawled = FALSE
                    ORDER BY created_at ASC 
                    LIMIT ?
                """, (limit,))
                
                rows = cursor.fetchall()
                
                for row in rows:
                    products.append(SpecialProduct(
                        product_id=row[0],
                        product_name=row[1],
                        product_url=row[2],
                        image_url=row[3],
                        price=row[4],
                        original_price=row[5],
                        discount_rate=row[6],
                        brand=row[7],
                        category=row[8],
                        rating=row[9],
                        review_count=row[10],
                        is_crawled=bool(row[11]),
                        created_at=row[12],
                        updated_at=row[13]
                    ))
                
                logger.info(f"✅ {len(products)}개의 미크롤링 특가 상품을 조회했습니다")
                
        except Exception as e:
            logger.error(f"❌ 미크롤링 상품 조회 오류: {e}")
            raise
        
        return products
    
    def get_total_count(self) -> int:
        """전체 특가 상품 수 조회"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*) FROM special_products")
                count = cursor.fetchone()[0]
                return count
        except Exception as e:
            logger.error(f"❌ 특가 상품 수 조회 오류: {e}")
            return 0
    
    def delete_old_products(self, days: int = 7) -> int:
        """오래된 특가 상품 삭제"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    DELETE FROM special_products 
                    WHERE created_at < datetime('now', '-{} days')
                """.format(days))
                
                deleted_count = cursor.rowcount
                conn.commit()
                
                logger.info(f"✅ {deleted_count}개의 오래된 특가 상품을 삭제했습니다")
                return deleted_count
                
        except Exception as e:
            logger.error(f"❌ 오래된 상품 삭제 오류: {e}")
            return 0


# 전역 Repository 인스턴스
special_product_repository = SpecialProductRepository() 