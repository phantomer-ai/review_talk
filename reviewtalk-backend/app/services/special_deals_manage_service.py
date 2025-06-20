"""
특가 상품 관리 서비스
특가 상품 검색, 등록, 크롤링 관리를 담당
"""
import asyncio
import schedule
import threading
import time
from typing import List, Dict, Any, Optional
from loguru import logger
from pydantic import HttpUrl

from app.infrastructure.crawler.special_deals_crawler import SpecialDealsCrawler
from app.infrastructure.product_repository import ProductRepository
from app.services.crawl_product_review_service import CrawlProductReviewService
from app.models.schemas import CrawlRequest


class SpecialDealsManageService:
    """특가 상품 관리 서비스"""
    
    def __init__(self):
        self.special_crawler = SpecialDealsCrawler()
        self.product_repository = ProductRepository()
        self.crawl_service = CrawlProductReviewService()
        self._scheduler_running = False
        self._scheduler_thread = None
    
    async def discover_and_register_special_deals(self, limit: int = 20) -> Dict[str, Any]:
        """특가 상품 발견 및 등록"""
        try:
            logger.info(f"특가 상품 발견 시작 (최대 {limit}개)")
            
            # 1. 특가 상품 크롤링
            special_products = await asyncio.to_thread(
                self.special_crawler.crawl_special_deals, limit
            )
            
            if not special_products:
                return {
                    'success': True,
                    'message': '새로운 특가 상품을 찾지 못했습니다.',
                    'discovered': 0,
                    'registered': 0
                }
            
            # 2. 새로운 특가 상품만 필터링
            new_products = self._filter_new_products(special_products)
            
            # 3. 특가 상품 등록
            registered_count = 0
            for product in new_products:
                if await self._register_special_product(product):
                    registered_count += 1
            
            logger.info(f"특가 상품 발견 완료: {len(special_products)}개 발견, {registered_count}개 등록")
            
            return {
                'success': True,
                'message': f'특가 상품 {registered_count}개가 등록되었습니다.',
                'discovered': len(special_products),
                'registered': registered_count,
                'products': new_products[:5]  # 처음 5개만 반환
            }
            
        except Exception as e:
            logger.error(f"특가 상품 발견 및 등록 실패: {e}")
            return {
                'success': False,
                'message': f'특가 상품 발견 실패: {str(e)}',
                'discovered': 0,
                'registered': 0
            }
    
    async def crawl_special_products_reviews(self, product_ids: List[str] = None, max_reviews: int = 50) -> Dict[str, Any]:
        """특가 상품 리뷰 크롤링"""
        try:
            # 크롤링할 특가 상품 목록 가져오기
            if product_ids:
                products = self.product_repository.get_products_by_ids(product_ids)
                products = [p for p in products if p.get('is_special')]
            else:
                # 크롤링되지 않은 특가 상품들 가져오기
                products = self._get_uncrawled_special_products()
            
            if not products:
                return {
                    'success': True,
                    'message': '크롤링할 특가 상품이 없습니다.',
                    'crawled': 0
                }
            
            logger.info(f"특가 상품 리뷰 크롤링 시작: {len(products)}개")
            
            crawled_count = 0
            crawl_results = []
            
            for product in products:
                try:
                    # CrawlRequest 생성 (is_special=True로 설정)
                    crawl_request = CrawlRequest(
                        product_url=HttpUrl(product['product_url']),
                        max_reviews=max_reviews,
                        is_special=True
                    )
                    
                    result = await self.crawl_service.crawl_product_reviews(crawl_request)
                    
                    crawl_results.append({
                        'product_id': product['product_id'],
                        'product_name': product.get('product_name'),
                        'success': result.success,
                        'reviews_found': result.reviews_found,
                        'message': result.message
                    })
                    
                    if result.success:
                        crawled_count += 1
                    
                    # 너무 빠른 요청 방지
                    await asyncio.sleep(2)
                    
                except Exception as e:
                    logger.error(f"특가 상품 {product['product_id']} 크롤링 실패: {e}")
                    crawl_results.append({
                        'product_id': product['product_id'],
                        'success': False,
                        'message': f'크롤링 실패: {str(e)}'
                    })
            
            logger.info(f"특가 상품 리뷰 크롤링 완료: {crawled_count}/{len(products)}개 성공")
            
            return {
                'success': True,
                'message': f'특가 상품 {crawled_count}개의 리뷰 크롤링이 완료되었습니다.',
                'crawled': crawled_count,
                'total': len(products),
                'results': crawl_results
            }
            
        except Exception as e:
            logger.error(f"특가 상품 리뷰 크롤링 실패: {e}")
            return {
                'success': False,
                'message': f'리뷰 크롤링 실패: {str(e)}',
                'crawled': 0
            }
    
    def get_special_products(self, limit: int = 10, only_crawled: bool = True) -> List[Dict[str, Any]]:
        """특가 상품 목록 조회"""
        return self.product_repository.get_special_products(limit, only_crawled)
    
    def get_special_product_statistics(self) -> Dict[str, Any]:
        """특가 상품 통계"""
        try:
            stats = self.product_repository.get_product_statistics()
            
            # 크롤링되지 않은 특가 상품 수 추가
            uncrawled_special = len(self._get_uncrawled_special_products())
            stats['uncrawled_special_products'] = uncrawled_special
            
            return stats
            
        except Exception as e:
            logger.error(f"특가 상품 통계 조회 실패: {e}")
            return {}
    
    def start_background_crawler(self, interval_hours: int = 6):
        """백그라운드 특가 상품 크롤러 시작"""
        if self._scheduler_running:
            logger.warning("백그라운드 크롤러가 이미 실행 중입니다.")
            return
        
        def run_scheduler():
            # 특가 상품 발견 스케줄링
            schedule.every(interval_hours).hours.do(self._background_discover_job)
            
            # 리뷰 크롤링 스케줄링 (발견 후 1시간 뒤)
            schedule.every(interval_hours).hours.do(self._background_crawl_job).tag('crawl')
            
            logger.info(f"백그라운드 특가 상품 크롤러 시작 (간격: {interval_hours}시간)")
            
            while self._scheduler_running:
                schedule.run_pending()
                time.sleep(60)  # 1분마다 체크
        
        self._scheduler_running = True
        self._scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
        self._scheduler_thread.start()
    
    def stop_background_crawler(self):
        """백그라운드 크롤러 중지"""
        self._scheduler_running = False
        schedule.clear()
        logger.info("백그라운드 특가 상품 크롤러 중지")
    
    def _filter_new_products(self, special_products: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """새로운 특가 상품만 필터링"""
        new_products = []
        
        for product in special_products:
            product_id = product.get('product_id')
            if product_id:
                existing = self.product_repository.get_product_by_id(product_id)
                if not existing:
                    new_products.append(product)
        
        return new_products
    
    async def _register_special_product(self, product_data: Dict[str, Any]) -> bool:
        """특가 상품 등록"""
        try:
            # 특가 상품 플래그 추가
            product_data['is_special'] = True
            product_data['is_crawled'] = False
            
            # 특가 상품 관련 추가 데이터
            special_data = {
                'discount_rate': product_data.get('discount_rate'),
                'original_price': product_data.get('original_price'),
                'special_type': product_data.get('special_type', 'deal'),
                'discovered_at': product_data.get('created_at')
            }
            product_data['special_data'] = special_data
            
            result = self.product_repository.create_or_update_product(product_data)
            return result is not None
            
        except Exception as e:
            logger.error(f"특가 상품 등록 실패: {e}")
            return False
    
    def _get_uncrawled_special_products(self) -> List[Dict[str, Any]]:
        """크롤링되지 않은 특가 상품 조회"""
        return self.product_repository.get_special_products(limit=100, only_crawled=False)
    
    def _background_discover_job(self):
        """백그라운드 특가 상품 발견 작업"""
        try:
            logger.info("백그라운드 특가 상품 발견 시작")
            
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            result = loop.run_until_complete(
                self.discover_and_register_special_deals(limit=30)
            )
            
            logger.info(f"백그라운드 특가 상품 발견 완료: {result}")
            
        except Exception as e:
            logger.error(f"백그라운드 특가 상품 발견 실패: {e}")
        finally:
            loop.close()
    
    def _background_crawl_job(self):
        """백그라운드 리뷰 크롤링 작업"""
        try:
            logger.info("백그라운드 특가 상품 리뷰 크롤링 시작")
            
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            result = loop.run_until_complete(
                self.crawl_special_products_reviews(max_reviews=30)
            )
            
            logger.info(f"백그라운드 리뷰 크롤링 완료: {result}")
            
        except Exception as e:
            logger.error(f"백그라운드 리뷰 크롤링 실패: {e}")
        finally:
            loop.close()
    
    async def force_crawl_product(self, product_id: str, max_reviews: int = 50) -> Dict[str, Any]:
        """특정 특가 상품 강제 크롤링"""
        try:
            product = self.product_repository.get_product_by_id(product_id)
            if not product:
                return {'success': False, 'message': '상품을 찾을 수 없습니다.'}
            
            if not product.get('is_special'):
                return {'success': False, 'message': '특가 상품이 아닙니다.'}
            
            # CrawlRequest 생성 (is_special=True로 설정)
            crawl_request = CrawlRequest(
                product_url=HttpUrl(product['product_url']),
                max_reviews=max_reviews,
                is_special=True
            )
            
            result = await self.crawl_service.crawl_product_reviews(crawl_request)
            
            return {
                'success': result.success,
                'message': result.message,
                'reviews_found': result.reviews_found
            }
            
        except Exception as e:
            logger.error(f"특가 상품 강제 크롤링 실패: {e}")
            return {'success': False, 'message': f'크롤링 실패: {str(e)}'}
    
    def delete_special_product(self, product_id: str) -> bool:
        """특가 상품 삭제"""
        try:
            product = self.product_repository.get_product_by_id(product_id)
            if product and product.get('is_special'):
                return self.product_repository.delete_product(product_id)
            return False
            
        except Exception as e:
            logger.error(f"특가 상품 삭제 실패: {e}")
            return False