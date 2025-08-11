"""
다나와 오늘의 특가 페이지 크롤러
"""
import asyncio
import re
from typing import List, Optional, Dict, Any
from urllib.parse import urljoin

from playwright.async_api import async_playwright, Page, Browser
from loguru import logger

from app.models.schemas import SpecialProduct


class SpecialDealsCrawler:
    """다나와 오늘의 특가 페이지 크롤러"""
    
    def __init__(self):
        self.browser: Optional[Browser] = None
        self.page: Optional[Page] = None
        self.playwright = None
        self.base_url = "https://m.danawa.com"
        self.special_deals_url = "https://m.danawa.com/leftPanel/cmPick.html"
    
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
    
    async def crawl_special_deals(self, max_products: int = 50) -> List[SpecialProduct]:
        """다나와 오늘의 특가 상품 크롤링"""
        products = []
        
        try:
            logger.info(f"🚀 다나와 특가 페이지 접근: {self.special_deals_url}")
            
            # 특가 페이지로 이동
            await self.page.goto(self.special_deals_url, wait_until='domcontentloaded', timeout=60000)
            await asyncio.sleep(3)
            logger.info("✅ 특가 페이지 로드 완료")
            
            # 페이지 스크롤하여 콘텐츠 로드
            await self._scroll_to_load_content()
            
            # 특가 상품 목록 크롤링
            products = await self._extract_special_products(max_products)
            
            logger.info(f"🎉 총 {len(products)}개의 특가 상품을 수집했습니다!")
            
        except Exception as e:
            logger.error(f"❌ 특가 상품 크롤링 오류: {e}")
            
        return products
    
    async def _scroll_to_load_content(self):
        """스크롤하여 더 많은 콘텐츠 로드"""
        try:
            logger.info("📜 페이지 스크롤 중...")
            for i in range(5):  # 특가 상품이 많을 수 있으므로 더 많이 스크롤
                await self.page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                await asyncio.sleep(2)
            logger.info("✅ 스크롤 완료")
        except Exception as e:
            logger.error(f"❌ 스크롤 오류: {e}")
    
    async def _extract_special_products(self, max_products: int) -> List[SpecialProduct]:
        """특가 상품 정보 추출"""
        products = []
        
        try:
            # 특가 상품 컨테이너 선택자 (문서에서 제공된 경로 기반)
            container_selector = "#cmPick-category-container"
            
            # 컨테이너가 로드될 때까지 대기
            await self.page.wait_for_selector(container_selector, timeout=30000)
            
            # 특가 상품 아이템들 선택
            # 문서의 경로: #cmPick-category-item-42124 > div > a
            # 일반화된 선택자 사용
            item_selector = f"{container_selector} [id*='cmPick-category-item-'] > div > a"
            
            # 모든 특가 상품 링크 수집
            product_links = await self.page.query_selector_all(item_selector)
            logger.info(f"🔍 발견된 특가 상품 링크: {len(product_links)}개")
            
            # 최대 개수만큼 처리
            process_count = min(len(product_links), max_products)
            
            for i in range(process_count):
                try:
                    link = product_links[i]
                    
                    # 상품 정보 추출
                    product_info = await self._extract_product_info_from_link(link, i)
                    
                    if product_info:
                        products.append(product_info)
                        logger.info(f"✅ 상품 {i+1}/{process_count}: {product_info.product_name}")
                    
                    # 각 상품 처리 후 짧은 대기
                    await asyncio.sleep(0.5)
                    
                except Exception as e:
                    logger.error(f"❌ 상품 {i+1} 처리 오류: {e}")
                    continue
            
        except Exception as e:
            logger.error(f"❌ 특가 상품 추출 오류: {e}")
        
        return products
    
    async def _extract_product_info_from_link(self, link_element, index: int) -> Optional[SpecialProduct]:
        """개별 상품 링크에서 정보 추출"""
        try:
            # 상품 URL 추출
            product_url = await link_element.get_attribute('href')
            if not product_url:
                return None
            
            # 상대 경로를 절대 경로로 변환
            if product_url.startswith('/'):
                product_url = urljoin(self.base_url, product_url)
            
            # 상품 ID 추출 (URL에서)
            product_id = self._extract_product_id_from_url(product_url)
            if not product_id:
                product_id = f"special_{index}_{int(asyncio.get_event_loop().time())}"
            
            # 상품 이미지 URL 추출 (구체적인 선택자 사용)
            image_url = None
            img_element = await link_element.query_selector("div.box__thumbnail > img")
            if img_element:
                image_url = await img_element.get_attribute('src')
                if image_url and image_url.startswith('/'):
                    image_url = urljoin(self.base_url, image_url)
                elif image_url and image_url.startswith('//'):
                    image_url = f"https:{image_url}"
            
            # 상품명 추출 (구체적인 선택자 사용)
            product_name = None
            title_element = await link_element.query_selector("div.box__info > div.box__title")
            if title_element:
                product_name = await title_element.inner_text()
                product_name = product_name.strip() if product_name else None
            
            # 가격 정보 추출 (구체적인 선택자 사용)
            price_info = await self._extract_detailed_price_info(link_element)
            
            return SpecialProduct(
                product_id=product_id,
                product_name=product_name or f"특가상품 {index+1}",
                product_url=product_url,
                image_url=image_url,
                price=price_info.get('price'),
                original_price=price_info.get('original_price'),
                discount_rate=price_info.get('discount_rate'),
                brand=None,  # 특가 페이지에서는 브랜드 정보가 제한적
                category="특가상품",
                rating=None,
                review_count=0,
                is_crawled=False
            )
            
        except Exception as e:
            logger.error(f"❌ 상품 정보 추출 오류: {e}")
            return None
    
    def _extract_product_id_from_url(self, url: str) -> Optional[str]:
        """URL에서 상품 ID 추출"""
        try:
            # code 파라미터 추출
            code_match = re.search(r'[?&]code=([^&]+)', url)
            if code_match:
                return code_match.group(1)
            
            # pcode 파라미터 추출
            pcode_match = re.search(r'[?&]pcode=([^&]+)', url)
            if pcode_match:
                return pcode_match.group(1)
            
            # URL 경로에서 숫자 추출
            path_match = re.search(r'/(\d+)/?', url)
            if path_match:
                return path_match.group(1)
            
            return None
        except:
            return None
    
    async def _extract_text_from_element(self, element, description: str) -> Optional[str]:
        """요소에서 텍스트 추출"""
        try:
            text = await element.inner_text()
            return text.strip() if text else None
        except:
            return None
    
    async def _extract_price_info(self, element) -> Dict[str, Optional[str]]:
        """가격 정보 추출 (기존 방식)"""
        price_info = {
            'price': None,
            'original_price': None,
            'discount_rate': None
        }
        
        try:
            # 가격 관련 텍스트 추출 시도
            text_content = await element.inner_text()
            
            # 원 단위 가격 추출
            price_matches = re.findall(r'[\d,]+원', text_content)
            if price_matches:
                price_info['price'] = price_matches[0]
                if len(price_matches) > 1:
                    price_info['original_price'] = price_matches[1]
            
            # 할인율 추출
            discount_match = re.search(r'(\d+)%', text_content)
            if discount_match:
                price_info['discount_rate'] = f"{discount_match.group(1)}%"
                
        except Exception as e:
            logger.debug(f"가격 정보 추출 오류: {e}")
        
        return price_info
    
    async def _extract_detailed_price_info(self, element) -> Dict[str, Optional[str]]:
        """구체적인 선택자를 사용한 가격 정보 추출"""
        price_info = {
            'price': None,
            'original_price': None,
            'discount_rate': None
        }
        
        try:
            # 가격 컨테이너 찾기
            price_container = await element.query_selector("div.box__info > div.box__price")
            if not price_container:
                # 대체 방법으로 기존 방식 사용
                return await self._extract_price_info(element)
            
            # 가격 컨테이너 내의 모든 텍스트 가져오기
            price_text = await price_container.inner_text()
            
            # 할인율 추출
            discount_match = re.search(r'(\d+)%', price_text)
            if discount_match:
                price_info['discount_rate'] = f"{discount_match.group(1)}%"
            
            # 가격 정보 추출 (여러 패턴 시도)
            price_matches = re.findall(r'[\d,]+원', price_text)
            if price_matches:
                if len(price_matches) >= 2:
                    # 첫 번째가 할인 가격, 두 번째가 원래 가격인 경우가 많음
                    price_info['price'] = price_matches[0]
                    price_info['original_price'] = price_matches[1]
                else:
                    price_info['price'] = price_matches[0]
            
            # 더 구체적인 선택자로 시도
            if not price_info['price']:
                # 현재 가격 찾기
                current_price_elem = await price_container.query_selector("span.price, .price_current, .price-current")
                if current_price_elem:
                    current_price_text = await current_price_elem.inner_text()
                    price_match = re.search(r'([\d,]+원)', current_price_text)
                    if price_match:
                        price_info['price'] = price_match.group(1)
                
                # 원래 가격 찾기
                original_price_elem = await price_container.query_selector("span.price_origin, .price-origin, .original-price")
                if original_price_elem:
                    original_price_text = await original_price_elem.inner_text()
                    price_match = re.search(r'([\d,]+원)', original_price_text)
                    if price_match:
                        price_info['original_price'] = price_match.group(1)
                
        except Exception as e:
            logger.debug(f"상세 가격 정보 추출 오류: {e}")
            # 오류 발생시 기존 방식으로 대체
            return await self._extract_price_info(element)
        
        return price_info


async def crawl_special_deals(max_products: int = 50) -> List[SpecialProduct]:
    """다나와 특가 상품 크롤링 함수"""
    async with SpecialDealsCrawler() as crawler:
        return await crawler.crawl_special_deals(max_products) 