from typing import List, Optional
from pydantic import BaseModel, HttpUrl, Field


# 크롤링 관련 스키마
class CrawlRequest(BaseModel):
    product_url: HttpUrl = Field(..., description="다나와 상품 URL")
    max_reviews: int = Field(default=100, ge=1, le=1000, description="수집할 최대 리뷰 수")


class ReviewData(BaseModel):
    review_id: str = Field(..., description="리뷰 고유 ID")
    content: str = Field(..., description="리뷰 내용")
    rating: Optional[int] = Field(None, ge=1, le=5, description="평점 (1-5)")
    author: Optional[str] = Field(None, description="작성자")
    date: Optional[str] = Field(None, description="작성일")


class CrawlResponse(BaseModel):
    success: bool = Field(..., description="크롤링 성공 여부")
    product_id: str = Field(..., description="상품 고유 ID")
    product_name: str = Field(..., description="상품명")
    total_reviews: int = Field(..., description="수집된 리뷰 수")
    reviews: List[ReviewData] = Field(..., description="리뷰 목록")
    error_message: Optional[str] = Field(None, description="에러 메시지")


# AI 채팅 관련 스키마
class ChatRequest(BaseModel):
    product_id: Optional[str] = Field(None, description="상품 ID (없으면 전체 리뷰에서 검색)")
    question: str = Field(..., min_length=1, max_length=500, description="사용자 질문")


class SourceReview(BaseModel):
    content: str = Field(..., description="참조된 리뷰 내용")
    rating: Optional[int] = Field(None, description="평점")
    similarity_score: float = Field(..., description="유사도 점수")


class ChatResponse(BaseModel):
    success: bool = Field(..., description="처리 성공 여부")
    answer: str = Field(..., description="AI 답변")
    confidence: float = Field(..., ge=0.0, le=1.0, description="답변 신뢰도")
    source_reviews: List[SourceReview] = Field(..., description="참조된 리뷰들")
    error_message: Optional[str] = Field(None, description="에러 메시지")


# 공통 응답 스키마
class HealthResponse(BaseModel):
    status: str
    app_name: str
    version: str 