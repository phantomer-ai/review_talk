import asyncio
from typing import Dict, Any
from urllib.parse import urlparse
from loguru import logger

from app.infrastructure.crawler.danawa_crawler import crawl_danawa_reviews
from app.models.schemas import CrawlRequest, CrawlResponse
from app.services.ai_service import AIService


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
            return (
                parsed.scheme in ['http', 'https'] and
                'danawa.com' in parsed.netloc
            )
        except Exception:
            return False
    
    async def crawl_product_reviews(self, request: CrawlRequest) -> CrawlResponse:
        """상품 리뷰 크롤링 메인 함수"""
        product_url = str(request.product_url)
        max_reviews = request.max_reviews
        
        # URL 유효성 검증
        if not CrawlService.validate_url(product_url):
            return CrawlResponse(
                success=False,
                product_id="invalid",
                product_name="Invalid URL",
                total_reviews=0,
                reviews=[],
                error_message="유효하지 않은 다나와 URL입니다."
            )
        
        try:
            # 크롤링 실행 (타임아웃 60초) 타임아웃 120초로 변경
            result = await asyncio.wait_for(
                crawl_danawa_reviews(product_url, max_reviews),
                timeout=600.0
            )
            
            # 크롤링 성공 시 AI 서비스에 리뷰 저장
            crawl_response = CrawlResponse(**result)
            if crawl_response.success and crawl_response.reviews:
                try:
                    ai_result = self.ai_service.process_and_store_reviews(
                        reviews=crawl_response.reviews,
                        product_url=product_url
                    )
                    logger.info(f"🤖 AI 저장 결과: {ai_result['message']}")
                except Exception as ai_error:
                    logger.warning(f"⚠️ AI 저장 실패 (크롤링은 성공): {ai_error}")
            
            return crawl_response
            
        except asyncio.TimeoutError:
            return CrawlResponse(
                success=False,
                product_id="timeout",
                product_name="Timeout",
                total_reviews=0,
                reviews=[],
                error_message="크롤링 시간 초과 (60초)"
            )
        except Exception as e:
            return CrawlResponse(
                success=False,
                product_id="error",
                product_name="Error",
                total_reviews=0,
                reviews=[],
                error_message=f"크롤링 중 오류 발생: {str(e)}"
            ) 