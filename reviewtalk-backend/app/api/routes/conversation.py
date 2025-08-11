"""
대화 인터페이스 API 엔드포인트
"""
from fastapi import APIRouter, HTTPException, Depends, status
from typing import Dict, Any

from app.models.schemas import ChatRequest, CrawlRequest
from app.services.ai_service import AIService
from app.services.crawl_service import CrawlService

router = APIRouter(prefix="/api/v1", tags=["Conversation"])


def get_ai_service() -> AIService:
    """AI 서비스 의존성 주입"""
    return AIService()


def get_crawl_service() -> CrawlService:
    """크롤 서비스 의존성 주입"""
    return CrawlService()


@router.post("/conversation")
async def conversation_interface(
    user_id: str,
    user_question: str,
    product_id: str = None,
    crawl_request: CrawlRequest = None,
    ai_service: AIService = Depends(get_ai_service),
    crawl_service: CrawlService = Depends(get_crawl_service)
) -> Dict[str, Any]:
    """
    통합 대화 인터페이스
    - AI 서비스와 비동기적으로 채팅 (chat_with_reviews)
    - 크롤 서비스와 비동기적으로 리뷰 크롤링 (crawl_product_reviews)
    
    Args:
        user_id: 사용자 ID (필수)
        user_question: 사용자 질문 (필수)
        product_id: 제품 ID (선택적)
        crawl_request: 크롤링 요청 (선택적)
    """
    try:
        # 1. AI 서비스 - 비동기 호출 (chat_with_reviews)
        chat_result = await ai_service.chat_with_reviews(
            user_id=user_id,
            user_question=user_question,
            product_id=product_id,
            n_results=5
        )
        
        # 2. 크롤 서비스 - 비동기 호출 (crawl_product_reviews)
        crawl_result = None
        if crawl_request:
            crawl_result = await crawl_service.crawl_product_reviews(crawl_request)
        
        # 결과 통합
        response = {
            "success": True,
            "chat_result": chat_result,
            "crawl_result": crawl_result,
            "message": "대화 인터페이스 처리 완료"
        }
        
        return response
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"대화 인터페이스 처리 중 오류 발생: {str(e)}"
        )