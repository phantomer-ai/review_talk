"""
통합 상품 리뷰 크롤링 서비스
products 테이블에 상품 정보를 저장하고 리뷰를 크롤링하는 통합 서비스
"""
import asyncio
import re
from typing import Dict, Any, List, Optional
from loguru import logger

from app.infrastructure.crawler.danawa_crawler import DanawaCrawler
from app.infrastructure.product_repository import ProductRepository
from app.infrastructure.ai.vector_store import VectorStore
from app.models.schemas import CrawlRequest, CrawlResponse


class CrawlProductReviewService:
    """통합 상품 리뷰 크롤링 서비스"""
    
    def __init__(self):
        self.crawler = DanawaCrawler()
        self.product_repository = ProductRepository()
        self.vector_store = VectorStore()
    
    async def crawl_product_reviews(self, request: CrawlRequest) -> CrawlResponse:
        """상품 리뷰 크롤링 메인 플로우"""
        try:
            logger.info(f"상품 리뷰 크롤링 시작: {request.product_url}")
            
            # 1. URL에서 상품 ID 추출
            product_id = self._extract_product_id(request.product_url)
            if not product_id:
                return CrawlResponse(
                    success=False,
                    message="상품 URL에서 상품 ID를 추출할 수 없습니다.",
                    reviews_found=0
                )
            
            # 2. 기본 상품 정보 생성/업데이트
            product_data = await self._create_or_update_product(product_id, request.product_url)
            if not product_data:
                return CrawlResponse(
                    success=False,
                    message="상품 정보 저장에 실패했습니다.",
                    reviews_found=0
                )
            
            # 3. 상품 상세 정보 크롤링 및 업데이트
            product_info = await self._crawl_product_info(request.product_url)
            if product_info:
                await self._update_product_details(product_id, product_info)
            
            # 4. 리뷰 크롤링
            reviews = await self._crawl_reviews(request.product_url, request.max_reviews)
            
            if not reviews:
                self.product_repository.update_crawl_status(product_id, True, 0)
                return CrawlResponse(
                    success=True,
                    message="리뷰를 찾을 수 없습니다.",
                    reviews_found=0,
                    product_id=product_id
                )
            
            # 5. 벡터 스토어에 리뷰 저장
            stored_count = await self._store_reviews_to_vector(product_id, reviews)
            
            # 6. 상품 크롤링 상태 업데이트
            self.product_repository.update_crawl_status(product_id, True, stored_count)
            
            logger.info(f"크롤링 완료: {product_id}, 리뷰 {stored_count}개")
            
            return CrawlResponse(
                success=True,
                message=f"리뷰 크롤링이 완료되었습니다. (총 {stored_count}개)",
                reviews_found=stored_count,
                product_id=product_id,
                product_info=product_info
            )
            
        except Exception as e:
            logger.error(f"상품 리뷰 크롤링 실패: {e}")
            return CrawlResponse(
                success=False,
                message=f"크롤링 중 오류가 발생했습니다: {str(e)}",
                reviews_found=0
            )
    
    async def crawl_special_product(self, product_data: Dict[str, Any], max_reviews: int = 50) -> Dict[str, Any]:
        """특가 상품 크롤링 (special_deals_manage_service에서 호출)"""
        try:
            product_id = product_data.get('product_id')
            product_url = product_data.get('product_url')
            
            if not product_id or not product_url:
                return {'success': False, 'message': '상품 ID 또는 URL이 없습니다.'}
            
            # 1. 상품을 특가 상품으로 저장
            product_data['is_special'] = True
            saved_product = self.product_repository.create_or_update_product(product_data)
            
            if not saved_product:
                return {'success': False, 'message': '특가 상품 저장 실패'}
            
            # 2. 리뷰 크롤링
            reviews = await self._crawl_reviews(product_url, max_reviews)
            
            if reviews:
                # 3. 벡터 스토어에 저장
                stored_count = await self._store_reviews_to_vector(product_id, reviews)
                
                # 4. 크롤링 상태 업데이트
                self.product_repository.update_crawl_status(product_id, True, stored_count)
                
                logger.info(f"특가 상품 크롤링 완료: {product_id}, 리뷰 {stored_count}개")
                
                return {
                    'success': True,
                    'message': f'특가 상품 크롤링 완료 (리뷰 {stored_count}개)',
                    'reviews_found': stored_count,
                    'product_id': product_id
                }
            else:
                # 리뷰는 없지만 상품 정보는 저장 완료
                self.product_repository.update_crawl_status(product_id, True, 0)
                return {
                    'success': True,
                    'message': '특가 상품 저장 완료 (리뷰 없음)',
                    'reviews_found': 0,
                    'product_id': product_id
                }
            
        except Exception as e:
            logger.error(f"특가 상품 크롤링 실패: {e}")
            return {'success': False, 'message': f'크롤링 실패: {str(e)}'}
    
    def _extract_product_id(self, product_url: str) -> Optional[str]:
        """URL에서 상품 ID 추출"""
        patterns = [
            r'pcode=(\d+)',
            r'code=(\d+)',
            r'/(\d+)/?$',
            r'product_no=(\d+)'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, product_url)
            if match:
                return match.group(1)
        
        logger.warning(f"상품 ID 추출 실패: {product_url}")
        return None
    
    async def _create_or_update_product(self, product_id: str, product_url: str) -> Optional[Dict[str, Any]]:
        """기본 상품 정보 생성/업데이트"""
        try:
            product_data = {
                'product_id': product_id,
                'product_name': f'상품 {product_id}',  # 기본값, 나중에 상세 정보로 업데이트
                'product_url': product_url,
                'is_crawled': False
            }
            
            return self.product_repository.create_or_update_product(product_data)
            
        except Exception as e:
            logger.error(f"기본 상품 정보 생성 실패: {e}")
            return None
    
    async def _crawl_product_info(self, product_url: str) -> Optional[Dict[str, Any]]:
        """상품 상세 정보 크롤링"""
        try:
            # DanawaCrawler를 사용하여 상품 정보 크롤링
            product_info = await asyncio.to_thread(
                self.crawler.get_product_info, product_url
            )
            return product_info
            
        except Exception as e:
            logger.error(f"상품 정보 크롤링 실패: {e}")
            return None
    
    async def _update_product_details(self, product_id: str, product_info: Dict[str, Any]) -> bool:
        """상품 상세 정보 업데이트"""
        try:
            update_data = {
                'product_id': product_id,
                'product_name': product_info.get('name', f'상품 {product_id}'),
                'brand': product_info.get('brand'),
                'category': product_info.get('category'),
                'rating': product_info.get('rating'),
                'image_url': product_info.get('image_url'),
                'price': product_info.get('price')
            }
            
            updated_product = self.product_repository.create_or_update_product(update_data)
            return updated_product is not None
            
        except Exception as e:
            logger.error(f"상품 상세 정보 업데이트 실패: {e}")
            return False
    
    async def _crawl_reviews(self, product_url: str, max_reviews: int) -> List[Dict[str, Any]]:
        """리뷰 크롤링"""
        try:
            reviews = await asyncio.to_thread(
                self.crawler.crawl_reviews, product_url, max_reviews
            )
            
            logger.info(f"리뷰 크롤링 완료: {len(reviews)}개")
            return reviews
            
        except Exception as e:
            logger.error(f"리뷰 크롤링 실패: {e}")
            return []
    
    async def _store_reviews_to_vector(self, product_id: str, reviews: List[Dict[str, Any]]) -> int:
        """벡터 스토어에 리뷰 저장"""
        try:
            stored_count = 0
            
            for review in reviews:
                try:
                    # 벡터 스토어에 리뷰 추가
                    success = self.vector_store.add_review(
                        product_id=product_id,
                        review_text=review.get('content', ''),
                        metadata={
                            'product_id': product_id,
                            'review_id': review.get('id'),
                            'rating': review.get('rating'),
                            'author': review.get('author'),
                            'date': review.get('date')
                        }
                    )
                    
                    if success:
                        stored_count += 1
                        
                except Exception as e:
                    logger.warning(f"개별 리뷰 저장 실패: {e}")
                    continue
            
            logger.info(f"벡터 스토어 저장 완료: {stored_count}/{len(reviews)}개")
            return stored_count
            
        except Exception as e:
            logger.error(f"벡터 스토어 저장 실패: {e}")
            return 0
    
    def get_product_info(self, product_id: str) -> Optional[Dict[str, Any]]:
        """상품 정보 조회"""
        return self.product_repository.get_product_by_id(product_id)
    
    def get_product_by_url(self, product_url: str) -> Optional[Dict[str, Any]]:
        """URL로 상품 정보 조회"""
        return self.product_repository.get_product_by_url(product_url)
    
    def get_crawl_statistics(self) -> Dict[str, Any]:
        """크롤링 통계 정보"""
        return self.product_repository.get_product_statistics()