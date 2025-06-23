"""
통합 상품 관리 API 엔드포인트
"""
from fastapi import APIRouter, HTTPException, status, BackgroundTasks, Depends, Query
from typing import Dict, Any, List, Optional
from pydantic import BaseModel
from loguru import logger

from app.services.crawl_product_review_service import CrawlProductReviewService
from app.services.special_deals_manage_service import SpecialDealsManageService
from app.infrastructure.unified_product_repository import unified_product_repository
from app.infrastructure.chat_room_repository import ChatRoomRepository
from app.models.schemas import CrawlRequest


class Product(BaseModel):
    """상품 정보 스키마"""
    id: Optional[int] = None
    product_id: str
    product_name: str
    product_url: str
    image_url: Optional[str] = None
    price: Optional[str] = None
    original_price: Optional[str] = None
    discount_rate: Optional[str] = None
    brand: Optional[str] = None
    category: Optional[str] = None
    rating: Optional[float] = None
    review_count: int = 0
    is_crawled: bool = False
    is_special: bool = False
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class ProductStatistics(BaseModel):
    """상품 통계 스키마"""
    total_products: int
    crawled_products: int
    special_products: int
    regular_products: int


router = APIRouter(prefix="/api/v1/products", tags=["Products"])


def get_crawl_service() -> CrawlProductReviewService:
    """크롤링 서비스 의존성 주입"""
    return CrawlProductReviewService()


def get_special_deals_service() -> SpecialDealsManageService:
    """특가 상품 서비스 의존성 주입"""
    return SpecialDealsManageService()


def get_chat_room_repository() -> ChatRoomRepository:
    """채팅방 리포지토리 의존성 주입"""
    return ChatRoomRepository()


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
    product_id: str
) -> Dict[str, Any]:
    """상품 정보 조회"""
    try:
        product = unified_product_repository.get_product_by_id(product_id)
        
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
async def get_user_products(
    user_id: str = Query(..., description="사용자 ID"),
    chat_room_repo: ChatRoomRepository = Depends(get_chat_room_repository)
) -> Dict[str, Any]:
    """사용자의 채팅방 기반 상품 목록 조회"""
    try:
        logger.info(f"사용자 {user_id}의 상품 목록 조회 시작")
        
        
        # 1. 사용자의 채팅방에서 사용된 product_id 목록 조회
        product_ids = chat_room_repo.get_product_ids_by_user(user_id)
        
        if not product_ids:
            logger.info(f"사용자 {user_id}의 채팅방이 없습니다")
            return {
                "success": True,
                "products": [],
                "count": 0,
                "message": "아직 채팅한 상품이 없습니다"
            }
        
        logger.info(f"사용자 {user_id}의 product_id 목록: {product_ids}")
        
        # 2. product_id 목록으로 상품 정보 조회
        products = unified_product_repository.get_products_by_ids(product_ids)
        
        logger.info(f"조회된 상품 수: {len(products)}")
        
        return {
            "success": True,
            "products": products,
            "count": len(products),
            "user_id": user_id
        }
        
    except Exception as e:
        logger.error(f"사용자 상품 목록 조회 중 오류 발생: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"상품 목록 조회 중 오류 발생: {str(e)}"
        )


@router.get("/list")
async def get_products_list(
    limit: int = 10,
    special_only: bool = False,
    crawled_only: bool = True
) -> Dict[str, Any]:
    """전체 상품 목록 조회 (기존 기능)"""
    try:
        if special_only:
            products = unified_product_repository.get_special_products(limit, crawled_only)
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
async def get_product_statistics() -> Dict[str, Any]:
    """상품 통계 정보"""
    try:
        stats = unified_product_repository.get_product_statistics()
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