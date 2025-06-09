"""
OpenAI GPT를 사용한 AI 응답 생성
"""
from typing import List, Dict, Any
from openai import OpenAI
from app.core.config import settings


class OpenAIClient:
    """OpenAI GPT를 사용한 AI 응답 생성"""
    
    def __init__(self):
        """OpenAI 클라이언트 초기화"""
        self.client = OpenAI(api_key=settings.openai_api_key)
        self.model = "gpt-3.5-turbo"
    
    def generate_review_summary(
        self, 
        reviews: List[Dict[str, Any]], 
        user_question: str
    ) -> str:
        """리뷰 데이터를 바탕으로 사용자 질문에 대한 답변 생성"""
        try:
            # 리뷰 텍스트 준비
            review_texts = []
            for review in reviews:
                document = review.get("document", "")
                metadata = review.get("metadata", {})
                rating = metadata.get("rating", "N/A")
                date = metadata.get("date", "N/A")
                
                review_text = f"[평점: {rating}, 날짜: {date}]\n{document}"
                review_texts.append(review_text)
            
            reviews_context = "\n\n".join(review_texts)
            
            # 시스템 프롬프트 설정
            system_prompt = """당신은 상품 리뷰 분석 전문가입니다. 사용자의 질문에 대해 제공된 리뷰 데이터를 바탕으로 정확하고 도움이 되는 답변을 제공해주세요.

답변 규칙:
1. 제공된 리뷰 데이터만을 기반으로 답변하세요
2. 구체적인 평점과 리뷰 내용을 인용하여 답변의 근거를 제시하세요
3. 긍정적인 면과 부정적인 면을 균형있게 제시하세요
4. 사용자가 구매 결정을 내리는데 도움이 되도록 객관적인 정보를 제공하세요
5. 리뷰 데이터에 없는 정보는 추측하지 마세요
6. 한국어로 친근하고 자연스럽게 답변해주세요"""

            user_prompt = f"""사용자 질문: {user_question}

관련 리뷰 데이터:
{reviews_context}

위 리뷰 데이터를 바탕으로 사용자의 질문에 답변해주세요."""

            # GPT API 호출
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.7,
                max_tokens=1000
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            print(f"❌ OpenAI API 호출 오류: {e}")
            return "죄송합니다. 현재 AI 응답을 생성할 수 없습니다. 잠시 후 다시 시도해주세요."
    
    def generate_product_overview(self, reviews: List[Dict[str, Any]]) -> str:
        """제품 전체 리뷰 요약 생성"""
        try:
            # 리뷰 통계 계산
            total_reviews = len(reviews)
            ratings = []
            review_texts = []
            
            for review in reviews:
                metadata = review.get("metadata", {})
                rating = metadata.get("rating")
                if rating and isinstance(rating, (int, float)):
                    ratings.append(rating)
                
                document = review.get("document", "")
                review_texts.append(document)
            
            avg_rating = sum(ratings) / len(ratings) if ratings else 0
            reviews_sample = "\n\n".join(review_texts[:10])  # 최대 10개 리뷰만 사용
            
            system_prompt = """당신은 상품 리뷰 분석 전문가입니다. 제공된 리뷰 데이터를 종합하여 제품에 대한 전반적인 요약을 작성해주세요.

요약에 포함할 내용:
1. 전체적인 평가 (평점 기준)
2. 주요 장점들
3. 주요 단점들
4. 구매를 고려할 만한 사용자 타입
5. 주의사항

한국어로 친근하고 객관적으로 작성해주세요."""

            user_prompt = f"""총 {total_reviews}개의 리뷰 (평균 평점: {avg_rating:.1f}/5.0)

대표 리뷰들:
{reviews_sample}

위 데이터를 바탕으로 이 제품에 대한 종합적인 요약을 작성해주세요."""

            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.7,
                max_tokens=800
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            print(f"❌ 제품 요약 생성 오류: {e}")
            return "제품 요약을 생성할 수 없습니다."


# 전역 OpenAI 클라이언트 인스턴스 - 지연 초기화
openai_client = None

def get_openai_client():
    """OpenAI 클라이언트 싱글톤 인스턴스 반환"""
    global openai_client
    if openai_client is None:
        openai_client = OpenAIClient()
    return openai_client 