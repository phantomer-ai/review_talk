"""
통합 상품 데이터 관리 Repository (일반 상품 + 특가 상품)
"""
import sqlite3
from typing import List, Optional, Dict, Any
from datetime import datetime
import json

from loguru import logger
from app.core.config import settings
from app.models.schemas import SpecialProduct


class UnifiedProductRepository:
    """통합 상품 데이터 관리 (일반 상품 + 특가 상품)"""
    
    def __init__(self):
        self.db_path = settings.database_url.replace("sqlite:///", "")
    
    def init_db(self):
        """데이터베이스 초기화 - 상품 테이블 생성 (일반 상품 + 특가 상품 통합)"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # 통합 상품 테이블 생성
                cursor.execute("""
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
                        is_crawled BOOLEAN DEFAULT FALSE,
                        is_special BOOLEAN DEFAULT FALSE,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # 인덱스 생성
                cursor.execute("CREATE INDEX IF NOT EXISTS idx_product_id ON products(product_id)")
                cursor.execute("CREATE INDEX IF NOT EXISTS idx_created_at ON products(created_at)")
                cursor.execute("CREATE INDEX IF NOT EXISTS idx_is_crawled ON products(is_crawled)")
                cursor.execute("CREATE INDEX IF NOT EXISTS idx_is_special ON products(is_special)")
                
                conn.commit()
                logger.info("✅ 통합 상품 테이블 초기화 완료")
                
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
                        INSERT OR REPLACE INTO products (
                            product_id, product_name, product_url, image_url,
                            price, original_price, discount_rate, brand, category,
                            rating, review_count, is_crawled, is_special, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
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
                        product.is_crawled,
                        product.is_special
                    ))
                    saved_count += 1
                
                conn.commit()
                logger.info(f"✅ {saved_count}개의 특가 상품을 저장했습니다")
                
        except Exception as e:
            logger.error(f"❌ 특가 상품 저장 오류: {e}")
            raise
        
        return saved_count
    
    def get_special_products(self, limit: int = 50, only_crawled: bool = True) -> List[Dict[str, Any]]:
        """특가 상품 목록 조회 (Dict 반환으로 수정)"""
        products = []
        
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                where_clause = "WHERE is_special = TRUE"
                if only_crawled:
                    where_clause += " AND is_crawled = TRUE"
                
                cursor.execute(f"""
                    SELECT 
                        product_id, 
                        product_name, 
                        product_url, 
                        image_url,
                        price, 
                        original_price, 
                        discount_rate, 
                        brand, 
                        category,
                        rating, 
                        review_count, 
                        is_crawled, 
                        is_special, 
                        created_at, 
                        updated_at
                    FROM products 
                    {where_clause}
                    ORDER BY created_at DESC 
                    LIMIT ?
                """, (limit,))
                
                rows = cursor.fetchall()
                
                for row in rows:
                    products.append({
                        'product_id': row[0],
                        'product_name': row[1],
                        'product_url': row[2],
                        'image_url': row[3],
                        'price': row[4],
                        'original_price': row[5],
                        'discount_rate': row[6],
                        'brand': row[7],
                        'category': row[8],
                        'rating': row[9],
                        'review_count': row[10],
                        'is_crawled': bool(row[11]),
                        'is_special': bool(row[12]),
                        'created_at': row[13],
                        'updated_at': row[14]
                    })
                
                logger.info(f"✅ {len(products)}개의 특가 상품을 조회했습니다")
                
        except Exception as e:
            logger.error(f"❌ 특가 상품 조회 오류: {e}")
            raise
        
        return products
    
    def get_special_products_as_models(self, limit: int = 50, offset: int = 0) -> List[SpecialProduct]:
        """특가 상품 목록 조회 (SpecialProduct 모델 반환)"""
        products = []
        
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT 
                        product_id, product_name, product_url, image_url,
                        price, original_price, discount_rate, brand, category,
                        rating, review_count, is_crawled, is_special, created_at, updated_at
                    FROM products 
                    WHERE is_special = TRUE
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
                        is_special=bool(row[12]),
                        created_at=row[13],
                        updated_at=row[14]
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
                        rating, review_count, is_crawled, is_special, created_at, updated_at
                    FROM products 
                    WHERE product_id = ? AND is_special = TRUE
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
                        is_special=bool(row[12]),
                        created_at=row[13],
                        updated_at=row[14]
                    )
                
        except Exception as e:
            logger.error(f"❌ 특가 상품 조회 오류: {e}")
            raise
        
        return None
    
    def update_crawl_status(self, product_id: str, is_crawled: bool, review_count: int = 0) -> bool:
        """상품의 크롤링 상태 업데이트 (일반/특가 상품 모두 지원)"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    UPDATE products 
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
    
    def get_uncrawled_products(self, limit: int = 10) -> List[Dict[str, Any]]:
        """아직 리뷰가 크롤링되지 않은 특가 상품 조회 (Dict 반환)"""
        products = []
        
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT 
                        product_id, 
                        product_name, 
                        product_url, 
                        image_url,
                        price, 
                        original_price, 
                        discount_rate, 
                        brand, 
                        category,
                        rating, 
                        review_count, 
                        is_crawled, 
                        is_special, 
                        created_at, 
                        updated_at
                    FROM products 
                    WHERE is_special = TRUE 
                      AND is_crawled = FALSE
                    ORDER BY created_at ASC 
                    LIMIT ?
                """, (limit,))
                
                rows = cursor.fetchall()
                
                for row in rows:
                    products.append({
                        'product_id': row[0],
                        'product_name': row[1],
                        'product_url': row[2],
                        'image_url': row[3],
                        'price': row[4],
                        'original_price': row[5],
                        'discount_rate': row[6],
                        'brand': row[7],
                        'category': row[8],
                        'rating': row[9],
                        'review_count': row[10],
                        'is_crawled': bool(row[11]),
                        'is_special': bool(row[12]),
                        'created_at': row[13],
                        'updated_at': row[14]
                    })
                
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
                cursor.execute("SELECT COUNT(*) FROM products WHERE is_special = TRUE")
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
                    DELETE FROM products 
                    WHERE created_at < datetime('now', '-{} days') AND is_special = TRUE
                """.format(days))
                
                deleted_count = cursor.rowcount
                conn.commit()
                
                logger.info(f"✅ {deleted_count}개의 오래된 특가 상품을 삭제했습니다")
                return deleted_count
                
        except Exception as e:
            logger.error(f"❌ 오래된 상품 삭제 오류: {e}")
            return 0
    
    # 일반 상품 관련 메서드들 추가
    def create_or_update_product(self, product_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """상품 생성 또는 업데이트 (일반/특가 상품 모두 지원)"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # 기존 상품 확인
                cursor.execute("""
                    SELECT id, is_crawled, review_count FROM products 
                    WHERE product_id = ?
                """, (product_data['product_id'],))
                
                existing = cursor.fetchone()
                
                if existing:
                    # 업데이트
                    cursor.execute("""
                        UPDATE products SET
                            product_name = ?,
                            product_url = ?,
                            image_url = ?,
                            price = ?,
                            original_price = ?,
                            discount_rate = ?,
                            brand = ?,
                            category = ?,
                            rating = ?,
                            review_count = ?,
                            is_special = ?,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE product_id = ?
                    """, (
                        product_data.get('product_name'),
                        str(product_data.get('product_url')),
                        str(product_data.get('image_url')),
                        product_data.get('price'),
                        product_data.get('original_price'),
                        product_data.get('discount_rate'),
                        product_data.get('brand'),
                        product_data.get('category'),
                        product_data.get('rating'),
                        product_data.get('review_count', existing[2]),
                        product_data.get('is_special', False),
                        product_data['product_id']
                    ))
                    
                    logger.info(f"상품 업데이트 완료: {product_data['product_id']}")
                    
                else:
                    # 새로 생성
                    cursor.execute("""
                        INSERT INTO products (
                            product_id, product_name, product_url, image_url,
                            price, original_price, discount_rate, brand, category,
                            rating, review_count, is_special,
                            is_crawled, created_at, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """, (
                        product_data['product_id'],
                        product_data.get('product_name'),
                        str(product_data.get('product_url')),
                        str(product_data.get('image_url')),
                        product_data.get('price'),
                        product_data.get('original_price'),
                        product_data.get('discount_rate'),
                        product_data.get('brand'),
                        product_data.get('category'),
                        product_data.get('rating'),
                        product_data.get('review_count', 0),
                        product_data.get('is_special', False),
                        product_data.get('is_crawled', False)
                    ))
                    
                    logger.info(f"새 상품 생성 완료: {product_data['product_id']}")
                
                conn.commit()
                
                # 생성/업데이트된 상품 조회 후 반환
                return self.get_product_by_id(product_data['product_id'])
                
        except Exception as e:
            logger.error(f"상품 생성/업데이트 실패: {e}")
            return None
    
    def get_product_by_id(self, product_id: str) -> Optional[Dict[str, Any]]:
        """상품 ID로 조회 (일반/특가 상품 모두 지원)"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT * FROM products WHERE product_id = ?
                """, (product_id,))
                
                row = cursor.fetchone()
                if row:
                    columns = [desc[0] for desc in cursor.description]
                    return dict(zip(columns, row))
                return None
                
        except Exception as e:
            logger.error(f"상품 조회 실패: {e}")
            return None
    
    def get_product_by_url(self, product_url: str) -> Optional[Dict[str, Any]]:
        """상품 URL로 조회"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT * FROM products WHERE product_url = ?
                """, (product_url,))
                
                row = cursor.fetchone()
                if row:
                    columns = [desc[0] for desc in cursor.description]
                    return dict(zip(columns, row))
                return None
                
        except Exception as e:
            logger.error(f"URL로 상품 조회 실패: {e}")
            return None
    
    def get_products_by_ids(self, product_ids: List[str]) -> List[Dict[str, Any]]:
        """여러 상품 ID로 조회"""
        products = []
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                placeholders = ','.join(['?' for _ in product_ids])
                cursor.execute(f"""
                    SELECT * FROM products WHERE is_special = 0 AND product_id IN ({placeholders})
                """, product_ids)
                
                rows = cursor.fetchall()
                columns = [desc[0] for desc in cursor.description]
                
                for row in rows:
                    products.append(dict(zip(columns, row)))
                
                return products
                
        except Exception as e:
            logger.error(f"여러 상품 조회 실패: {e}")
            return []
    
    def get_product_statistics(self) -> Dict[str, Any]:
        """상품 통계 정보"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # 전체 상품 수
                cursor.execute("SELECT COUNT(*) FROM products")
                total_products = cursor.fetchone()[0]
                
                # 특가 상품 수
                cursor.execute("SELECT COUNT(*) FROM products WHERE is_special = TRUE")
                special_products = cursor.fetchone()[0]
                
                # 일반 상품 수
                cursor.execute("SELECT COUNT(*) FROM products WHERE is_special = FALSE")
                normal_products = cursor.fetchone()[0]
                
                # 크롤링 완료된 상품 수
                cursor.execute("SELECT COUNT(*) FROM products WHERE is_crawled = TRUE")
                crawled_products = cursor.fetchone()[0]
                
                # 크롤링 완료된 특가 상품 수
                cursor.execute("SELECT COUNT(*) FROM products WHERE is_special = TRUE AND is_crawled = TRUE")
                crawled_special_products = cursor.fetchone()[0]
                
                return {
                    'total_products': total_products,
                    'special_products': special_products,
                    'normal_products': normal_products,
                    'crawled_products': crawled_products,
                    'crawled_special_products': crawled_special_products,
                    'uncrawled_products': total_products - crawled_products
                }
                
        except Exception as e:
            logger.error(f"상품 통계 조회 실패: {e}")
            return {}
    
    def delete_product(self, product_id: str) -> bool:
        """상품 삭제"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("DELETE FROM products WHERE product_id = ?", (product_id,))
                conn.commit()
                return cursor.rowcount > 0
                
        except Exception as e:
            logger.error(f"상품 삭제 실패: {e}")
            return False


# 전역 Repository 인스턴스
unified_product_repository = UnifiedProductRepository() 