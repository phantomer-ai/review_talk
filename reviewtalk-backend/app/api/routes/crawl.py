from fastapi import APIRouter, HTTPException, status, Depends, Request
from app.models.schemas import CrawlRequest, CrawlResponse
from app.services.crawl_service import CrawlService
from loguru import logger

router = APIRouter(prefix="/api/v1", tags=["크롤링"])


def get_crawl_service() -> CrawlService:
    """크롤 서비스 의존성 주입"""
    return CrawlService()


def _validate_crawl_request(request: CrawlRequest):
    errors = []
    # product_url 필수 및 타입 체크
    if not request.product_url:
        errors.append("required parameter - product_url : [Null]")
    # max_reviews 유효성 체크
    if request.max_reviews is None:
        errors.append("required parameter - max_reviews : [Null]")
    elif not (1 <= request.max_reviews <= 1000):
        errors.append(f"invalid parameter - max_reviews : [{request.max_reviews}]")
    return errors


@router.post("/crawl-reviews", response_model=CrawlResponse)
async def crawl_product_reviews(
    request: CrawlRequest,
    crawl_service: CrawlService = Depends(get_crawl_service),
    raw_request: Request = None
) -> CrawlResponse:
    """
    다나와 상품 리뷰 크롤링
    
    - **product_url**: 다나와 상품 URL (예: https://prod.danawa.com/info/?pcode=123456)
    - **max_reviews**: 수집할 최대 리뷰 수 (1-1000, 기본값: 20)
    
    실제 다나와 사이트에서 리뷰를 크롤링하여 구조화된 데이터로 반환합니다.
    """
    # OPTIONS (CORS preflight) 요청 로깅
    if raw_request and raw_request.method == "OPTIONS":
        logger.warning(f"CORS Preflight(OPTIONS) 요청: headers={dict(raw_request.headers)}")
        
    # 파라미터 유효성 검증 및 상세 로깅
    errors = _validate_crawl_request(request)
    if errors:
        logger.error(f"400 Bad Request 발생 | 전달값: product_url={getattr(request, 'product_url', None)}, max_reviews={getattr(request, 'max_reviews', None)} | errors={errors}")
        if raw_request:
            logger.error(f"Request headers: {dict(raw_request.headers)}")
            try:
                body = await raw_request.body()
                logger.error(f"Request body: {body}")
            except Exception as e:
                logger.error(f"Request body 파싱 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid or missing parameters: {errors}"
        )
    try:
        result = await crawl_service.crawl_product_reviews(request)
        return result
    except Exception as e:
        logger.error(f"Exception: {str(e)} | 전달값: product_url={getattr(request, 'product_url', None)}, max_reviews={getattr(request, 'max_reviews', None)}")
        if raw_request:
            logger.error(f"Request headers: {dict(raw_request.headers)}")
            try:
                body = await raw_request.body()
                logger.error(f"Request body: {body}")
            except Exception as e:
                logger.error(f"Request body 파싱 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"크롤링 중 서버 오류가 발생했습니다: {str(e)}"
        ) 