# ReviewTalk 프로젝트 🚀

다나와 상품 리뷰를 AI가 분석해서 사용자 질문에 답변하는 모바일 챗봇

## 📋 프로젝트 구조

```
juho_alone/
├── docs/                           # 프로젝트 문서
│   ├── PROJECT_OVERVIEW.md         # 프로젝트 개요
│   ├── CHECKPOINTS_PHASE1.md      # Phase 1 체크포인트
│   └── CHECKPOINTS_PHASE2.md      # Phase 2 체크포인트
├── reviewtalk-backend/             # FastAPI 백엔드
└── reviewtalk_app/                 # Flutter 프론트엔드
```

## 🛠️ 기술 스택

### 백엔드
- **FastAPI** + **Python 3.11+** + **uv** 패키지 관리
- **OpenAI GPT-4** (AI 챗봇)
- **ChromaDB** (벡터 데이터베이스)
- **Playwright** (다나와 크롤링)

### 프론트엔드
- **Flutter 3.16+** + **Dart**
- **MVVM + Clean Architecture**
- **Provider** (상태 관리)
- **Dio** (HTTP 클라이언트)

## 🚀 실행 방법

### 백엔드 서버 실행
```bash
cd reviewtalk-backend
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 프론트엔드 앱 실행
```bash
cd reviewtalk_app
flutter run -d chrome  # 웹 브라우저에서 실행
```

## ✅ Phase 1 완료 상태

- ✅ **백엔드**: FastAPI + uv 기반 Clean Architecture 구조 완성
- ✅ **프론트엔드**: Flutter + MVVM Clean Architecture 구조 완성  
- ✅ **서버-앱 연결**: HTTP 통신 및 API 클라이언트 동작 확인
- ✅ **개발환경**: Git 저장소 초기화 및 기본 설정 완료

## 🎯 다음 단계 (Phase 2)

1. **다나와 크롤러 연동** (45분)
   - POST /api/v1/crawl-reviews 엔드포인트 구현
   - Playwright 기반 리뷰 수집 기능

2. **AI 챗봇 엔진 구현** (60분)
   - ChromaDB + OpenAI 기반 RAG 시스템
   - POST /api/v1/chat 엔드포인트 구현

## 📚 문서

자세한 내용은 `docs/` 폴더의 문서를 참고하세요:
- [프로젝트 개요](docs/PROJECT_OVERVIEW.md)
- [Phase 1 체크포인트](docs/CHECKPOINTS_PHASE1.md)
- [Phase 2 체크포인트](docs/CHECKPOINTS_PHASE2.md)

---

**개발자**: 천주호  
**프로젝트 시작**: 2025-06-08  
**현재 단계**: Phase 1 완료 ✅ 