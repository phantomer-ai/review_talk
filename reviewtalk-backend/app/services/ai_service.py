"""
AI 기반 리뷰 분석 서비스
"""
from typing import List, Dict, Any
from app.infrastructure.ai.vector_store import get_vector_store
from app.infrastructure.ai.openai_client import get_openai_client
from app.models.schemas import ReviewData
from app.infrastructure.conversation_repository import ConversationRepository
from app.infrastructure.chat_room_repository import ChatRoomRepository
from app.infrastructure.unified_product_repository import unified_product_repository
import asyncio
import logging
from app.utils.cache import ConversationCache
from app.utils.url_utils import extract_product_id

# 로거 설정
logger = logging.getLogger(__name__)

conversation_cache = ConversationCache(maxlen=30)

class AIService:
    """AI 기반 리뷰 분석 서비스"""
    
    def __init__(self):
        """AI 서비스 초기화"""
        self.vector_store = get_vector_store()
        self.openai_client = get_openai_client()
        self.conversation_repository = ConversationRepository()
        self.chat_room_repository = ChatRoomRepository()
        self.product_repository = unified_product_repository

    def process_and_store_reviews(
        self, 
        reviews: List[ReviewData], 
        product_id: str,
        product_info: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """리뷰를 처리하고 벡터 저장소에 저장"""
        try:
            logger.info(f"리뷰 추가 product_id :  [{product_id}]")

            # 벡터 저장소에 리뷰 추가
            self.vector_store.add_reviews(reviews, product_id)
            
            # 통계 정보 반환
            stats = self.vector_store.get_collection_stats()
            
            product_info_msg = ""
            if product_info:
                product_info_msg = f" (상품명: {product_info.get('product_name', 'N/A')})"

            return {
                "success": True,
                "message": f"{len(reviews)}개 리뷰가 성공적으로 저장되었습니다.{product_info_msg}",
                "reviews_added": len(reviews),
                "total_reviews_in_db": stats["total_reviews"]
            }
            
        except Exception as e:
            return {
                "success": False,
                "message": f"리뷰 저장 중 오류 발생: {str(e)}",
                "reviews_added": 0,
                "total_reviews_in_db": 0
            }
    
    async def store_chat(
        self,
        user_id: str,
        chat_room_id: int,
        message: str,
        chat_user_id: str,
        related_review_ids: list[str] = None
    ) -> int:
        """
        채팅 내용을 conversations 테이블에 저장 (비동기, chat_room_id 기준)
        Args:
            user_id (str): 실제 대화 주체(사람) user_id
            product_id (str): 제품 ID (product_id)
            message (str): 채팅 메시지
            chat_user_id (str): 메시지 작성자(사람/AI)
            related_review_ids (list[str], optional): 관련 리뷰 ID 목록
        Returns:
            int: 저장된 row의 id (primary key)
        """
        loop = asyncio.get_running_loop()
        try:
            logger.info(f"chat_room_id: {chat_room_id}")

        except Exception:
            raise ValueError(f" invalid chat_room_id  :[{chat_room_id}]")
        return await loop.run_in_executor(
            None,
            self.conversation_repository.store_chat,
            chat_room_id,
            message,
            chat_user_id,
            related_review_ids
        )
    
    async def chat_with_reviews(
        self,
        user_id: str,
        user_question: str,
        product_id: str = None,
        n_results: int = 5
    ) -> Dict[str, Any]:
        """사용자 질문에 대해 리뷰 기반 AI 응답 생성 (비동기, chat_room_id 기준)"""
        logger.info(f"[chat_with_reviews] 시작 - user_question: '{user_question}', product_id: '{product_id}', n_results: {n_results}")
        try:
            loop = asyncio.get_running_loop()
            product_id_int = int(product_id) if product_id is not None else None

            chat_room = None
            chat_room_id = None
            
            # product_id가 있을 때만 채팅방 생성/조회
            if product_id_int is not None:
                # 1단계: 채팅 시작
                # 이미 채팅방이 만들어져 있는지 확인
                chat_room = self.chat_room_repository.get_chat_room_by_user_and_product(user_id, product_id_int)

                #없다면?
                if(chat_room == None):
                    chat_room_id = self.chat_room_repository.create_chat_room(user_id, product_id_int)
                else:
                    chat_room_id = chat_room.get("id")

            # 2단계: 관련 리뷰 검색
            logger.info(f"[chat_with_reviews] 2단계: 리뷰 검색 시작 - query: '{user_question}', product_url: '{product_id}', n_results: {n_results}")
            similar_reviews = self.vector_store.search_similar_reviews(
                query=user_question,
                n_results=n_results,
                product_id=product_id
                )

            logger.info(f"[chat_with_reviews] 2단계: 리뷰 검색 완료 - 검색된 리뷰 수: {len(similar_reviews) if similar_reviews else 0}")
            if not similar_reviews:
                logger.warning(f"[chat_with_reviews] 검색된 리뷰 없음 - query: '{user_question}', product_id: '{product_id}'")
                return {
                    "success": False,
                    "message": "관련된 리뷰를 찾을 수 없습니다.",
                    "ai_response": "죄송합니다. 해당 질문과 관련된 리뷰 정보를 찾을 수 없습니다. 다른 질문을 시도해보세요.",
                    "source_reviews": []
                }


            # 4단계: 채팅방이 있을 때만 최근 대화 조회
            recent_convs = []
            if chat_room_id is not None:
                logger.info(f"[chat_with_reviews] 5단계: 최근 대화 캐시 조회 시작 - chat_room_id: '{chat_room_id}'")
                recent_convs = conversation_cache.get_recent_conversations(chat_room_id)
                logger.info(f"[chat_with_reviews] 5단계: 캐시에서 조회된 대화 수: {len(recent_convs) if recent_convs else 0}")
                if not recent_convs:
                    logger.info(f"[chat_with_reviews] 6단계: DB에서 최근 대화 조회 시작")
                    recent_convs = await loop.run_in_executor(
                        None,
                        self.conversation_repository.get_recent_conversations,
                        chat_room_id
                    )
                    logger.info(f"[chat_with_reviews] 6단계: DB에서 조회된 대화 수: {len(recent_convs) if recent_convs else 0}")
                    if recent_convs:
                        conversation_cache.set_conversations(chat_room_id, recent_convs)
                        logger.info(f"[chat_with_reviews] 6단계: 대화 캐시에 저장 완료")
            # 6.5단계: 상품 정보 조회 (통합 테이블에서)
            product_info = None
            if product_id:
                try:
                    product_info = self.product_repository.get_product_by_id(str(product_id))
                    logger.info(f"[chat_with_reviews] 상품 정보 조회 완료: {product_info.get('product_name') if product_info else '정보 없음'}")
                except Exception as e:
                    logger.warning(f"[chat_with_reviews] 상품 정보 조회 실패: {e}")
            
            # 7단계: AI 응답 생성 (최근 대화 30건 + 상품 정보도 전달)
            logger.info(f"[chat_with_reviews] 7단계: AI 응답 생성 시작")
            ai_response = self.openai_client.generate_review_summary(
                reviews=similar_reviews,
                user_question=user_question,
                recent_conversations=recent_convs
            )
            # 8단계: 관련 리뷰 ID 추출
            related_review_ids = [r["metadata"].get("review_id") for r in similar_reviews if r.get("metadata") and r["metadata"].get("review_id")]
            # 9단계: 채팅방이 있을 때만 대화 저장
            if chat_room_id is not None:
                user_msg = {
                    "message": user_question,
                    "chat_user_id": user_id,
                    "related_review_ids": related_review_ids
                }
                ai_msg = {
                    "message": ai_response,
                    "chat_user_id": "open_1234",
                    "related_review_ids": related_review_ids
                }

                loop = asyncio.get_running_loop()
                await loop.run_in_executor(None, conversation_cache.add_conversation, chat_room_id, user_msg)
                await loop.run_in_executor(None, conversation_cache.add_conversation, chat_room_id, ai_msg)

                # 11단계: DB 저장 (chat_room_id 기준)
                await self.store_chat(
                    user_id=user_id,
                    chat_room_id=chat_room_id,
                    message=user_question,
                    chat_user_id=user_id,
                    related_review_ids=related_review_ids
                )
                await self.store_chat(
                    user_id=user_id,
                    chat_room_id=chat_room_id,
                    message=ai_response,
                    chat_user_id="open_ai_v1",
                    related_review_ids=related_review_ids
                )
            final_response = {
                "success": True,
                "message": "AI 응답이 성공적으로 생성되었습니다.",
                "ai_response": ai_response,
                "source_reviews": similar_reviews,
                "reviews_used": len(similar_reviews),
                "product_info": {
                    "product_id": product_info.get('product_id') if product_info else str(product_id),
                    "product_name": product_info.get('product_name') if product_info else f"상품 {product_id}",
                    "is_special": product_info.get('is_special', False) if product_info else False
                } if product_id else None
            }
            return final_response
        except Exception as e:
            logger.error(f"[chat_with_reviews] 오류: {e}")
            return {
                "success": False,
                "message": f"AI 처리 중 오류: {str(e)}",
                "ai_response": "",
                "source_reviews": []
            }
    
    def get_product_overview(self, product_url: str = None) -> Dict[str, Any]:
        """제품 전체 리뷰 요약 생성"""
        try:
            # 제품 관련 모든 리뷰 검색 (일반적인 쿼리 사용)
            all_reviews = self.vector_store.search_similar_reviews(
                query="제품 전체 평가 요약",
                n_results=50,  # 더 많은 리뷰 가져오기
                product_url=product_url
            )
            
            if not all_reviews:
                return {
                    "success": False,
                    "message": "분석할 리뷰가 없습니다.",
                    "overview": "아직 분석할 리뷰 데이터가 충분하지 않습니다."
                }
            
            # 제품 요약 생성
            overview = self.openai_client.generate_product_overview(all_reviews)
            
            return {
                "success": True,
                "message": "제품 요약이 성공적으로 생성되었습니다.",
                "overview": overview,
                "reviews_analyzed": len(all_reviews)
            }
            
        except Exception as e:
            return {
                "success": False,
                "message": f"제품 요약 생성 중 오류 발생: {str(e)}",
                "overview": "제품 요약을 생성할 수 없습니다."
            }
    
    def get_database_stats(self) -> Dict[str, Any]:
        """데이터베이스 통계 정보 반환"""
        try:
            stats = self.vector_store.get_collection_stats()
            return {
                "success": True,
                "stats": stats
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"통계 조회 중 오류 발생: {str(e)}",
                "stats": {"total_reviews": 0, "collection_name": "unknown"}
            } 