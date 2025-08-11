"""
애플리케이션 설정 및 환경변수 관리
"""
import os
from typing import List, Literal
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
    
    # AI/LLM 설정
    llm_provider: Literal["openai", "gemini", "qwen3", "local"] = "qwen3"  # Qwen3 추가
    
    # OpenAI API 설정
    openai_api_key: str = ""
    openai_model: str = "gpt-4o"
    
    # Google Gemini API 설정
    gemini_api_key: str = ""
    gemini_model: str = "gemini-1.5-pro"
    
    # Qwen3/Local LLM 설정 (Ollama, vLLM 등)
    local_llm_base_url: str = "http://localhost:11434/v1"  # Ollama 기본 URL
    local_llm_model: str = "qwen3:8b"  # 사용할 모델명
    local_llm_api_key: str = "not-needed"  # 로컬 모델은 API 키 불필요
    
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