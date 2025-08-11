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

### 1. 사전 준비: Qwen3 설치 (무료 개발 환경)
```bash
# Ollama 설치 (macOS)
brew install ollama

# Ollama 서버 시작
brew services start ollama

# Qwen3 모델 다운로드 (약 5.2GB)
ollama pull qwen3
```

### 2. 백엔드 설정 및 실행
```bash
# 1. 백엔드 디렉토리로 이동
cd reviewtalk-backend

# 2. 환경변수 파일 생성
cp env.example.txt .env

# 3. .env 파일 수정 (기본값은 Qwen3로 설정되어 있음)
# LLM_PROVIDER=qwen3
# LOCAL_LLM_BASE_URL=http://localhost:11434/v1
# ...

# 4. Python 의존성 설치
uv sync

# 5. Playwright 브라우저 드라이버 설치
uv run playwright install

# 6. 개발 서버 실행
uv run dev
```
서버가 `http://localhost:8000`에서 실행됩니다. API 문서는 `http://localhost:8000/docs`에서 확인할 수 있습니다.

### 3. 프론트엔드 설정 및 실행
```bash
# 1. 프론트엔드 디렉토리로 이동
cd reviewtalk_app

# 2. Flutter 의존성 설치
flutter pub get

# 3. 앱 실행 (웹, 모바일 등)
flutter run -d chrome
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