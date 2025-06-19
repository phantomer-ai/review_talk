"""
특가 상품 관련 API 엔드포인트
"""
from fastapi import APIRouter, HTTPException, status, Depends, Query, BackgroundTasks
from fastapi.responses import Response
from typing import Optional
import httpx

from app.models.schemas import (
    SpecialProductsResponse,
    CrawlSpecialProductsRequest,
    CrawlSpecialProductsResponse,
    SpecialProduct
)
from app.services.special_deals_service import special_deals_service

router = APIRouter(prefix="/api/v1", tags=["특가상품"])


def get_special_deals_service():
    """특가 상품 서비스 의존성 주입"""
    return special_deals_service


@router.get("/special-deals/image-proxy")
async def get_image_proxy(
    url: str = Query(..., description="프록시할 이미지 URL")
):
    """
    다나와 이미지 프록시 엔드포인트
    
    다나와 이미지 서버의 핫링킹 차단을 우회하여 이미지를 제공합니다.
    """
    try:
        # URL 유효성 검사
        if not url.startswith('https://img.danawa.com/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="다나와 이미지 URL만 허용됩니다."
            )
        
        # 다나와 서버에서 이미지 가져오기
        headers = {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1',
            'Referer': 'https://m.danawa.com/',
            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
            'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers, timeout=10.0)
            
            if response.status_code == 200:
                # 이미지 데이터와 컨텐츠 타입 반환
                content_type = response.headers.get('content-type', 'image/jpeg')
                return Response(
                    content=response.content,
                    media_type=content_type,
                    headers={
                        'Cache-Control': 'public, max-age=3600',  # 1시간 캐시
                        'Access-Control-Allow-Origin': '*',  # CORS 허용
                    }
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"이미지를 가져올 수 없습니다. 상태코드: {response.status_code}"
                )
                
    except httpx.TimeoutException:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="이미지 서버 응답 시간 초과"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"이미지 프록시 오류: {str(e)}"
        )


@router.post("/special-deals/crawl", response_model=CrawlSpecialProductsResponse)
async def crawl_special_deals(
    request: CrawlSpecialProductsRequest,
    service = Depends(get_special_deals_service)
) -> CrawlSpecialProductsResponse:
    """
    다나와 오늘의 특가 상품 크롤링
    
    - **max_products**: 수집할 최대 특가 상품 수 (1-100, 기본값: 50)
    - **crawl_reviews**: 각 상품의 리뷰도 함께 크롤링할지 여부 (기본값: True)
    - **max_reviews_per_product**: 상품당 수집할 최대 리뷰 수 (1-500, 기본값: 100)
    
    오늘의 특가 페이지에서 상품 목록을 크롤링하고, 옵션에 따라 각 상품의 리뷰도 수집합니다.
    """
    try:
        result = await service.crawl_and_save_special_deals(request)
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"특가 상품 크롤링 중 서버 오류가 발생했습니다: {str(e)}"
        )


@router.get("/special-deals", response_model=SpecialProductsResponse)
def get_special_deals(
    limit: int = Query(50, ge=1, le=100, description="조회할 상품 수"),
    offset: int = Query(0, ge=0, description="조회 시작 위치"),
    service = Depends(get_special_deals_service)
) -> SpecialProductsResponse:
    """
    저장된 특가 상품 목록 조회
    
    - **limit**: 조회할 상품 수 (1-100, 기본값: 50)
    - **offset**: 조회 시작 위치 (기본값: 0)
    
    데이터베이스에 저장된 특가 상품 목록을 페이지네이션으로 조회합니다.
    """
    try:
        result = service.get_special_products(limit, offset)
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"특가 상품 조회 중 서버 오류가 발생했습니다: {str(e)}"
        )


@router.get("/special-deals/{product_id}", response_model=SpecialProduct)
def get_special_deal_by_id(
    product_id: str,
    service = Depends(get_special_deals_service)
) -> SpecialProduct:
    """
    특정 특가 상품 상세 조회
    
    - **product_id**: 조회할 상품의 고유 ID
    
    특정 특가 상품의 상세 정보를 조회합니다.
    """
    try:
        product = service.get_special_product_by_id(product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"상품 ID '{product_id}'를 찾을 수 없습니다."
            )
        return product
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"특가 상품 조회 중 서버 오류가 발생했습니다: {str(e)}"
        )


@router.post("/special-deals/process-uncrawled")
async def process_uncrawled_products(
    background_tasks: BackgroundTasks,
    batch_size: int = Query(5, ge=1, le=20, description="배치 처리할 상품 수"),
    service = Depends(get_special_deals_service)
):
    """
    아직 리뷰가 크롤링되지 않은 특가 상품들을 백그라운드에서 처리
    
    - **batch_size**: 한 번에 처리할 상품 수 (1-20, 기본값: 5)
    
    리뷰 크롤링이 완료되지 않은 특가 상품들의 리뷰를 백그라운드에서 수집합니다.
    """
    try:
        # 백그라운드 태스크로 실행
        background_tasks.add_task(service.process_uncrawled_products, batch_size)
        
        return {
            "success": True,
            "message": f"미크롤링 상품 배치 처리를 백그라운드에서 시작했습니다. (배치 크기: {batch_size})"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"배치 처리 시작 중 오류가 발생했습니다: {str(e)}"
        )


@router.delete("/special-deals/cleanup")
def cleanup_old_special_deals(
    days: int = Query(7, ge=1, le=30, description="삭제할 데이터의 일수"),
    service = Depends(get_special_deals_service)
):
    """
    오래된 특가 상품 데이터 정리
    
    - **days**: 삭제할 데이터의 일수 (1-30, 기본값: 7)
    
    지정된 일수보다 오래된 특가 상품 데이터를 삭제합니다.
    """
    try:
        result = service.cleanup_old_products(days)
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"데이터 정리 중 서버 오류가 발생했습니다: {str(e)}"
        )


@router.get("/special-deals/stats/summary")
def get_special_deals_stats(
    service = Depends(get_special_deals_service)
):
    """
    특가 상품 통계 요약
    
    전체 특가 상품 수, 리뷰 크롤링 완료 상품 수 등의 통계를 제공합니다.
    """
    try:
        # 전체 상품 수
        total_products = service.repository.get_total_count()
        
        # 크롤링 완료된 상품들
        crawled_products = service.repository.get_special_products(limit=1000)
        crawled_count = sum(1 for p in crawled_products if p.is_crawled)
        uncrawled_count = total_products - crawled_count
        
        # 총 리뷰 수
        total_reviews = sum(p.review_count for p in crawled_products if p.is_crawled)
        
        return {
            "success": True,
            "stats": {
                "total_products": total_products,
                "crawled_products": crawled_count,
                "uncrawled_products": uncrawled_count,
                "total_reviews": total_reviews,
                "crawl_completion_rate": round(crawled_count / total_products * 100, 2) if total_products > 0 else 0
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"통계 조회 중 서버 오류가 발생했습니다: {str(e)}"
        ) 