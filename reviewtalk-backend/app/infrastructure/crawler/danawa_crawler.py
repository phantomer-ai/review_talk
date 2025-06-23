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
                # 사용자가 설정한 개수만큼 리뷰 로드를 위해 더보기 버튼 반복 클릭
                await self._click_more_reviews_if_needed(max_reviews)
                
                # 리뷰 데이터 추출
                reviews = await self._extract_mobile_reviews(max_reviews)
            
            logger.info(f"🎉 총 {len(reviews)}개의 리뷰를 수집했습니다!")

        except Exception as e:
            logger.error(f"❌ 모바일 리뷰 크롤링 오류: {e}")

        return reviews
    
    async def extract_product_info(self, product_url: str) -> Dict[str, Optional[str]]:
        """다나와 상품 페이지에서 상품 정보 추출"""
        product_info = {
            'product_name': None,
            'image_url': None,
            'price': None,
            'brand': None
        }
        
        try:
            logger.info(f"🔍 상품 정보 추출 시작: {product_url}")
            
            # self.page가 None인지 확인
            if not self.page:
                logger.error("❌ 브라우저 페이지가 초기화되지 않았습니다.")
                return product_info
            
            # 상품 페이지로 이동 (아직 안했다면)
            current_url = self.page.url
            if current_url != product_url:
                await self.page.goto(str(product_url), wait_until='domcontentloaded', timeout=60000)
                await asyncio.sleep(3)
            
            # 페이지 스크롤하여 모든 콘텐츠 로드
            await self._scroll_to_load_content()
            
            # 상품명 추출 - 사용자 제공 정확한 선택자
            product_name_selectors = [
                "#productBlog-productName",  # 사용자 제공 정확한 선택자
                ".product_title",  # 백업 선택자
                ".product-title",
                ".prod_name",
                ".item_name",
                ".product_name",
                "h1.title",
                "h1.product-title",
                ".title_area h1",
                ".prod_info h1",
                "h1",  # 마지막 대안
                ".item_title"
            ]
            
            for selector in product_name_selectors:
                try:
                    logger.debug(f"🔍 상품명 선택자 시도: {selector}")
                    element = await self.page.query_selector(selector)
                    if element:
                        product_name = await element.inner_text()
                        logger.debug(f"📝 추출된 텍스트: {product_name}")
                        if product_name and len(product_name.strip()) > 0:
                            product_info['product_name'] = product_name.strip()
                            logger.info(f"✅ 상품명 추출 성공: {product_name[:50]}...")
                            break
                    else:
                        logger.debug(f"❌ 선택자 {selector}로 요소를 찾을 수 없음")
                except Exception as e:
                    logger.debug(f"❌ 선택자 {selector} 오류: {e}")
                    continue
            
            # 상품 이미지 추출 - 사용자 제공 정확한 선택자
            image_selectors = [
                "#productBlog-image-item-0 > span > img",  # 사용자 제공 정확한 선택자
                "#productBlog-image-item-1 > span > img",  # 두 번째 이미지
                "#productBlog-image-item-2 > span > img",  # 세 번째 이미지
                ".thumb_area img",  # 백업 선택자
                ".product_img img",
                ".item_img img", 
                ".prod_img img",
                ".product_image img",
                ".main_image img",
                ".swiper-slide img",  # 다나와에서 자주 사용하는 슬라이더
                ".thumb_list img",
                ".gallery img",
                "img[src*='danawa']",  # 다나와 이미지 서버
                "img[alt*='상품']",
                "img[alt*='제품']",
                "img[data-src*='danawa']",  # 지연 로딩 이미지
                "img"  # 마지막 대안
            ]
            
            for selector in image_selectors:
                try:
                    logger.debug(f"🔍 이미지 선택자 시도: {selector}")
                    element = await self.page.query_selector(selector)
                    if element:
                        src = await element.get_attribute('src')
                        data_src = await element.get_attribute('data-src')
                        alt = await element.get_attribute('alt')
                        logger.debug(f"📷 src: {src}, data-src: {data_src}")
                        
                        # src 또는 data-src 중 유효한 것 사용
                        image_url = src or data_src
                        
                        # 유효한 이미지 URL인지 확인
                        if image_url and ('jpg' in image_url.lower() or 'jpeg' in image_url.lower() or 'png' in image_url.lower() or 'webp' in image_url.lower()):
                            # 상대 경로를 절대 경로로 변환
                            if image_url.startswith('/'):
                                image_url = f"https://img.danawa.com{image_url}"
                            elif image_url.startswith('//'):
                                image_url = f"https:{image_url}"
                            
                            product_info['image_url'] = image_url
                            logger.info(f"✅ 상품 이미지 추출 성공: {image_url}")
                            break
                    else:
                        logger.debug(f"❌ 선택자 {selector}로 요소를 찾을 수 없음")
                except Exception as e:
                    logger.debug(f"❌ 선택자 {selector} 오류: {e}")
                    continue
            
            # 가격 정보 추출 (선택사항)
            price_selectors = [
                ".price_real",
                ".price_current",
                ".price",
                "[class*='price']",
                ".price_info .price"
            ]
            
            for selector in price_selectors:
                try:
                    element = await self.page.query_selector(selector)
                    if element:
                        price_text = await element.inner_text()
                        if price_text and '원' in price_text:
                            product_info['price'] = price_text.strip()
                            logger.info(f"✅ 가격 정보 추출: {price_text}")
                            break
                except:
                    continue
            
            # 브랜드 정보 추출 (선택사항)
            brand_selectors = [
                ".brand_name",
                ".brand",
                "[class*='brand']",
                ".manufacturer"
            ]
            
            for selector in brand_selectors:
                try:
                    element = await self.page.query_selector(selector)
                    if element:
                        brand_text = await element.inner_text()
                        if brand_text and len(brand_text.strip()) > 0:
                            product_info['brand'] = brand_text.strip()
                            logger.info(f"✅ 브랜드 정보 추출: {brand_text}")
                            break
                except:
                    continue
            
        except Exception as e:
            logger.error(f"❌ 상품 정보 추출 오류: {e}")
        
        return product_info
    
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
    
    async def _click_more_reviews_if_needed(self, target_reviews: int):
        """사용자가 설정한 개수만큼 리뷰를 로드하기 위해 더보기 버튼을 반복 클릭"""
        logger.info(f"🔍 목표 {target_reviews}개 리뷰 로드를 위한 더보기 버튼 클릭 시작...")
        
        # 사용자가 제공한 정확한 펼쳐보기 셀렉터
        more_button_selector = "#productBlog-opinion-mall-button-viewMore > span"
        
        # 기본적으로 30개 정도 보이므로, 추가로 필요한 만큼 더보기 클릭
        # 한 번 클릭할 때마다 약 30-50개씩 추가 로드됨
        estimated_clicks = max(1, (target_reviews - 30) // 30)
        max_clicks = min(estimated_clicks + 2, 20)  # 최대 20번까지만 클릭 (안전장치)
        
        logger.info(f"📊 예상 더보기 클릭 횟수: {estimated_clicks}, 최대 클릭 횟수: {max_clicks}")
        
        click_count = 0
        for i in range(max_clicks):
            try:
                more_button = await self.page.query_selector(more_button_selector)
                if more_button:
                    # 버튼이 보이는지 확인
                    is_visible = await more_button.is_visible()
                    if is_visible:
                        logger.info(f"✅ 더보기 버튼 {i+1}번째 클릭!")
                        await more_button.click()
                        click_count += 1
                        await asyncio.sleep(3)  # 로딩 대기
                        
                        # 현재 로드된 리뷰 개수 확인
                        current_reviews = await self.page.query_selector_all('[id*="productBlog-opinion-mall-list-listItem-"]')
                        current_count = len(current_reviews)
                        logger.info(f"📝 현재 로드된 리뷰: {current_count}개")
                        
                        # 목표 개수에 도달했으면 중단
                        if current_count >= target_reviews:
                            logger.info(f"🎯 목표 개수({target_reviews})에 도달! 더보기 클릭 중단")
                            break
                    else:
                        logger.info("🔚 더보기 버튼이 보이지 않음 - 모든 리뷰 로드 완료")
                        break
                else:
                    logger.info("🔚 더보기 버튼을 찾을 수 없음 - 모든 리뷰 로드 완료")
                    break
                    
            except Exception as e:
                logger.error(f"❌ 더보기 버튼 {i+1}번째 클릭 실패: {e}")
                break
        
        logger.info(f"🎉 총 {click_count}번의 더보기 클릭 완료")
    
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
            # 1. 상품 정보 먼저 추출
            logger.info("🔍 상품 정보 추출 중...")
            product_info = await crawler.extract_product_info(product_url)
            
            # 2. 리뷰 크롤링
            logger.info("📝 리뷰 크롤링 시작...")
            reviews = await crawler.crawl_reviews(product_url, max_reviews)
            
            product_code = crawler.extract_product_code(product_url)
            
            # 추출된 상품 정보 사용
            product_name = product_info.get('product_name')
            if not product_name:
                product_name = f"다나와 상품 ({product_code})" if product_code else "다나와 상품"
            
            # CrawlResponse 스키마에 맞게 반환 (상품 정보 포함)
            return {
                "success": True,
                "product_id": product_code or "unknown",
                "product_name": product_name,
                "product_image": product_info.get('image_url'),  # 이미지 URL 추가
                "product_price": product_info.get('price'),      # 가격 정보 추가
                "product_brand": product_info.get('brand'),      # 브랜드 정보 추가
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
                "product_image": None,
                "product_price": None,
                "product_brand": None,
                "total_reviews": 0,
                "reviews": [],
                "error_message": str(e)
            } 