"""
AI 채팅 API 엔드포인트
"""
from fastapi import APIRouter, HTTPException, status, Depends
from typing import Dict, Any

from app.models.schemas import ChatRequest, ChatResponse
from app.services.ai_service import AIService
from app.infrastructure.chat_room_repository import ChatRoomRepository
from app.infrastructure.conversation_room_repository import ConversationRoomRepository

router = APIRouter(prefix="/api/v1", tags=["AI Chat"])


def get_ai_service() -> AIService:
    """AI 서비스 의존성 주입"""
    return AIService()


def get_chat_room_repository() -> ChatRoomRepository:
    return ChatRoomRepository()


def get_conversation_room_repository() -> ConversationRoomRepository:
    return ConversationRoomRepository()


@router.post("/chat", response_model=Dict[str, Any])
async def chat_with_ai(
    request: ChatRequest,
    ai_service: AIService = Depends(get_ai_service),
    chat_room_repo: ChatRoomRepository = Depends(get_chat_room_repository)
) -> Dict[str, Any]:
    """AI와 채팅하기 - 상품 리뷰 기반 질문 답변 (chat_room_id 기반 접근 지원)"""
    
    # product_id가 있는 경우에만 chat_room 처리
    if request.product_id:
        # user_id 에 해당하는 product_id (chat_room) 이 생성 되어있는지 확인
        room = chat_room_repo.get_chat_room_by_user_and_product(request.user_id, request.product_id)
        
        # 만약 room 이 없으면?
        if room == None:
            chat_room_repo.create_chat_room(request.user_id, request.product_id)
    
    # chat_with_reviews에 user_id, product_id 전달 (product_id는 room에서 추출)
    return await ai_service.chat_with_reviews(
        user_id=request.user_id,
        user_question=request.question,
        product_id=request.product_id,
        n_results=5
    )


@router.get("/conversations")
async def get_conversations(
    user_id: str,
    product_id: int,
    limit: int = 30,
    repo: ConversationRoomRepository = Depends(get_conversation_room_repository),
):
    """user_id와 product_id로 대화 내용 조회"""
    try:
        conversations = repo.get_conversations_by_user_and_product(
            user_id=user_id, product_id=product_id, limit=limit
        )
        return conversations
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"대화 내용 조회 중 오류 발생: {str(e)}"
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