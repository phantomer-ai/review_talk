"""
AI 기반 리뷰 분석 서비스
"""
from typing import List, Dict, Any
from app.infrastructure.ai.vector_store import get_vector_store
from app.infrastructure.ai.openai_client import get_openai_client
from app.models.schemas import ReviewData


class AIService:
    """AI 기반 리뷰 분석 서비스"""
    
    def __init__(self):
        """AI 서비스 초기화"""
        self.vector_store = get_vector_store()
        self.openai_client = get_openai_client()
    
    def process_and_store_reviews(
        self, 
        reviews: List[ReviewData], 
        product_url: str
    ) -> Dict[str, Any]:
        """리뷰를 처리하고 벡터 저장소에 저장"""
        try:
            # 벡터 저장소에 리뷰 추가
            self.vector_store.add_reviews(reviews, product_url)
            
            # 통계 정보 반환
            stats = self.vector_store.get_collection_stats()
            
            return {
                "success": True,
                "message": f"{len(reviews)}개 리뷰가 성공적으로 저장되었습니다.",
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
    
    def chat_with_reviews(
        self, 
        user_question: str, 
        product_id: str = None, 
        n_results: int = 5
    ) -> Dict[str, Any]:
        """사용자 질문에 대해 리뷰 기반 AI 응답 생성"""
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
            
            # AI 응답 생성
            ai_response = self.openai_client.generate_review_summary(
                reviews=similar_reviews,
                user_question=user_question
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