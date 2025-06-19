"""
특가 상품 서비스 - 비즈니스 로직 처리
"""
import asyncio
from typing import List, Dict, Any
from datetime import datetime

from loguru import logger

from app.models.schemas import (
    SpecialProduct, 
    SpecialProductsResponse, 
    CrawlSpecialProductsRequest,
    CrawlSpecialProductsResponse
)
from app.infrastructure.special_product_repository import special_product_repository
from app.infrastructure.crawler.special_deals_crawler import crawl_special_deals
from app.infrastructure.crawler.danawa_crawler import crawl_danawa_reviews
from app.infrastructure.ai.vector_store import get_vector_store
from app.infrastructure.conversation_repository import conversation_repository


class SpecialDealsService:
    """특가 상품 서비스"""
    
    def __init__(self):
        self.repository = special_product_repository
    
    async def crawl_and_save_special_deals(
        self, 
        request: CrawlSpecialProductsRequest
    ) -> CrawlSpecialProductsResponse:
        """특가 상품 크롤링 및 저장"""
        logger.info(f"🚀 특가 상품 크롤링 시작 - 최대 {request.max_products}개")
        
        try:
            # 데이터베이스 초기화
            self.repository.init_db()
            
            # 1. 특가 상품 목록 크롤링
            logger.info("📦 특가 상품 목록 크롤링 중...")
            special_products = await crawl_special_deals(request.max_products)
            
            if not special_products:
                return CrawlSpecialProductsResponse(
                    success=False,
                    total_products=0,
                    products_with_reviews=0,
                    total_reviews=0,
                    error_message="특가 상품을 찾을 수 없습니다."
                )
            
            # 2. 특가 상품 저장
            saved_count = self.repository.save_special_products(special_products)
            logger.info(f"✅ {saved_count}개의 특가 상품 저장 완료")
            
            # 3. 각 상품별 리뷰 크롤링 (옵션)
            products_with_reviews = 0
            total_reviews = 0
            
            if request.crawl_reviews:
                logger.info("📝 각 상품별 리뷰 크롤링 시작...")
                
                for i, product in enumerate(special_products):
                    try:
                        logger.info(f"📖 상품 {i+1}/{len(special_products)}: {product.product_name}")
                        
                        # 리뷰 크롤링
                        review_result = await crawl_danawa_reviews(
                            product.product_url, 
                            request.max_reviews_per_product
                        )
                        
                        if review_result.get("success") and review_result.get("reviews"):
                            reviews = review_result["reviews"]
                            review_count = len(reviews)
                            
                            # 벡터 저장소에 리뷰 저장
                            await self._save_reviews_to_vector_store(
                                product.product_id,
                                product.product_name,
                                reviews
                            )
                            
                            # 크롤링 상태 업데이트
                            self.repository.update_crawl_status(
                                product.product_id, 
                                True, 
                                review_count
                            )
                            
                            products_with_reviews += 1
                            total_reviews += review_count
                            
                            logger.info(f"✅ {product.product_name}: {review_count}개 리뷰 저장")
                        else:
                            logger.warning(f"⚠️ {product.product_name}: 리뷰 크롤링 실패")
                        
                        # 각 상품 처리 후 잠시 대기 (서버 부하 방지)
                        await asyncio.sleep(2)
                        
                    except Exception as e:
                        logger.error(f"❌ 상품 리뷰 크롤링 오류 ({product.product_name}): {e}")
                        continue
            
            return CrawlSpecialProductsResponse(
                success=True,
                total_products=saved_count,
                products_with_reviews=products_with_reviews,
                total_reviews=total_reviews
            )
            
        except Exception as e:
            logger.error(f"❌ 특가 상품 크롤링 서비스 오류: {e}")
            return CrawlSpecialProductsResponse(
                success=False,
                total_products=0,
                products_with_reviews=0,
                total_reviews=0,
                error_message=str(e)
            )
    
    async def _save_reviews_to_vector_store(
        self, 
        product_id: str, 
        product_name: str, 
        reviews: List[Dict[str, Any]]
    ):
        """리뷰를 벡터 저장소에 저장"""
        try:
            documents = []
            metadatas = []
            ids = []
            
            for review in reviews:
                if hasattr(review, 'content') and review.content:
                    documents.append(review.content)
                    metadatas.append({
                        "product_id": product_id,
                        "product_name": product_name,
                        "rating": getattr(review, 'rating', None),
                        "author": getattr(review, 'author', None),
                        "date": getattr(review, 'date', None),
                        "review_id": getattr(review, 'review_id', None)
                    })
                    ids.append(f"{product_id}_{getattr(review, 'review_id', len(ids))}")
            
            if documents:
                vector_store = get_vector_store()
                product_info = {"product_name": product_name}
                vector_store.add_reviews(reviews, product_id, product_info)
                logger.info(f"✅ {len(documents)}개 리뷰를 벡터 저장소에 저장")
            
        except Exception as e:
            logger.error(f"❌ 벡터 저장소 저장 오류: {e}")
    
    def get_special_products(self, limit: int = 50, offset: int = 0) -> SpecialProductsResponse:
        """특가 상품 목록 조회"""
        try:
            products = self.repository.get_special_products(limit, offset)
            total_count = self.repository.get_total_count()
            
            return SpecialProductsResponse(
                success=True,
                total_count=total_count,
                products=products
            )
            
        except Exception as e:
            logger.error(f"❌ 특가 상품 조회 오류: {e}")
            return SpecialProductsResponse(
                success=False,
                total_count=0,
                products=[],
                error_message=str(e)
            )
    
    def get_special_product_by_id(self, product_id: str) -> SpecialProduct:
        """특정 특가 상품 조회"""
        try:
            return self.repository.get_special_product_by_id(product_id)
        except Exception as e:
            logger.error(f"❌ 특가 상품 조회 오류: {e}")
            return None
    
    async def process_uncrawled_products(self, batch_size: int = 5) -> Dict[str, Any]:
        """아직 리뷰가 크롤링되지 않은 상품들을 배치로 처리"""
        logger.info(f"🔄 미크롤링 상품 배치 처리 시작 (배치 크기: {batch_size})")
        
        try:
            # 미크롤링 상품 조회
            uncrawled_products = self.repository.get_uncrawled_products(batch_size)
            
            if not uncrawled_products:
                return {
                    "success": True,
                    "processed_count": 0,
                    "message": "처리할 미크롤링 상품이 없습니다."
                }
            
            processed_count = 0
            total_reviews = 0
            
            for product in uncrawled_products:
                try:
                    logger.info(f"📝 리뷰 크롤링: {product.product_name}")
                    
                    # 리뷰 크롤링
                    review_result = await crawl_danawa_reviews(product.product_url, 100)
                    
                    if review_result.get("success") and review_result.get("reviews"):
                        reviews = review_result["reviews"]
                        review_count = len(reviews)
                        
                        # 벡터 저장소에 저장
                        await self._save_reviews_to_vector_store(
                            product.product_id,
                            product.product_name,
                            reviews
                        )
                        
                        # 크롤링 상태 업데이트
                        self.repository.update_crawl_status(
                            product.product_id, 
                            True, 
                            review_count
                        )
                        
                        processed_count += 1
                        total_reviews += review_count
                        
                        logger.info(f"✅ {product.product_name}: {review_count}개 리뷰 처리 완료")
                    else:
                        # 실패해도 상태는 업데이트 (재시도 방지)
                        self.repository.update_crawl_status(product.product_id, True, 0)
                        logger.warning(f"⚠️ {product.product_name}: 리뷰 크롤링 실패")
                    
                    # 각 상품 처리 후 대기
                    await asyncio.sleep(3)
                    
                except Exception as e:
                    logger.error(f"❌ 상품 처리 오류 ({product.product_name}): {e}")
                    # 오류가 발생해도 상태 업데이트
                    self.repository.update_crawl_status(product.product_id, True, 0)
                    continue
            
            return {
                "success": True,
                "processed_count": processed_count,
                "total_reviews": total_reviews,
                "message": f"{processed_count}개 상품의 리뷰를 처리했습니다."
            }
            
        except Exception as e:
            logger.error(f"❌ 미크롤링 상품 배치 처리 오류: {e}")
            return {
                "success": False,
                "processed_count": 0,
                "total_reviews": 0,
                "error_message": str(e)
            }
    
    def cleanup_old_products(self, days: int = 7) -> Dict[str, Any]:
        """오래된 특가 상품 정리"""
        try:
            deleted_count = self.repository.delete_old_products(days)
            return {
                "success": True,
                "deleted_count": deleted_count,
                "message": f"{days}일 이전의 특가 상품 {deleted_count}개를 정리했습니다."
            }
        except Exception as e:
            logger.error(f"❌ 오래된 상품 정리 오류: {e}")
            return {
                "success": False,
                "deleted_count": 0,
                "error_message": str(e)
            }


# 전역 서비스 인스턴스
special_deals_service = SpecialDealsService() 