"""
AI 기반 리뷰 분석 서비스
"""
from typing import List, Dict, Any
from app.infrastructure.ai.vector_store import get_vector_store
from app.infrastructure.ai.openai_client import get_openai_client
from app.models.schemas import ReviewData
from app.infrastructure.conversation_repository import ConversationRepository
import asyncio
from app.utils.cache import ConversationCache
import sqlite3
from loguru import logger
from app.core.config import settings

conversation_cache = ConversationCache(maxlen=30)

class AIService:
    """AI 기반 리뷰 분석 서비스"""
    
    def __init__(self):
        """AI 서비스 초기화"""
        self.vector_store = get_vector_store()
        self.openai_client = get_openai_client()
        self.conversation_repository = ConversationRepository()
    
    def process_and_store_reviews(
        self, 
        reviews: List[ReviewData], 
        product_url: str,
        product_info: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """리뷰를 처리하고 벡터 저장소 및 일반 DB에 저장 (통합 방식)"""
        try:
            # 1. products 테이블에 상품 정보 저장 (UPSERT)
            product_id = self._save_product_to_db(product_url, product_info)
            
            # 2. reviews 테이블에 리뷰 저장
            self._save_reviews_to_db(product_id, reviews)
            
            # 3. 벡터 저장소에 리뷰 추가 (상품 정보 포함)
            self.vector_store.add_reviews(reviews, product_url, product_info)
            
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
        product_id: str,
        message: str,
        chat_user_id: str,
        related_review_ids: list[str] = None
    ) -> int:
        """
        채팅 내용을 conversations 테이블에 저장 (비동기)
        Args:
            product_id (str): 제품 ID (product_url)
            message (str): 채팅 메시지
            chat_user_id (str): 사용자 ID 또는 AI ID
            related_review_ids (list[str], optional): 관련 리뷰 ID 목록
        Returns:
            int: 저장된 row의 id (primary key)
        """
        loop = asyncio.get_running_loop()
        try:
            product_id_int = int(product_id) if product_id is not None else None
        except Exception:
            product_id_int = None
        return await loop.run_in_executor(
            None,
            self.conversation_repository.store_chat,
            product_id_int,
            message,
            chat_user_id,
            related_review_ids
        )
    
    async def chat_with_reviews(
        self, 
        user_question: str, 
        product_id: str = None, 
        n_results: int = 5
    ) -> Dict[str, Any]:
        """사용자 질문에 대해 리뷰 기반 AI 응답 생성 (비동기)"""
        try:
            # 관련 리뷰 검색
            similar_reviews = self.vector_store.search_similar_reviews(
                query=user_question,
                n_results=n_results,
                product_url=product_id  # product_id를 product_url 파라미터에 전달
            )
            
            if not similar_reviews:
                return {
                    "success": False,
                    "message": "관련된 리뷰를 찾을 수 없습니다.",
                    "ai_response": "죄송합니다. 해당 질문과 관련된 리뷰 정보를 찾을 수 없습니다. 다른 질문을 시도해보세요.",
                    "source_reviews": []
                }
            user_id = "temp_1234"
            ai_id = "open_1234"
            # 1. 최근 대화 30건 cache에서 조회, 없으면 db에서 조회 후 cache에 set
            recent_convs = conversation_cache.get_recent_conversations(user_id, product_id)
            if not recent_convs:
                loop = asyncio.get_running_loop()
                recent_convs = await loop.run_in_executor(
                    None,
                    self.conversation_repository.get_recent_conversations,
                    user_id,
                    product_id
                )
                if recent_convs:
                    conversation_cache.set_conversations(user_id, product_id, recent_convs)
            # 2. AI 응답 생성 (최근 대화 30건도 전달)
            ai_response = self.openai_client.generate_review_summary(
                reviews=similar_reviews,
                user_question=user_question,
                recent_conversations=recent_convs
            )
            # 관련 리뷰 ID 추출
            related_review_ids = [r["metadata"].get("review_id") for r in similar_reviews if r.get("metadata") and r["metadata"].get("review_id")]
            # 3. cache에 add_conversation (비동기, Write-Behind) 및 DB 저장 (비동기)
            user_msg = {
                "message": user_question,
                "chat_user_id": user_id,
                "related_review_ids": related_review_ids
            }
            ai_msg = {
                "message": ai_response,
                "chat_user_id": ai_id,
                "related_review_ids": related_review_ids
            }
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(None, conversation_cache.add_conversation, user_id, product_id, user_msg)
            await loop.run_in_executor(None, conversation_cache.add_conversation, user_id, product_id, ai_msg)
            # DB 저장은 비동기로 (이미 await self.store_chat으로 구현)
            await self.store_chat(
                product_id=product_id,
                message=user_question,
                chat_user_id=user_id,
                related_review_ids=related_review_ids
            )
            await self.store_chat(
                product_id=product_id,
                message=ai_response,
                chat_user_id=ai_id,
                related_review_ids=related_review_ids
            )
            return {
                "success": True,
                "message": "AI 응답이 성공적으로 생성되었습니다.",
                "ai_response": ai_response,
                "source_reviews": similar_reviews,
                "reviews_used": len(similar_reviews)
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"AI 응답 생성 중 오류 발생: {str(e)}",
                "ai_response": "죄송합니다. 현재 AI 응답을 생성할 수 없습니다.",
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
    
    def _save_product_to_db(self, product_url: str, product_info: Dict[str, Any] = None) -> int:
        """products 테이블에 상품 정보 저장 (UPSERT) - 통합 방식"""
        try:
            db_path = settings.database_url.replace("sqlite:///", "")
            
            with sqlite3.connect(db_path) as conn:
                cursor = conn.cursor()
                
                # 상품명 결정
                product_name = "다나와 상품"
                if product_info and product_info.get("product_name"):
                    product_name = product_info["product_name"]
                
                # UPSERT: 기존 상품이 있으면 업데이트, 없으면 삽입
                cursor.execute("""
                    INSERT INTO products (name, url, created_at)
                    VALUES (?, ?, CURRENT_TIMESTAMP)
                    ON CONFLICT(url) DO UPDATE SET
                        name = excluded.name,
                        created_at = created_at
                """, (product_name, product_url))
                
                # 상품 ID 조회
                cursor.execute("SELECT id FROM products WHERE url = ?", (product_url,))
                result = cursor.fetchone()
                
                if result:
                    product_id = result[0]
                    logger.info(f"✅ 상품 DB 저장 완료: {product_name} (ID: {product_id})")
                    return product_id
                else:
                    raise Exception("상품 저장 후 ID 조회 실패")
                    
        except Exception as e:
            logger.error(f"❌ 상품 DB 저장 오류: {e}")
            raise
    
    def _save_reviews_to_db(self, product_id: int, reviews: List[ReviewData]) -> int:
        """reviews 테이블에 리뷰 저장 - 통합 방식"""
        try:
            db_path = settings.database_url.replace("sqlite:///", "")
            saved_count = 0
            
            with sqlite3.connect(db_path) as conn:
                cursor = conn.cursor()
                
                for review in reviews:
                    try:
                        # UPSERT: 기존 리뷰가 있으면 업데이트, 없으면 삽입
                        cursor.execute("""
                            INSERT INTO reviews (
                                product_id, review_id, content, rating, author, date, created_at
                            ) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                            ON CONFLICT(review_id) DO UPDATE SET
                                content = excluded.content,
                                rating = excluded.rating,
                                author = excluded.author,
                                date = excluded.date
                        """, (
                            product_id,
                            review.review_id or f"review_{hash(review.content)}",
                            review.content,
                            review.rating,
                            review.author,
                            review.date
                        ))
                        saved_count += 1
                        
                    except sqlite3.IntegrityError as e:
                        # 중복 리뷰는 무시
                        logger.debug(f"중복 리뷰 스킵: {review.review_id}")
                        continue
                
                conn.commit()
                logger.info(f"✅ 리뷰 DB 저장 완료: {saved_count}개")
                return saved_count
                
        except Exception as e:
            logger.error(f"❌ 리뷰 DB 저장 오류: {e}")
            raise 