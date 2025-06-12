"""
AI 채팅 API 엔드포인트
"""
from fastapi import APIRouter, HTTPException, Depends
from typing import Dict, Any

from app.models.schemas import ChatRequest, ChatResponse
from app.services.ai_service import AIService

router = APIRouter(prefix="/api/v1", tags=["AI Chat"])


def get_ai_service() -> AIService:
    """AI 서비스 의존성 주입"""
    return AIService()


@router.post("/chat", response_model=Dict[str, Any])
async def chat_with_ai(
    request: ChatRequest,
    ai_service: AIService = Depends(get_ai_service)
) -> Dict[str, Any]:
    """AI와 채팅하기 - 상품 리뷰 기반 질문 답변"""
    try:
        # AI 서비스를 통해 답변 생성
        result = await ai_service.chat_with_reviews(
            user_question=request.question,
            product_id=request.product_id,  # Optional product_id
            n_results=5
        )
        
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"채팅 처리 중 오류 발생: {str(e)}"
        )


@router.get("/product-overview")
async def get_product_overview(
    product_url: str = None,
    ai_service: AIService = Depends(get_ai_service)
) -> Dict[str, Any]:
    """제품 전체 리뷰 요약 생성"""
    try:
        result = ai_service.get_product_overview(product_url=product_url)
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"제품 요약 생성 중 오류 발생: {str(e)}"
        )


@router.get("/database-stats")
async def get_database_stats(
    ai_service: AIService = Depends(get_ai_service)
) -> Dict[str, Any]:
    """벡터 데이터베이스 통계 정보"""
    try:
        result = ai_service.get_database_stats()
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"통계 조회 중 오류 발생: {str(e)}"
        ) 