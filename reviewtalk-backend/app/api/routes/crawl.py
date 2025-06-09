from fastapi import APIRouter, HTTPException, status, Depends
from app.models.schemas import CrawlRequest, CrawlResponse
from app.services.crawl_service import CrawlService

router = APIRouter(prefix="/api/v1", tags=["크롤링"])


def get_crawl_service() -> CrawlService:
    """크롤 서비스 의존성 주입"""
    return CrawlService()


@router.post("/crawl-reviews", response_model=CrawlResponse)
async def crawl_product_reviews(
    request: CrawlRequest,
    crawl_service: CrawlService = Depends(get_crawl_service)
) -> CrawlResponse:
    """
    다나와 상품 리뷰 크롤링
    
    - **product_url**: 다나와 상품 URL (예: https://prod.danawa.com/info/?pcode=123456)
    - **max_reviews**: 수집할 최대 리뷰 수 (1-100, 기본값: 20)
    
    실제 다나와 사이트에서 리뷰를 크롤링하여 구조화된 데이터로 반환합니다.
    """
    try:
        result = await crawl_service.crawl_product_reviews(request)
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"크롤링 중 서버 오류가 발생했습니다: {str(e)}"
        ) 