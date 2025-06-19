"""
OpenAI GPT를 사용한 AI 응답 생성
"""
from typing import List, Dict, Any
from openai import OpenAI
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class OpenAIClient:
    """OpenAI GPT를 사용한 AI 응답 생성"""
    
    def __init__(self):
        """OpenAI 클라이언트 초기화"""
        self.client = OpenAI(api_key=settings.openai_api_key)
        self.model = "gpt-4o"
        logger.info(f"[OpenAIClient.__init__] 모델: {self.model}, API KEY 존재 여부: {bool(settings.openai_api_key)}")


    def generate_review_summary(
        self, 
        reviews: List[Dict[str, Any]], 
        user_question: str,
        recent_conversations: List[Dict[str, Any]] = None
    ) -> str:
        """리뷰 데이터와 최근 대화 맥락을 바탕으로 사용자 질문에 대한 답변 생성"""
        logger.info(f"[generate_review_summary] 호출 - user_question: {user_question}")
        logger.info(f"[generate_review_summary] reviews 개수: {len(reviews)}")
        logger.info(f"[generate_review_summary] recent_conversations 개수: {len(recent_conversations) if recent_conversations else 0}")
        try:
            # 최근 대화 맥락 준비
            conversation_context = ""
            if recent_conversations:
                conversation_context = "\n\n".join([
                    f"[{conv.get('chat_user_id', '')}] {conv.get('message', '')}" for conv in recent_conversations
                ])
                conversation_context = f"\n\n[최근 대화 맥락]\n{conversation_context}"
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
            system_prompt = """

## 역할
-당신은 '리뷰톡'의 상품 리뷰 분석 전문 AI 챗봇입니다.
## 응답 스타일
- 친절하고 신뢰감 있는 존댓말 사용
- 100~200자 내외의 간결하고 명확한 응답
- 다음 표현들을 자주 사용하세요:
  - "리뷰를 분석해보니…"
  - "구매하신 분들 의견을 보면…"
  - "대부분의 사용자들이…"
- 이모지를 적절히 사용하세요: 😊 🙏 ⚠️ 💬 👍 💡
## 응답 구조
1. **관련 리뷰 수 요약**
   - 예: "전체 1,500개의 리뷰 중 120명이 착용감에 대해 언급했어요."
2. **리뷰 분석 결과 요약** (한 문장)
3. **실제 리뷰 내용 인용** (작성일, 평점 포함하여 1~2개 서술형 인용)
   - 예:
     [평점: ★★★★★,  “이어폰 착용감이 매우 좋아요.”
     [평점: ★☆☆☆☆,  “반품 제품이 온 것 같아 실망했습니다.”
   :오른쪽을_가리키는_손_모양: 표 형태는 사용하지 않고, 줄바꿈과 인용부호를 활용한 서술형 인용만 사용합니다.
4. **긍/부정 요약 및 결론 제시**
## 예외 상황 대응
- 관련 리뷰 없음: "죄송해요, 해당 내용에 대한 리뷰를 찾을 수 없네요 :땀_흘리는_웃는_얼굴:"
- 의견이 나뉘는 경우: "의견이 나뉘는 부분이에요. 긍정적으로는…, 반대로는…"
- 제품 외 질문: "상품 리뷰와 관련된 질문을 해주시면 더 정확한 답변을 드릴 수 있어요 :미소짓는_상기된_얼굴:"
## 주의사항
- 리뷰에 없는 정보는 절대 추론하거나 지어내지 마세요.
- 감정적/광고성 표현을 피하고, 중립적이고 유용한 정보를 제공하세요.
- 한두 리뷰만을 근거로 일반화하지 마세요. 반드시 복수의 리뷰를 종합적으로 분석하세요.
- 너무 짧거나 기계적인 답변을 피하고, 사용자가 신뢰할 수 있도록 서술형으로 설명하세요."""
        user_prompt = f"""사용자 질문: {user_question}\n\n{conversation_context}\n\n관련 리뷰 데이터:\n{reviews_context}\n\n위 리뷰 데이터와 최근 대화 맥락을 바탕으로 사용자의 질문에 답변해주세요."""
        logger.info(f"[generate_review_summary] system_prompt 길이: {len(system_prompt)}")
        logger.info(f"[generate_review_summary] user_prompt 길이: {len(user_prompt)}")
        # GPT API 호출
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.3, # 0.0 ~ 1.0 사이의 값으로 설정, 리뷰기반 0.3으로 조정
                max_tokens=1000
            )
            logger.info(f"[generate_review_summary] OpenAI 응답 수신 - choices: {len(response.choices)}")
            logger.info(f"[generate_review_summary] 응답 내용 길이: {len(response.choices[0].message.content) if response.choices and response.choices[0].message and response.choices[0].message.content else 0}")
            return response.choices[0].message.content
        except Exception as e:
            logger.error(f"[generate_review_summary] OpenAI API 호출 오류: {e}", exc_info=True)
            return "죄송합니다. 현재 AI 응답을 생성할 수 없습니다. 잠시 후 다시 시도해주세요."
    
    def generate_product_overview(self, reviews: List[Dict[str, Any]]) -> str:
        """제품 전체 리뷰 요약 생성"""
        logger.info(f"[generate_product_overview] 호출 - 리뷰 개수: {len(reviews)}")
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
        logger.info(f"[generate_product_overview] 평균 평점: {avg_rating:.2f}, 샘플 리뷰 개수: {len(review_texts[:10])}")
        system_prompt = """
## 역할
-당신은 '리뷰톡'의 상품 리뷰 분석 전문 AI 챗봇입니다.

## 응답 스타일
- 친절하고 신뢰감 있는 존댓말 사용
- 100~200자 내외의 간결하고 명확한 응답
- 다음 표현들을 자주 사용하세요:
  - "리뷰를 분석해보니…"
  - "구매하신 분들 의견을 보면…"
  - "대부분의 사용자들이…"
- 이모지를 적절히 사용하세요: 😊 🙏 ⚠️ 💬 👍 💡
## 응답 구조
1. **관련 리뷰 수 요약**
   - 예: "전체 1,500개의 리뷰 중 120명이 착용감에 대해 언급했어요."
2. **리뷰 분석 결과 요약** (한 문장)
3. **실제 리뷰 내용 인용** (작성일, 평점 포함하여 1~2개 서술형 인용)
   - 예:
     [평점: ★★★★★,  “이어폰 착용감이 매우 좋아요.”
     [평점: ★☆☆☆☆,  “반품 제품이 온 것 같아 실망했습니다.”
   :오른쪽을_가리키는_손_모양: 표 형태는 사용하지 않고, 줄바꿈과 인용부호를 활용한 서술형 인용만 사용합니다.
4. **긍/부정 요약 및 결론 제시**
## 예외 상황 대응
- 관련 리뷰 없음: "죄송해요, 해당 내용에 대한 리뷰를 찾을 수 없네요 :땀_흘리는_웃는_얼굴:"
- 의견이 나뉘는 경우: "의견이 나뉘는 부분이에요. 긍정적으로는…, 반대로는…"
- 제품 외 질문: "상품 리뷰와 관련된 질문을 해주시면 더 정확한 답변을 드릴 수 있어요 :미소짓는_상기된_얼굴:"
## 주의사항
- 리뷰에 없는 정보는 절대 추론하거나 지어내지 마세요.
- 감정적/광고성 표현을 피하고, 중립적이고 유용한 정보를 제공하세요.
- 한두 리뷰만을 근거로 일반화하지 마세요. 반드시 복수의 리뷰를 종합적으로 분석하세요.
- 너무 짧거나 기계적인 답변을 피하고, 사용자가 신뢰할 수 있도록 서술형으로 설명하세요."""
        user_prompt = f"""총 {total_reviews}개의 리뷰 (평균 평점: {avg_rating:.1f}/5.0)\n\n대표 리뷰들:\n{reviews_sample}\n\n위 데이터를 바탕으로 이 제품에 대한 종합적인 요약을 작성해주세요."""
        logger.info(f"[generate_product_overview] system_prompt 길이: {len(system_prompt)}")
        logger.info(f"[generate_product_overview] user_prompt 길이: {len(user_prompt)}")
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.7,
                max_tokens=800
            )
            logger.info(f"[generate_product_overview] OpenAI 응답 수신 - choices: {len(response.choices)}")
            logger.info(f"[generate_product_overview] 응답 내용 길이: {len(response.choices[0].message.content) if response.choices and response.choices[0].message and response.choices[0].message.content else 0}")
            return response.choices[0].message.content
        except Exception as e:
            logger.error(f"[generate_product_overview] OpenAI API 호출 오류: {e}", exc_info=True)
            return "제품 요약을 생성할 수 없습니다."


# 전역 OpenAI 클라이언트 인스턴스 - 지연 초기화
openai_client = None

def get_openai_client():
    """OpenAI 클라이언트 싱글톤 인스턴스 반환"""
    global openai_client
    if openai_client is None:
        openai_client = OpenAIClient()
    return openai_client 