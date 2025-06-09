"""
ReviewTalk FastAPI 애플리케이션 메인 모듈
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.routes import crawl, chat


def create_app() -> FastAPI:
    """FastAPI 애플리케이션 생성 및 설정"""
    
    app = FastAPI(
        title=settings.app_name,
        version=settings.version,
        description="다나와 상품 리뷰를 AI가 분석해서 답변하는 챗봇 API",
        docs_url="/docs",
        redoc_url="/redoc",
    )
    
    # CORS 미들웨어 설정
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # 라우터 등록
    app.include_router(crawl.router)
    app.include_router(chat.router)
    
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