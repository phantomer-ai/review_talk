"""
ReviewTalk FastAPI 애플리케이션 메인 모듈
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.core.config import settings
from app.api.routes import crawl, chat, chat_room, account, special_deals  # 신규 계정 라우터 import
from app.database import init_database  # 데이터베이스 모듈 import
from app.utils.scheduler import init_scheduler, shutdown_scheduler
from loguru import logger
import os
import logging

# logs 디렉터리 생성
os.makedirs("logs", exist_ok=True)

# 로그 파일로 저장 (10MB 단위로 파일 분할, 7일간 보관)
logger.add(
    "logs/app.log",
    rotation="10 MB",
    retention="7 days",
    level="INFO",
    format="{time:YYYY-MM-DD HH:mm:ss} | {level} | {message} | {exception}",
    encoding="utf-8"
)

class InterceptHandler(logging.Handler):
    def emit(self, record):
        logger_opt = logger.opt(depth=6, exception=record.exc_info)
        logger_opt.log(record.levelname, record.getMessage())

logging.basicConfig(handlers=[InterceptHandler()], level=0)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """애플리케이션 라이프사이클 관리"""
    # Startup
    logger.info("Starting ReviewTalk API...")

    # 데이터베이스 초기화
    try:
        init_database()
        logger.info("Database initialization completed")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        raise

    yield

    # Shutdown
    logger.info("Shutting down ReviewTalk API...")


def create_app() -> FastAPI:
    """FastAPI 애플리케이션 생성 및 설정"""
    
    app = FastAPI(
        title=settings.app_name,
        version=settings.version,
        description="다나와 상품 리뷰를 AI가 분석해서 답변하는 챗봇 API",
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan  # 라이프사이클 설정
    )
    
    # CORS 미들웨어 설정
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # 라우터 등록
    app.include_router(crawl.router)
    app.include_router(chat.router)
    app.include_router(chat_room.router)
    app.include_router(account.router)  # 계정 라우터 등록
    app.include_router(special_deals.router)

    # 애플리케이션 이벤트 핸들러
    @app.on_event("startup")
    async def startup_event():
        """애플리케이션 시작시 실행"""
        logger.info("🚀 ReviewTalk API 서버 시작")
        # 자동 크롤링 스케줄러 초기화
        init_scheduler()

    @app.on_event("shutdown")
    async def shutdown_event():
        """애플리케이션 종료시 실행"""
        logger.info("🛑 ReviewTalk API 서버 종료")
        # 스케줄러 정리
        shutdown_scheduler()

    return app


# FastAPI 애플리케이션 인스턴스
app = create_app()


@app.get("/", tags=["Root"])
async def root():
    """루트 엔드포인트"""
    return {
        "message": "ReviewTalk API",
        "version": settings.version,
        "docs": "/docs"
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """헬스 체크 엔드포인트"""
    return {
        "status": "healthy",
        "app_name": settings.app_name,
        "version": settings.version
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )