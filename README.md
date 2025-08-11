# ReviewTalk 프로젝트 🚀

**다나와 상품 리뷰를 AI가 분석하여 사용자 질문에 실시간으로 답변하는 모바일 챗봇 애플리케이션**

## 🌟 주요 기능

- **AI 기반 리뷰 분석**: LLM(대규모 언어 모델)을 활용하여 수많은 상품 리뷰를 분석하고 핵심 내용을 요약합니다.
- **실시간 대화형 Q&A**: 사용자는 채팅을 통해 상품의 장단점, 가성비, 특정 기능에 대한 실제 후기 등을 자유롭게 질문할 수 있습니다.
- **다나와 상품 지원**: 다나와에 등록된 상품 URL만 입력하면 해당 상품의 리뷰를 기반으로 AI 챗봇을 시작할 수 있습니다.
- **다중 LLM 지원**: OpenAI의 GPT, Google의 Gemini, 그리고 로컬에서 실행 가능한 Qwen3 등 다양한 AI 모델을 지원합니다.

## 🏗️ 아키텍처

```
┌─────────────────┐      API       ┌──────────────────┐
│   Flutter App   │ ◄────────────► │   FastAPI Server │
│(MVVM + Clean)   │                │  (Clean Arch)    │
└─────────────────┘                └──────────────────┘
         │                                │
         ▼                                ▼
┌─────────────────┐              ┌──────────────────┐
│  Local Storage  │              │  Vector Database │
│(SharedPrefs)    │              │     (ChromaDB)   │
└─────────────────┘              └──────────────────┘
```

## 🤖 지원하는 AI 모델들

| 모델 | 제공업체 | 장점 | 비용 | 추천 용도 |
|------|----------|------|------|-----------|
| **GPT-4o** | OpenAI | 높은 품질, 안정성 | 유료 | 프로덕션 환경 |
| **Gemini 1.5 Pro** | Google | 빠른 속도, 긴 컨텍스트 | 유료 | 대량 데이터 처리 |
| **Qwen3** | Alibaba Cloud | **무료**, 한국어 우수 | **무료** | 개발/테스트 환경 |

### 🌟 Qwen3를 추가한 이유

1. **💰 비용 절약**: 완전 무료로 로컬에서 실행
2. **🇰🇷 한국어 성능**: 한국어 리뷰 분석에 특화된 성능
3. **🔒 개인정보 보호**: 데이터가 외부로 전송되지 않음
4. **⚡ 빠른 응답**: 로컬 실행으로 네트워크 지연 없음
5. **🧪 개발 친화적**: API 키 없이 바로 테스트 가능

## 📋 프로젝트 구조

```
reviewtalk/
├── docs/                           # 프로젝트 문서
├── reviewtalk-backend/             # FastAPI 백엔드
│   ├── app/
│   │   ├── api/routes/            # API 엔드포인트
│   │   ├── infrastructure/ai/     # AI 모델 클라이언트
│   │   ├── services/              # 비즈니스 로직
│   │   └── models/                # 데이터 모델
│   ├── .env                       # 환경변수 (생성 필요)
│   └── pyproject.toml             # Python 의존성
└── reviewtalk_app/                # Flutter 프론트엔드
    ├── lib/
    │   ├── core/                  # 공통 기능
    │   ├── data/                  # 데이터 레이어
    │   ├── domain/                # 도메인 레이어
    │   └── presentation/          # UI 레이어
    └── pubspec.yaml               # Flutter 의존성
```

## 🛠️ 기술 스택

### 백엔드
- **FastAPI** + **Python 3.11+** + **uv** 패키지 관리
- **다중 AI 모델 지원**:
  - OpenAI GPT-4o
  - Google Gemini 1.5 Pro
  - **Qwen3 (로컬)**
- **ChromaDB** (벡터 데이터베이스)
- **SQLite** (메인 데이터베이스)
- **Playwright** (다나와 크롤링)

### 프론트엔드
- **Flutter 3.16+** + **Dart**
- **MVVM + Clean Architecture**
- **Provider** (상태 관리)
- **Dio** (HTTP 클라이언트)

## ⚙️ 설치 및 설정

### 1. Qwen3 설치 (권장 - 무료)

```bash
# Ollama 설치
brew install ollama

# Ollama 서버 시작
brew services start ollama

# Qwen3 모델 다운로드 (5.2GB)
ollama pull qwen2.5:3b

# 설치 확인
ollama list
```

### 2. 환경변수 설정

```bash
cd reviewtalk-backend
cp .env.example .env  # 예시 파일이 있다면
```

`.env` 파일 생성 및 편집:

#### Qwen3 사용 (무료, 권장)
```bash
# AI/LLM 설정
LLM_PROVIDER=qwen3
LOCAL_LLM_BASE_URL=http://localhost:11434/v1
LOCAL_LLM_MODEL=qwen2.5:3b
LOCAL_LLM_API_KEY=not-needed

# 데이터베이스
DATABASE_URL=sqlite:///./data/reviewtalk.db

# CORS 설정
CORS_ORIGINS=["*"]
```

#### OpenAI 사용 (유료)
```bash
LLM_PROVIDER=openai
OPENAI_API_KEY=your-actual-api-key
OPENAI_MODEL=gpt-4o
```

### 3. 의존성 설치

#### 백엔드
```bash
cd reviewtalk-backend
uv sync
```

#### 프론트엔드
```bash
cd reviewtalk_app
flutter pub get
```

## 🚀 실행 방법

### 1. 백엔드 서버 실행
```bash
cd reviewtalk-backend
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. 프론트엔드 앱 실행
```bash
cd reviewtalk_app
flutter run -d chrome  # 웹 브라우저에서 실행
# 또는
flutter run -d macos   # macOS 앱으로 실행
```

### 3. API 문서 확인
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **헬스 체크**: http://localhost:8000/health

## 🔄 모델 변경 방법

### 실시간 모델 전환
1. `.env` 파일에서 `LLM_PROVIDER` 변경
2. 서버 재시작
3. 로그에서 사용 중인 모델 확인

```bash
# 로그 예시
[AIClient.__init__] 로컬 LLM 모델: qwen2.5:3b, Base URL: http://localhost:11434/v1
```

## 🧪 테스트 방법

### 1. Qwen3 테스트
```bash
# Ollama로 직접 테스트
ollama run qwen2.5:3b "다나와에서 구매한 이어폰 리뷰를 분석해줘"
```

### 2. API 테스트
```bash
curl -X POST "http://localhost:8000/api/v1/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "이 제품의 장단점이 뭐야?", "product_url": "danawa_url"}'
```

### 3. Flutter 테스트
```bash
cd reviewtalk_app
flutter test
```

## 🏗️ 프로젝트 현황

### ✅ 완료된 기능
- ✅ **다중 LLM 지원**: OpenAI, Gemini, Qwen3
- ✅ **백엔드**: FastAPI + Clean Architecture
- ✅ **프론트엔드**: Flutter + MVVM Architecture
- ✅ **AI 분석**: 리뷰 분석 및 요약
- ✅ **크롤링**: 다나와 상품 리뷰 수집
- ✅ **벡터 검색**: ChromaDB 기반 유사 리뷰 검색
- ✅ **채팅 기능**: 실시간 AI 챗봇
- ✅ **데이터 저장**: SQLite + 벡터 DB

### 🎯 다음 계획
- 🔄 **성능 최적화**: 모델별 응답 속도 개선
- 📱 **모바일 앱**: iOS/Android 네이티브 앱
- 🌐 **배포**: Docker + Cloud 배포
- 🔍 **검색 개선**: 더 정확한 리뷰 검색

## 📊 성능 비교

| 모델 | 응답속도 | 한국어 품질 | 비용 | 안정성 |
|------|----------|-------------|------|--------|
| GPT-4o | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 💰💰💰 | ⭐⭐⭐⭐⭐ |
| Gemini 1.5 Pro | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 💰💰 | ⭐⭐⭐⭐ |
| **Qwen3** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | **무료** | ⭐⭐⭐⭐ |

## 🔧 문제해결

### Qwen3 관련
```bash
# Ollama 서비스 재시작
brew services restart ollama

# 모델 재다운로드
ollama pull qwen2.5:3b

# 모델 삭제 후 재설치
ollama rm qwen2.5:3b
ollama pull qwen2.5:3b
```

### 백엔드 문제
```bash
# 데이터베이스 초기화
cd reviewtalk-backend
rm -rf data/reviewtalk.db
uv run python app/database_migration.py

# 의존성 재설치
uv sync --reinstall
```

### 프론트엔드 문제
```bash
# Flutter 캐시 정리
flutter clean
flutter pub get

# 빌드 정리
rm -rf build/
flutter run
```

## 📚 문서

- [프로젝트 개요](docs/PROJECT_OVERVIEW.md)
- [체크포인트](docs/CHECKPOINTS_PHASE1.md)
- [API 문서](http://localhost:8000/docs)
- [ERD](reviewtalk-backend/ERD.md)

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

---

**개발자**: 천주호  
**프로젝트 시작**: 2025-01-08  
**현재 상태**: 다중 LLM 지원 완료 ✅  
**저장소**: [GitHub](https://github.com/phantomer-ai/review_talk)