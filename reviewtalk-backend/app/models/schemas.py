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
    product_image: Optional[str] = Field(None, description="상품 이미지 URL")
    product_price: Optional[str] = Field(None, description="상품 가격")
    product_brand: Optional[str] = Field(None, description="상품 브랜드")
    total_reviews: int = Field(..., description="수집된 리뷰 수")
    reviews: List[ReviewData] = Field(..., description="리뷰 목록")
    error_message: Optional[str] = Field(None, description="에러 메시지")


# AI 채팅 관련 스키마
class ChatRequest(BaseModel):
    user_id: str = Field(..., description="사용자 ID")
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


# 특가 상품 관련 스키마
class SpecialProduct(BaseModel):
    product_id: str = Field(..., description="상품 고유 ID")
    product_name: str = Field(..., description="상품명")
    product_url: str = Field(..., description="상품 URL")
    image_url: Optional[str] = Field(None, description="상품 이미지 URL")
    price: Optional[str] = Field(None, description="특가 가격")
    original_price: Optional[str] = Field(None, description="원래 가격")
    discount_rate: Optional[str] = Field(None, description="할인율")
    brand: Optional[str] = Field(None, description="브랜드명")
    category: Optional[str] = Field(None, description="카테고리")
    rating: Optional[float] = Field(None, description="평균 평점")
    review_count: int = Field(default=0, description="리뷰 수")
    is_crawled: bool = Field(default=False, description="리뷰 크롤링 완료 여부")
    created_at: Optional[str] = Field(None, description="등록 시간")
    updated_at: Optional[str] = Field(None, description="업데이트 시간")


class SpecialProductsResponse(BaseModel):
    success: bool = Field(..., description="처리 성공 여부")
    total_count: int = Field(..., description="전체 특가 상품 수")
    products: List[SpecialProduct] = Field(..., description="특가 상품 목록")
    error_message: Optional[str] = Field(None, description="에러 메시지")


class CrawlSpecialProductsRequest(BaseModel):
    max_products: int = Field(default=50, ge=1, le=100, description="수집할 최대 특가 상품 수")
    crawl_reviews: bool = Field(default=True, description="각 상품의 리뷰도 함께 크롤링할지 여부")
    max_reviews_per_product: int = Field(default=100, ge=1, le=500, description="상품당 수집할 최대 리뷰 수")


class CrawlSpecialProductsResponse(BaseModel):
    success: bool = Field(..., description="크롤링 성공 여부")
    total_products: int = Field(..., description="수집된 특가 상품 수")
    products_with_reviews: int = Field(..., description="리뷰까지 수집된 상품 수")
    total_reviews: int = Field(..., description="수집된 총 리뷰 수")
    error_message: Optional[str] = Field(None, description="에러 메시지")


# 공통 응답 스키마
class HealthResponse(BaseModel):
    status: str
    app_name: str
    version: str


# 채팅방(chat_room) 관련 스키마
class ChatRoomBase(BaseModel):
    user_id: str = Field(..., description="채팅방 소유자(사용자) ID")
    product_id: int = Field(..., description="상품 ID")

class ChatRoomCreate(ChatRoomBase):
    pass

class ChatRoomRead(ChatRoomBase):
    id: int = Field(..., description="채팅방 고유 ID")
    created_at: str = Field(..., description="생성일시")

class ChatRoomListResponse(BaseModel):
    chat_rooms: list[ChatRoomRead] = Field(..., description="채팅방 목록") 