"""
애플리케이션 설정 및 환경변수 관리
"""
import os
from typing import List
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """애플리케이션 설정"""
    
    # 기본 설정
    app_name: str = "ReviewTalk API"
    version: str = "0.1.0"
    debug: bool = False
    
    # 서버 설정
    host: str = "0.0.0.0"
    port: int = 8000
    
    # CORS 설정
    cors_origins: List[str] = ["http://localhost:3000","http://127.0.0.1:3000"]
    
    # 데이터베이스 설정
    database_url: str = "sqlite:///./data/reviewtalk.db"
    
    # OpenAI API 설정
    openai_api_key: str = ""
    
    # 크롤링 설정
    crawling_timeout: int = 30
    max_reviews_per_product: int = 50
    
    # ChromaDB 설정
    chroma_db_path: str = "./data/chroma_db"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"  


# 전역 설정 인스턴스
settings = Settings() 