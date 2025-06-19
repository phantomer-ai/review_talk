"""
자동 크롤링 스케줄러 - 매일 특가 상품 크롤링
"""
import asyncio
import schedule
import time
from datetime import datetime
from threading import Thread

from loguru import logger
from app.models.schemas import CrawlSpecialProductsRequest
from app.services.special_deals_service import special_deals_service


class CrawlingScheduler:
    """자동 크롤링 스케줄러"""
    
    def __init__(self):
        self.is_running = False
        self.scheduler_thread = None
    
    async def daily_special_deals_crawling(self):
        """매일 실행되는 특가 상품 크롤링 작업"""
        logger.info("🕐 [스케줄러] 일일 특가 상품 크롤링 시작")
        
        try:
            # 1. 특가 상품 목록 크롤링 (리뷰도 함께 수집)
            request = CrawlSpecialProductsRequest(
                max_products=50,
                crawl_reviews=True,  # 리뷰도 함께 크롤링으로 변경
                max_reviews_per_product=100
            )
            
            result = await special_deals_service.crawl_and_save_special_deals(request)
            
            if result.success:
                logger.info(f"✅ [스케줄러] 특가 상품 {result.total_products}개 수집 완료")
                
                # 2. 기존 미크롤링 상품들의 리뷰 배치 처리
                batch_result = await special_deals_service.process_uncrawled_products(batch_size=10)
                
                if batch_result.get("success"):
                    logger.info(f"✅ [스케줄러] 배치 처리 완료: {batch_result.get('processed_count', 0)}개 상품")
                else:
                    logger.warning(f"⚠️ [스케줄러] 배치 처리 실패: {batch_result.get('error_message', '알 수 없는 오류')}")
                
                # 3. 오래된 데이터 정리 (7일 이전)
                cleanup_result = special_deals_service.cleanup_old_products(days=7)
                if cleanup_result.get("success"):
                    logger.info(f"✅ [스케줄러] 오래된 데이터 정리: {cleanup_result.get('deleted_count', 0)}개 삭제")
                
            else:
                logger.error(f"❌ [스케줄러] 특가 상품 크롤링 실패: {result.error_message}")
                
        except Exception as e:
            logger.error(f"❌ [스케줄러] 일일 크롤링 작업 오류: {e}")
        
        logger.info("🏁 [스케줄러] 일일 특가 상품 크롤링 완료")
    
    async def background_review_crawling(self):
        """백그라운드에서 실행되는 리뷰 크롤링 작업 (2시간마다)"""
        logger.info("🔄 [스케줄러] 백그라운드 리뷰 크롤링 시작")
        
        try:
            # 미크롤링 상품들의 리뷰를 소량씩 처리
            batch_result = await special_deals_service.process_uncrawled_products(batch_size=5)
            
            if batch_result.get("success"):
                processed = batch_result.get('processed_count', 0)
                if processed > 0:
                    logger.info(f"✅ [스케줄러] 백그라운드 처리 완료: {processed}개 상품")
                else:
                    logger.info("ℹ️ [스케줄러] 처리할 미크롤링 상품 없음")
            else:
                logger.warning(f"⚠️ [스케줄러] 백그라운드 처리 실패: {batch_result.get('error_message', '알 수 없는 오류')}")
                
        except Exception as e:
            logger.error(f"❌ [스케줄러] 백그라운드 리뷰 크롤링 오류: {e}")
        
        logger.info("🏁 [스케줄러] 백그라운드 리뷰 크롤링 완료")
    
    def schedule_daily_jobs(self):
        """일일 작업 스케줄 설정"""
        # 매일 오전 9시에 특가 상품 크롤링 (리뷰 포함)
        schedule.every().day.at("09:00").do(self._run_async_job, self.daily_special_deals_crawling)
        

        logger.info("📅 [스케줄러] 작업 스케줄 설정 완료")
        logger.info("   - 매일 09:00: 특가 상품 크롤링 (리뷰 포함)")

    def _run_async_job(self, async_func):
        """비동기 함수를 동기 스케줄러에서 실행"""
        try:
            # 새로운 이벤트 루프에서 실행
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.run_until_complete(async_func())
            loop.close()
        except Exception as e:
            logger.error(f"❌ [스케줄러] 비동기 작업 실행 오류: {e}")
    
    def start_scheduler(self):
        """스케줄러 시작"""
        if self.is_running:
            logger.warning("⚠️ [스케줄러] 이미 실행 중입니다")
            return
        
        self.is_running = True
        self.schedule_daily_jobs()
        
        def run_scheduler():
            logger.info("🚀 [스케줄러] 시작됨")
            while self.is_running:
                try:
                    schedule.run_pending()
                    time.sleep(60)  # 1분마다 체크
                except Exception as e:
                    logger.error(f"❌ [스케줄러] 실행 오류: {e}")
                    time.sleep(60)
            logger.info("🛑 [스케줄러] 종료됨")
        
        self.scheduler_thread = Thread(target=run_scheduler, daemon=True)
        self.scheduler_thread.start()
        
        logger.info("✅ [스케줄러] 백그라운드에서 시작되었습니다")
    
    def stop_scheduler(self):
        """스케줄러 중지"""
        if not self.is_running:
            logger.warning("⚠️ [스케줄러] 실행 중이 아닙니다")
            return
        
        self.is_running = False
        schedule.clear()
        
        if self.scheduler_thread and self.scheduler_thread.is_alive():
            self.scheduler_thread.join(timeout=5)
        
        logger.info("🛑 [스케줄러] 중지되었습니다")
    
    def get_scheduler_status(self):
        """스케줄러 상태 조회"""
        next_runs = []
        for job in schedule.get_jobs():
            next_runs.append({
                "job": str(job.job_func),
                "next_run": job.next_run.strftime("%Y-%m-%d %H:%M:%S") if job.next_run else None
            })
        
        return {
            "is_running": self.is_running,
            "scheduled_jobs": len(schedule.get_jobs()),
            "next_runs": next_runs
        }


# 전역 스케줄러 인스턴스
crawler_scheduler = CrawlingScheduler()


def init_scheduler():
    """애플리케이션 시작시 스케줄러 초기화"""
    try:
        crawler_scheduler.start_scheduler()
        logger.info("✅ 자동 크롤링 스케줄러가 초기화되었습니다")
    except Exception as e:
        logger.error(f"❌ 스케줄러 초기화 실패: {e}")


def shutdown_scheduler():
    """애플리케이션 종료시 스케줄러 정리"""
    try:
        crawler_scheduler.stop_scheduler()
        logger.info("✅ 자동 크롤링 스케줄러가 종료되었습니다")
    except Exception as e:
        logger.error(f"❌ 스케줄러 종료 실패: {e}") 