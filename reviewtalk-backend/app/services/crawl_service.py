import asyncio
from typing import Dict, Any
from urllib.parse import urlparse
from loguru import logger

from app.infrastructure.crawler.danawa_crawler import crawl_danawa_reviews
from app.models.schemas import CrawlRequest, CrawlResponse, CrawlSpecialProductsRequest
from app.services.ai_service import AIService
from app.utils.url_utils import extract_product_id
from app.services.special_deals_service import special_deals_service


class CrawlService:
    """크롤링 서비스"""
    
    def __init__(self):
        """크롤링 서비스 초기화"""
        self.ai_service = AIService()
    
    @staticmethod
    def validate_url(url: str) -> bool:
        """URL 유효성 검증"""
        try:
            parsed = urlparse(str(url))
            # 다나와 도메인 체크 (danawa.com 또는 danawa.page.link)
            is_danawa_domain = any([
                'danawa.com' in parsed.netloc,
                'danawa.page.link' in parsed.netloc
            ])
            return (
                parsed.scheme in ['http', 'https'] and
                is_danawa_domain
            )
        except Exception:
            return False
    
    async def crawl_product_reviews(self, request: CrawlRequest) -> CrawlResponse:
        """상품 리뷰 크롤링 메인 함수 (특가 상품 리뷰도 함께 처리)"""
        product_url = str(request.product_url)
        max_reviews = request.max_reviews
        
        # URL 유효성 검증
        if not CrawlService.validate_url(product_url):
            return CrawlResponse(
                success=False,
                message="유효하지 않은 다나와 URL입니다.",
                reviews_found=0,
                product_id="invalid",
                error_message="유효하지 않은 다나와 URL입니다."
            )

        product_id = extract_product_id(product_url)

        try:
            # 1. 입력된 상품 리뷰 크롤링 (메인 작업)
            logger.info(f"🔍 메인 상품 리뷰 크롤링 시작: {product_url}")
            result = await asyncio.wait_for(
                crawl_danawa_reviews(product_url, max_reviews),
                timeout=600.0
            )
            
            # 크롤링 결과를 새로운 CrawlResponse 구조로 변환
            if result.get('success', False):
                reviews = result.get('reviews', [])
                review_count = len(reviews)
                
                crawl_response = CrawlResponse(
                    success=True,
                    message=f"리뷰 크롤링이 완료되었습니다. (총 {review_count}개)",
                    reviews_found=review_count,
                    product_id=product_id,
                    product_info={
                        "product_name": result.get('product_name'),
                        "product_image": result.get('product_image'),
                        "product_price": result.get('product_price'),
                        "product_brand": result.get('product_brand')
                    }
                )
                
                # AI 서비스에 리뷰 저장
                if reviews:
                    try:
                        product_info = {
                            "product_name": result.get('product_name'),
                            "product_image": result.get('product_image'),
                            "product_price": result.get('product_price'),
                            "product_brand": result.get('product_brand')
                        }

                        product_id_int = int(product_id) if product_id is not None else None
                        ai_result = self.ai_service.process_and_store_reviews(
                            reviews=reviews,
                            product_id=product_id_int,
                            product_info=product_info
                        )
                        logger.info(f"🤖 메인 상품 AI 저장 결과: {ai_result['message']}")
                    except Exception as ai_error:
                        logger.warning(f"⚠️ 메인 상품 AI 저장 실패 (크롤링은 성공): {ai_error}")
            else:
                crawl_response = CrawlResponse(
                    success=False,
                    message=result.get('error_message', '리뷰 크롤링에 실패했습니다.'),
                    reviews_found=0,
                    product_id=product_id,
                    error_message=result.get('error_message', '리뷰 크롤링에 실패했습니다.')
                )

            # 2. 백그라운드에서 특가 상품 리뷰 크롤링 트리거 (비동기로 실행)
            asyncio.create_task(self._trigger_special_deals_crawling())
            
            return crawl_response
            
        except asyncio.TimeoutError:
            return CrawlResponse(
                success=False,
                message="크롤링 시간 초과 (600초)",
                reviews_found=0,
                product_id=product_id,
                error_message="크롤링 시간 초과 (600초)"
            )
        except Exception as e:
            return CrawlResponse(
                success=False,
                message=f"크롤링 중 오류 발생: {str(e)}",
                reviews_found=0,
                product_id=product_id,
                error_message=f"크롤링 중 오류 발생: {str(e)}"
            )

    async def _trigger_special_deals_crawling(self):
        """백그라운드에서 특가 상품 리뷰 크롤링 실행"""
        try:
            logger.info("🏷️ 백그라운드 특가 상품 리뷰 크롤링 시작")

            # 특가 상품 목록 업데이트 (리뷰 포함)
            special_request = CrawlSpecialProductsRequest(
                max_products=6,  # 최대 6개 상품
                crawl_reviews=True,  # 리뷰도 함께 크롤링
                max_reviews_per_product=100  # 상품당 최대 100개 리뷰
            )

            # 특가 상품 크롤링 및 리뷰 수집
            special_result = await special_deals_service.crawl_and_save_special_deals(special_request)

            if special_result.success:
                logger.info(f"✅ 특가 상품 백그라운드 크롤링 완료: "
                          f"상품 {special_result.total_products}개, "
                          f"리뷰 있는 상품 {special_result.products_with_reviews}개, "
                          f"총 리뷰 {special_result.total_reviews}개")
            else:
                logger.warning(f"⚠️ 특가 상품 백그라운드 크롤링 실패: {special_result.error_message}")

        except Exception as e:
            logger.error(f"❌ 특가 상품 백그라운드 크롤링 오류: {e}")