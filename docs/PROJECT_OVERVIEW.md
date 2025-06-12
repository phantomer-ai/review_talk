# PROJECT_OVERVIEW 


# 리뷰톡 프로젝트 개요
## Project Overview

---

## 🎯 **프로젝트 목표**

**서비스명:** 리뷰톡 (ReviewTalk)  
**목적:** 다나와 상품 리뷰를 AI가 분석해서 사용자 질문에 답변하는 모바일 챗봇  
**개발자:** 1인 풀스택 개발  

**핵심 플로우:**
1. 사용자가 다나와 상품 URL 입력
2. 백엔드에서 리뷰 크롤링 + AI 분석
3. Flutter 앱에서 자연어 질문-답변 채팅

**확장 계획:**
- 🚀 상품 비교 기능
- 🚀 유튜브 리뷰 연동
- 🚀 광고 리뷰 필터링
- 🚀 사용자 맞춤 추천

---

## 🛠️ **기술 스택**

### Backend
- **Framework**: FastAPI 0.104+
- **Language**: Python 3.11+
- **Package Manager**: uv
- **AI/ML**: 
  - OpenAI GPT-4 (주요 LLM)
  - LangChain 0.1+ (RAG 구현)
  - ChromaDB (벡터 데이터베이스)
  - Sentence-Transformers (임베딩)
- **Crawling**: 
  - Playwright (메인)
  
- **Database**: 
  - SQLite (개발 시작용)
  - PostgreSQL (확장시 - Railway 제공)
  - SQLAlchemy ORM (DB 추상화)
- **Validation**: Pydantic v2

### Frontend
- **Framework**: Flutter 3.16+
- **Language**: Dart 3.2+
- **Architecture**: MVVM + Clean Architecture
- **State Management**: Provider 6.1+
- **HTTP**: dio 5.4+
- **Dependency Injection**: get_it 7.6+
- **Local Storage**: shared_preferences, hive

### DevOps & Tools
- **Package Manager**: uv (Python 의존성 관리)
- **Deployment**: 
  - Backend: Railway - GitHub 자동 배포
  - Database: Railway PostgreSQL (무료)
  - Frontend: APK 직접 배포
- **Version Control**: Git + GitHub

---

## 🏗️ **아키텍처 설계**

### 전체 구조도
```
┌─────────────────┐    API    ┌──────────────────┐
│   Flutter App   │ ◄────────► │   FastAPI Server │
│     (MVVM)      │            │      (Clean)     │
└─────────────────┘            └──────────────────┘
         │                              │
         ▼                              ▼
┌─────────────────┐            ┌──────────────────┐
│ Local Storage   │            │  Vector Database │
│ (SharedPrefs)   │            │     (ChromaDB)   │
└─────────────────┘            └──────────────────┘
```

### 백엔드 폴더 구조
```
reviewtalk-backend/
├── app/
│   ├── main.py                   # FastAPI 앱 진입점
│   ├── core/                     # 핵심 설정
│   │   ├── config.py            # 환경변수, 설정
│   │   └── dependencies.py      # DI 컨테이너
│   ├── api/                     # API 엔드포인트
│   │   └── routes/
│   │       ├── crawl.py         # 크롤링 API
│   │       └── chat.py          # 챗봇 API
│   ├── services/                # 비즈니스 로직
│   │   ├── crawl_service.py     # 크롤링 서비스
│   │   └── ai_service.py        # AI 챗봇 서비스
│   ├── models/                  # 데이터 모델
│   │   └── schemas.py           # Pydantic 스키마
│   ├── infrastructure/          # 외부 의존성
│   │   ├── crawler/
│   │   │   └── danawa_crawler.py
│   │   └── ai/
│   │       ├── openai_client.py
│   │       └── chroma_store.py
│   └── utils/
│       └── exceptions.py
├── pyproject.toml
└── .env
```

### 프론트엔드 폴더 구조 (MVVM)
```
reviewtalk-app/
├── lib/
│   ├── main.dart                 # 앱 진입점
│   ├── core/                     # 핵심 기능
│   │   ├── constants/           # 상수
│   │   ├── network/             # 네트워크
│   │   └── utils/               # 유틸리티
│   ├── data/                     # 데이터 레이어
│   │   ├── datasources/remote/  # API 클라이언트
│   │   ├── models/              # 데이터 모델
│   │   └── repositories/        # 리포지토리 구현
│   ├── domain/                   # 도메인 레이어
│   │   ├── entities/            # 도메인 엔티티
│   │   ├── repositories/        # 리포지토리 인터페이스
│   │   └── usecases/            # 유스케이스
│   ├── presentation/             # 프레젠테이션 레이어
│   │   ├── viewmodels/          # ViewModel (MVVM)
│   │   └── views/               # View (UI)
│   │       ├── screens/
│   │       └── widgets/
│   └── injection_container.dart  # 의존성 주입
└── pubspec.yaml
```

### 프레젠테이션 레이어 구조
```
presentation/
├── viewmodels/
│   ├── product_viewmodel.dart     # 상품 크롤링 상태관리
│   └── chat_viewmodel.dart        # AI 채팅 상태관리
└── views/
    ├── screens/
    │   ├── home_screen.dart       # URL 입력 화면
    │   ├── loading_screen.dart    # 크롤링 진행 화면  
    │   └── chat_screen.dart       # AI 채팅 화면
    └── widgets/
        ├── product_url_input.dart # URL 입력 위젯
        ├── chat_bubble.dart       # 채팅 말풍선 위젯
        └── loading_indicator.dart # 로딩 인디케이터
```

---

## 🎯 **오늘의 최종 목표**

### **완성 목표:**
- ✅ 다나와 URL 입력 → 리뷰 크롤링 성공
- ✅ "배터리 어때요?" → AI 답변 생성
- ✅ Flutter 앱에서 전체 플로우 실행 가능
- ✅ 안드로이드 에뮬레이터에서 데모 시연 가능
- ✅ Railway에 백엔드 배포
- ✅ APK 파일 생성

### **핵심 API 엔드포인트:**
```
POST /api/v1/crawl-reviews
POST /api/v1/chat
GET  /health
```

### **환경변수:**
```
OPENAI_API_KEY=sk-your-key-here
CORS_ORIGINS=*
DATABASE_URL=sqlite:///./reviewtalk.db
```

이 문서는 모든 체크포인트에서 참조용으로 사용하세요!