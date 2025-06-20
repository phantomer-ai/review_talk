"""
통합 상품 관리 API 엔드포인트
"""
from fastapi import APIRouter, HTTPException, status, BackgroundTasks, Depends
from typing import Dict, Any, List, Optional

from app.services.crawl_product_review_service import CrawlProductReviewService
from app.services.special_deals_manage_service import SpecialDealsManageService
from app.infrastructure.product_repository import ProductRepository
from app.models.schemas import CrawlRequest

router = APIRouter(prefix="/api/v1/products", tags=["Products"])


def get_crawl_service() -> CrawlProductReviewService:
    """크롤링 서비스 의존성 주입"""
    return CrawlProductReviewService()


def get_special_deals_service() -> SpecialDealsManageService:
    """특가 상품 서비스 의존성 주입"""
    return SpecialDealsManageService()


def get_product_repository() -> ProductRepository:
    """상품 리포지토리 의존성 주입"""
    return ProductRepository()


@router.post("/crawl-reviews")
async def crawl_product_reviews(
    request: CrawlRequest,
    crawl_service: CrawlProductReviewService = Depends(get_crawl_service)
) -> Dict[str, Any]:
    """상품 리뷰 크롤링 (통합 버전)"""
    try:
        result = await crawl_service.crawl_product_reviews(request)
        
        if result.success:
            return {
                "success": True,
                "message": result.message,
                "product_id": result.product_id,
                "reviews_found": result.reviews_found,
                "product_info": result.product_info
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=result.message
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"크롤링 중 오류 발생: {str(e)}"
        )


@router.get("/{product_id}")
async def get_product(
    product_id: str,
    product_repo: ProductRepository = Depends(get_product_repository)
) -> Dict[str, Any]:
    """상품 정보 조회"""
    try:
        product = product_repo.get_product_by_id(product_id)
        
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="상품을 찾을 수 없습니다."
            )
        
        return {
            "success": True,
            "product": product
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"상품 조회 중 오류 발생: {str(e)}"
        )


@router.get("/")
async def get_products(
    limit: int = 10,
    special_only: bool = False,
    crawled_only: bool = True,
    product_repo: ProductRepository = Depends(get_product_repository)
) -> Dict[str, Any]:
    """상품 목록 조회"""
    try:
        if special_only:
            products = product_repo.get_special_products(limit, crawled_only)
        else:
            # 일반 상품 목록 조회 로직 (향후 구현)
            products = []
        
        return {
            "success": True,
            "products": products,
            "count": len(products)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"상품 목록 조회 중 오류 발생: {str(e)}"
        )


@router.get("/statistics/overview")
async def get_product_statistics(
    product_repo: ProductRepository = Depends(get_product_repository)
) -> Dict[str, Any]:
    """상품 통계 정보"""
    try:
        stats = product_repo.get_product_statistics()
        return {
            "success": True,
            "statistics": stats
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"통계 조회 중 오류 발생: {str(e)}"
        )


@router.post("/special-deals/discover")
async def discover_special_deals(
    background_tasks: BackgroundTasks,
    limit: int = 20,
    special_service: SpecialDealsManageService = Depends(get_special_deals_service)
) -> Dict[str, Any]:
    """특가 상품 발견 및 등록"""
    try:
        # 백그라운드에서 실행
        background_tasks.add_task(
            special_service.discover_and_register_special_deals, limit
        )
        
        return {
            "success": True,
            "message": f"특가 상품 발견 작업이 백그라운드에서 시작되었습니다. (최대 {limit}개)"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"특가 상품 발견 작업 시작 실패: {str(e)}"
        )


@router.post("/special-deals/crawl-reviews")
async def crawl_special_deals_reviews(
    background_tasks: BackgroundTasks,
    product_ids: Optional[List[str]] = None,
    max_reviews: int = 50,
    special_service: SpecialDealsManageService = Depends(get_special_deals_service)
) -> Dict[str, Any]:
    """특가 상품 리뷰 크롤링"""
    try:
        # 백그라운드에서 실행
        background_tasks.add_task(
            special_service.crawl_special_products_reviews, product_ids, max_reviews
        )
        
        message = "특가 상품 리뷰 크롤링이 백그라운드에서 시작되었습니다."
        if product_ids:
            message += f" (대상: {len(product_ids)}개 상품)"
        
        return {
            "success": True,
            "message": message
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"리뷰 크롤링 작업 시작 실패: {str(e)}"
        )


@router.get("/special-deals/")
async def get_special_deals(
    limit: int = 10,
    only_crawled: bool = True,
    special_service: SpecialDealsManageService = Depends(get_special_deals_service)
) -> Dict[str, Any]:
    """특가 상품 목록 조회"""
    try:
        products = special_service.get_special_products(limit, only_crawled)
        
        return {
            "success": True,
            "products": products,
            "count": len(products)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"특가 상품 목록 조회 실패: {str(e)}"
        )


@router.get("/special-deals/statistics")
async def get_special_deals_statistics(
    special_service: SpecialDealsManageService = Depends(get_special_deals_service)
) -> Dict[str, Any]:
    """특가 상품 통계"""
    try:
        stats = special_service.get_special_product_statistics()
        
        return {
            "success": True,
            "statistics": stats
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"특가 상품 통계 조회 실패: {str(e)}"
        )


@router.post("/special-deals/{product_id}/force-crawl")
async def force_crawl_special_product(
    product_id: str,
    max_reviews: int = 50,
    special_service: SpecialDealsManageService = Depends(get_special_deals_service)
) -> Dict[str, Any]:
    """특정 특가 상품 강제 크롤링"""
    try:
        result = await special_service.force_crawl_product(product_id, max_reviews)
        
        if result['success']:
            return {
                "success": True,
                "message": result['message'],
                "reviews_found": result.get('reviews_found', 0)
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=result['message']
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"강제 크롤링 실패: {str(e)}"
        )


@router.delete("/special-deals/{product_id}")
async def delete_special_product(
    product_id: str,
    special_service: SpecialDealsManageService = Depends(get_special_deals_service)
) -> Dict[str, Any]:
    """특가 상품 삭제"""
    try:
        success = special_service.delete_special_product(product_id)
        
        if success:
            return {
                "success": True,
                "message": "특가 상품이 삭제되었습니다."
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="삭제할 특가 상품을 찾을 수 없습니다."
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"특가 상품 삭제 실패: {str(e)}"
        )


@router.post("/special-deals/background-crawler/start")
async def start_background_crawler(
    interval_hours: int = 6,
    special_service: SpecialDealsManageService = Depends(get_special_deals_service)
) -> Dict[str, Any]:
    """백그라운드 특가 상품 크롤러 시작"""
    try:
        special_service.start_background_crawler(interval_hours)
        
        return {
            "success": True,
            "message": f"백그라운드 크롤러가 시작되었습니다. (간격: {interval_hours}시간)"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"백그라운드 크롤러 시작 실패: {str(e)}"
        )


@router.post("/special-deals/background-crawler/stop")
async def stop_background_crawler(
    special_service: SpecialDealsManageService = Depends(get_special_deals_service)
) -> Dict[str, Any]:
    """백그라운드 특가 상품 크롤러 중지"""
    try:
        special_service.stop_background_crawler()
        
        return {
            "success": True,
            "message": "백그라운드 크롤러가 중지되었습니다."
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"백그라운드 크롤러 중지 실패: {str(e)}"
        )