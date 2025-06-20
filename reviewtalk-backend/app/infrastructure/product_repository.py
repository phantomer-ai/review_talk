"""
통합 상품 리포지토리 - products 테이블 관리
"""
import sqlite3
import json
from typing import Optional, List, Dict, Any
from datetime import datetime
from loguru import logger

from app.database import get_db_connection


class ProductRepository:
    """통합 상품 관리 리포지토리"""
    
    def create_or_update_product(self, product_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """상품 생성 또는 업데이트"""
        try:
            with get_db_connection() as conn:
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
                            special_data = ?,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE product_id = ?
                    """, (
                        product_data.get('product_name'),
                        product_data.get('product_url'),
                        product_data.get('image_url'),
                        product_data.get('price'),
                        product_data.get('original_price'),
                        product_data.get('discount_rate'),
                        product_data.get('brand'),
                        product_data.get('category'),
                        product_data.get('rating'),
                        product_data.get('review_count', existing['review_count']),
                        product_data.get('is_special', False),
                        json.dumps(product_data.get('special_data', {})) if product_data.get('special_data') else None,
                        product_data['product_id']
                    ))
                    
                    product_id = existing['id']
                    logger.info(f"상품 업데이트 완료: {product_data['product_id']}")
                    
                else:
                    # 새로 생성
                    cursor.execute("""
                        INSERT INTO products (
                            product_id, product_name, product_url, image_url,
                            price, original_price, discount_rate, brand, category,
                            rating, review_count, is_special, special_data,
                            is_crawled, created_at, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """, (
                        product_data['product_id'],
                        product_data.get('product_name'),
                        product_data.get('product_url'),
                        product_data.get('image_url'),
                        product_data.get('price'),
                        product_data.get('original_price'),
                        product_data.get('discount_rate'),
                        product_data.get('brand'),
                        product_data.get('category'),
                        product_data.get('rating'),
                        product_data.get('review_count', 0),
                        product_data.get('is_special', False),
                        json.dumps(product_data.get('special_data', {})) if product_data.get('special_data') else None,
                        product_data.get('is_crawled', False)
                    ))
                    
                    product_id = cursor.lastrowid
                    logger.info(f"새 상품 생성 완료: {product_data['product_id']}")
                
                conn.commit()
                
                # 생성/업데이트된 상품 조회 후 반환
                return self.get_product_by_id(product_data['product_id'])
                
        except Exception as e:
            logger.error(f"상품 생성/업데이트 실패: {e}")
            return None
    
    def get_product_by_id(self, product_id: str) -> Optional[Dict[str, Any]]:
        """상품 ID로 조회"""
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT * FROM products WHERE product_id = ?
                """, (product_id,))
                
                row = cursor.fetchone()
                if row:
                    product = dict(row)
                    # special_data JSON 파싱
                    if product.get('special_data'):
                        try:
                            product['special_data'] = json.loads(product['special_data'])
                        except:
                            product['special_data'] = {}
                    return product
                return None
                
        except Exception as e:
            logger.error(f"상품 조회 실패: {e}")
            return None
    
    def get_product_by_url(self, product_url: str) -> Optional[Dict[str, Any]]:
        """상품 URL로 조회"""
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT * FROM products WHERE product_url = ?
                """, (product_url,))
                
                row = cursor.fetchone()
                if row:
                    product = dict(row)
                    if product.get('special_data'):
                        try:
                            product['special_data'] = json.loads(product['special_data'])
                        except:
                            product['special_data'] = {}
                    return product
                return None
                
        except Exception as e:
            logger.error(f"URL로 상품 조회 실패: {e}")
            return None
    
    def mark_as_special(self, product_id: str, special_data: Dict[str, Any] = None) -> bool:
        """상품을 특가 상품으로 마킹"""
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    UPDATE products SET
                        is_special = TRUE,
                        special_data = ?,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE product_id = ?
                """, (
                    json.dumps(special_data or {}),
                    product_id
                ))
                
                conn.commit()
                return cursor.rowcount > 0
                
        except Exception as e:
            logger.error(f"특가 상품 마킹 실패: {e}")
            return False
    
    def update_crawl_status(self, product_id: str, is_crawled: bool, review_count: int = None) -> bool:
        """크롤링 상태 및 리뷰 개수 업데이트"""
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                
                if review_count is not None:
                    cursor.execute("""
                        UPDATE products SET
                            is_crawled = ?,
                            review_count = ?,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE product_id = ?
                    """, (is_crawled, review_count, product_id))
                else:
                    cursor.execute("""
                        UPDATE products SET
                            is_crawled = ?,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE product_id = ?
                    """, (is_crawled, product_id))
                
                conn.commit()
                return cursor.rowcount > 0
                
        except Exception as e:
            logger.error(f"크롤링 상태 업데이트 실패: {e}")
            return False
    
    def get_special_products(self, limit: int = 10, only_crawled: bool = True) -> List[Dict[str, Any]]:
        """특가 상품 목록 조회"""
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                
                query = """
                    SELECT * FROM products 
                    WHERE is_special = TRUE
                """
                
                if only_crawled:
                    query += " AND is_crawled = TRUE"
                
                query += " ORDER BY created_at DESC LIMIT ?"
                
                cursor.execute(query, (limit,))
                
                products = []
                for row in cursor.fetchall():
                    product = dict(row)
                    if product.get('special_data'):
                        try:
                            product['special_data'] = json.loads(product['special_data'])
                        except:
                            product['special_data'] = {}
                    products.append(product)
                
                return products
                
        except Exception as e:
            logger.error(f"특가 상품 목록 조회 실패: {e}")
            return []
    
    def get_products_by_ids(self, product_ids: List[str]) -> List[Dict[str, Any]]:
        """여러 상품 ID로 조회"""
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                
                placeholders = ','.join('?' * len(product_ids))
                cursor.execute(f"""
                    SELECT * FROM products 
                    WHERE product_id IN ({placeholders})
                """, product_ids)
                
                products = []
                for row in cursor.fetchall():
                    product = dict(row)
                    if product.get('special_data'):
                        try:
                            product['special_data'] = json.loads(product['special_data'])
                        except:
                            product['special_data'] = {}
                    products.append(product)
                
                return products
                
        except Exception as e:
            logger.error(f"여러 상품 조회 실패: {e}")
            return []
    
    def delete_product(self, product_id: str) -> bool:
        """상품 삭제"""
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("DELETE FROM products WHERE product_id = ?", (product_id,))
                conn.commit()
                return cursor.rowcount > 0
                
        except Exception as e:
            logger.error(f"상품 삭제 실패: {e}")
            return False
    
    def get_product_statistics(self) -> Dict[str, Any]:
        """상품 통계 정보"""
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                
                # 전체 상품 수
                cursor.execute("SELECT COUNT(*) as total FROM products")
                total = cursor.fetchone()['total']
                
                # 특가 상품 수
                cursor.execute("SELECT COUNT(*) as special FROM products WHERE is_special = TRUE")
                special = cursor.fetchone()['special']
                
                # 크롤링 완료 상품 수
                cursor.execute("SELECT COUNT(*) as crawled FROM products WHERE is_crawled = TRUE")
                crawled = cursor.fetchone()['crawled']
                
                # 총 리뷰 수
                cursor.execute("SELECT SUM(review_count) as total_reviews FROM products")
                total_reviews = cursor.fetchone()['total_reviews'] or 0
                
                return {
                    'total_products': total,
                    'special_products': special,
                    'crawled_products': crawled,
                    'total_reviews': total_reviews
                }
                
        except Exception as e:
            logger.error(f"상품 통계 조회 실패: {e}")
            return {}