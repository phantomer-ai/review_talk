import asyncio
import re
import time
from typing import List, Optional, Dict, Any
from urllib.parse import urlparse, parse_qs

from playwright.async_api import async_playwright, Page, Browser
from loguru import logger

from app.models.schemas import ReviewData


class DanawaCrawler:
    """모바일 다나와 크롤러 - Playwright 전용"""
    
    def __init__(self):
        self.browser: Optional[Browser] = None
        self.page: Optional[Page] = None
        self.playwright = None
    
    async def __aenter__(self):
        """비동기 컨텍스트 매니저 진입"""
        self.playwright = await async_playwright().start()
        self.browser = await self.playwright.chromium.launch(
            headless=True,
            args=[
                '--disable-dev-shm-usage', 
                '--no-sandbox', 
                '--disable-gpu',
                '--disable-web-security',
                '--disable-features=VizDisplayCompositor',
                '--user-agent=Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1'
            ]
        )
        
        context = await self.browser.new_context(
            viewport={'width': 375, 'height': 667},  # 모바일 뷰포트
            user_agent='Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1',
            extra_http_headers={
                'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
            }
        )
        
        self.page = await context.new_page()
        
        # 타임아웃 설정
        self.page.set_default_timeout(60000)  # 60초
        
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """비동기 컨텍스트 매니저 종료"""
        try:
            if self.page:
                await self.page.close()
            if self.browser:
                await self.browser.close()
            if self.playwright:
                await self.playwright.stop()
        except Exception as e:
            logger.error(f"브라우저 종료 오류: {e}")
    
    def extract_product_code(self, url: str) -> Optional[str]:
        """다나와 URL에서 상품 코드를 추출"""
        try:
            parsed = urlparse(str(url))
            if 'danawa.com' not in parsed.netloc:
                return None
            
            # URL에서 code 파라미터 추출 (모바일)
            query_params = parse_qs(parsed.query)
            if 'code' in query_params:
                return query_params['code'][0]
            
            # URL에서 pcode 파라미터 추출 (데스크톱)
            if 'pcode' in query_params:
                return query_params['pcode'][0]
            
            # URL 경로에서 상품 코드 추출 시도
            path_match = re.search(r'/(\d+)/?$', parsed.path)
            if path_match:
                return path_match.group(1)
                
            return None
        except Exception:
            return None
    
    async def crawl_reviews(self, product_url: str, max_reviews: int = 100) -> List[ReviewData]:
        """모바일 다나와 상품 리뷰 크롤링"""
        reviews = []

        try:
            logger.info(f"🚀 모바일 상품 페이지 접근: {product_url}")
            
            # 모바일 상품 페이지로 이동
            await self.page.goto(str(product_url), wait_until='domcontentloaded', timeout=60000)
            await asyncio.sleep(3)
            logger.info("✅ 모바일 상품 페이지 로드 완료")
            
            # 페이지 스크롤하여 콘텐츠 로드
            await self._scroll_to_load_content()
            
            # 리뷰 섹션으로 이동
            review_found = await self._navigate_to_mobile_reviews()
            
            if review_found:
                # 리뷰 더 보기 버튼 클릭
                await self._click_more_reviews_if_needed()
                
                # 리뷰 데이터 추출
                reviews = await self._extract_mobile_reviews(max_reviews)
            
            logger.info(f"🎉 총 {len(reviews)}개의 리뷰를 수집했습니다!")

        except Exception as e:
            logger.error(f"❌ 모바일 리뷰 크롤링 오류: {e}")

        return reviews
    
    async def _scroll_to_load_content(self):
        """스크롤하여 더 많은 콘텐츠 로드"""
        try:
            logger.info("📜 페이지 스크롤 중...")
            for i in range(3):
                await self.page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                await asyncio.sleep(2)
            logger.info("✅ 스크롤 완료")
        except Exception as e:
            logger.error(f"❌ 스크롤 오류: {e}")
    
    async def _navigate_to_mobile_reviews(self) -> bool:
        """모바일 사이트에서 리뷰 섹션으로 이동"""
        logger.info("🔍 모바일 리뷰 섹션 찾는 중...")
        
        # 사용자가 제공한 정확한 리뷰 버튼 셀렉터
        review_button_selector = "#productBlog-starsButton > div.text__review > span.text__number"
        
        try:
            # 리뷰 버튼 클릭
            review_button = await self.page.query_selector(review_button_selector)
            if review_button:
                logger.info(f"✅ 리뷰 버튼 발견!")
                await review_button.click()
                await asyncio.sleep(3)
                logger.info("✅ 리뷰 섹션으로 이동 완료")
                return True
            else:
                logger.error("❌ 리뷰 버튼을 찾을 수 없습니다.")
                return False
        except Exception as e:
            logger.error(f"❌ 리뷰 탭 클릭 실패: {e}")
            return False
    
    async def _click_more_reviews_if_needed(self):
        """리뷰 더 보기 버튼이 있으면 클릭"""
        logger.info("🔍 리뷰 더 보기 버튼 찾는 중...")
        
        # 사용자가 제공한 정확한 펼쳐보기 셀렉터
        more_button_selector = "#productBlog-opinion-mall-button-viewMore > span"
        
        try:
            more_button = await self.page.query_selector(more_button_selector)
            if more_button:
                logger.info(f"✅ 더보기 버튼 발견!")
                await more_button.click()
                await asyncio.sleep(3)
                logger.info("✅ 더 많은 리뷰 로드 완료")
        except Exception as e:
            logger.error(f"❌ 더보기 버튼 클릭 실패: {e}")
    
    async def _extract_mobile_reviews(self, max_reviews: int) -> List[ReviewData]:
        """모바일 페이지에서 리뷰 데이터 추출"""
        reviews = []
        
        logger.info("🔍 모바일 리뷰 데이터 추출 중...")
        
        try:
            # 리뷰 컨테이너들 찾기 (동적 ID 패턴)
            # 사용자 예시: #productBlog-opinion-mall-list-listItem-9123372001990022352 > div
            review_containers = await self.page.query_selector_all('[id*="productBlog-opinion-mall-list-listItem-"] > div')
            logger.info(f"📝 발견된 리뷰 컨테이너: {len(review_containers)}개")
            
            if not review_containers:
                logger.error("❌ 리뷰 컨테이너를 찾을 수 없습니다.")
                return reviews
            
            review_count = 0
            for i, container in enumerate(review_containers):
                if review_count >= max_reviews:
                    break
                
                try:
                    # 컨테이너의 ID에서 숫자 추출
                    container_id = await container.get_attribute('id')
                    if not container_id:
                        # 부모 요소의 ID에서 추출 시도
                        parent = await container.query_selector('xpath=..')
                        if parent:
                            container_id = await parent.get_attribute('id')
                    
                    if container_id and 'productBlog-opinion-mall-list-listItem-' in container_id:
                        # ID에서 숫자 부분 추출
                        review_id = container_id.replace('productBlog-opinion-mall-list-listItem-', '')
                        
                        # 해당 리뷰의 텍스트 찾기
                        # 사용자 예시: #productBlog-opinion-mall-list-content-9123372001990022352
                        text_selector = f"#productBlog-opinion-mall-list-content-{review_id}"
                        text_element = await self.page.query_selector(text_selector)
                        
                        # 별점 찾기 
                        # 사용자 예시: #productBlog-opinion-mall-list-listItem-9123372001865032107 > div > div > div:nth-child(1) > div > span > span
                        rating_selector = f"#productBlog-opinion-mall-list-listItem-{review_id} > div > div > div:nth-child(1) > div > span > span"
                        rating_element = await self.page.query_selector(rating_selector)
                        
                        # 리뷰 텍스트 추출
                        review_text = ""
                        if text_element:
                            review_text = await text_element.inner_text()
                            review_text = review_text.strip()
                        
                        # 별점 추출
                        rating = 0
                        if rating_element:
                            rating_text = await rating_element.inner_text()
                            # 별점 텍스트에서 숫자 추출 (예: "5점" -> 5)
                            rating_match = re.search(r'(\d+)', rating_text)
                            if rating_match:
                                rating = int(rating_match.group(1))
                        
                        if review_text and len(review_text) > 10:  # 의미있는 길이의 리뷰만
                            review_data = ReviewData(
                                review_id=review_id,
                                content=review_text,
                                rating=rating if rating > 0 else None,
                                author="익명",  # 모바일에서는 작성자 정보 제한적
                                date=None       # 날짜 정보 추출이 필요하면 별도 셀렉터 필요
                            )
                            reviews.append(review_data)
                            review_count += 1
                            logger.info(f"📝 리뷰 {review_count}: {review_text[:50]}..." + (f" (★{rating})" if rating > 0 else ""))
                    
                except Exception as e:
                    logger.error(f"❌ 리뷰 {i+1} 추출 오류: {e}")
                    continue
            
            logger.info(f"🎉 총 {len(reviews)}개의 모바일 리뷰 추출 완료!")
            
        except Exception as e:
            logger.error(f"❌ 모바일 리뷰 추출 중 오류: {e}")
        
        return reviews


async def crawl_danawa_reviews(product_url: str, max_reviews: int = 100) -> Dict[str, Any]:
    """다나와 리뷰 크롤링 메인 함수"""
    async with DanawaCrawler() as crawler:
        try:
            reviews = await crawler.crawl_reviews(product_url, max_reviews)
            
            product_code = crawler.extract_product_code(product_url)
            
            # CrawlResponse 스키마에 맞게 반환
            return {
                "success": True,
                "product_id": product_code or "unknown",
                "product_name": f"다나와 상품 ({product_code})" if product_code else "다나와 상품",
                "total_reviews": len(reviews),
                "reviews": reviews,  # ReviewData 객체들의 리스트
                "error_message": None
            }
            
        except Exception as e:
            logger.error(f"크롤링 전체 오류: {e}")
            return {
                "success": False,
                "product_id": "error", 
                "product_name": "Error",
                "total_reviews": 0,
                "reviews": [],
                "error_message": str(e)
            } 