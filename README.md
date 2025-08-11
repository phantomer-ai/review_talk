# ReviewTalk 프로젝트 🚀

**다나와 상품 리뷰를 AI가 분석하여 사용자 질문에 실시간으로 답변하는 모바일 챗봇 애플리케이션**

이 프로젝트는 최신 AI 기술과 모바일 앱 개발 프레임워크를 결합하여, 사용자가 상품에 대해 더 깊이 이해하고 합리적인 구매 결정을 내릴 수 있도록 돕는 것을 목표로 합니다.

## 🌟 주요 기능

- **AI 기반 리뷰 분석**: LLM(대규모 언어 모델)을 활용하여 수많은 상품 리뷰를 분석하고 핵심 내용을 요약합니다.
- **실시간 대화형 Q&A**: 사용자는 채팅을 통해 상품의 장단점, 가성비, 특정 기능에 대한 실제 후기 등을 자유롭게 질문할 수 있습니다.
- **다나와 상품 지원**: 다나와에 등록된 상품 URL만 입력하면 해당 상품의 리뷰를 기반으로 AI 챗봇을 시작할 수 있습니다.
- **다중 LLM 지원**: OpenAI의 GPT, Google의 Gemini, 그리고 로컬에서 실행 가능한 Qwen3 등 다양한 AI 모델을 지원하여 유연성과 확장성을 확보했습니다.

## 🏗️ 아키텍처

이 프로젝트는 확장성과 유지보수성을 고려하여 프론트엔드와 백엔드를 명확히 분리하고, 각각 체계적인 아키텍처 패턴을 적용했습니다.

```
┌─────────────────┐      API       ┌──────────────────┐
│   Flutter App   │ ◄────────────► │   FastAPI Server │
│(MVVM + Clean Arch)│              │  (Clean Architecture)  │
└─────────────────┘                └──────────────────┘
         │                                │
         ▼                                ▼
┌─────────────────┐              ┌──────────────────┐
│  Local Storage  │              │  Vector Database │
│(SharedPreferences)│              │     (ChromaDB)   │
└─────────────────┘              └──────────────────┘
```

### Frontend (Flutter)
- **MVVM + Clean Architecture**: UI(View), 상태 및 로직(ViewModel), 비즈니스 규칙(Domain), 데이터 처리(Data)를 명확히 분리하여 코드의 재사용성과 테스트 용이성을 극대화했습니다.
- **Provider**: 상태 관리를 위해 사용하여 위젯 트리에 상태를 효율적으로 전파합니다.
- **GetIt**: 의존성 주입(DI)을 통해 각 레이어 간의 결합도를 낮춥니다.

### Backend (FastAPI)
- **Clean Architecture**: API 엔드포인트, 비즈니스 로직(Services), 데이터 모델, 외부 인프라(AI, DB)를 계층적으로 분리하여 유연하고 확장 가능한 구조를 구현했습니다.
- **RAG (Retrieval-Augmented Generation)**: LangChain과 ChromaDB(벡터 DB)를 활용하여, 사용자 질문과 가장 관련 높은 리뷰를 먼저 찾고 이를 기반으로 LLM이 정확한 답변을 생성하도록 합니다.

## 🛠️ 기술 스택

| 구분 | 기술 | 설명 |
| :--- | :--- | :--- |
| **Frontend** | Flutter, Dart | 크로스플랫폼 모바일 앱 개발 |
| | Provider, GetIt | 상태 관리 및 의존성 주입 |
| | Dio, dartz | 강력한 HTTP 통신 및 함수형 프로그래밍 |
| **Backend** | FastAPI, Python | 고성능 비동기 웹 프레임워크 |
| | LangChain, OpenAI, Gemini | RAG 구현 및 LLM 연동 |
| | ChromaDB, Sentence-Transformers | 벡터 데이터베이스 및 텍스트 임베딩 |
| | Playwright | 동적 웹 페이지 크롤링 |
| **Package Manager** | uv (Python) | 빠르고 효율적인 Python 의존성 관리 |
| **Deployment** | Railway (Backend), Play Store (Frontend) | 추천 배포 환경 |

## 🤖 지원하는 AI 모델

ReviewTalk은 다양한 LLM 모델을 지원하며, `.env` 파일 설정만으로 쉽게 전환할 수 있습니다.

| 모델 | 제공업체 | 장점 | 비용 | 추천 용도 |
| :--- | :--- | :--- | :--- | :--- |
| **GPT-4o** | OpenAI | 최고의 품질, 안정성 | 유료 | 프로덕션 환경 |
| **Gemini 1.5 Pro**| Google | 빠른 속도, 긴 컨텍스트 | 유료 | 대량 데이터 처리 |
| **Qwen3** | Alibaba (Ollama) | **무료**, 우수한 한국어 성능 | **무료** | 개발 및 테스트 |

🌟 **로컬 Qwen3 모델을 사용하면 API 키 없이 완전 무료로 개발 및 테스트를 진행할 수 있습니다.**

## ⚙️ 설치 및 실행 방법

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

## 🧪 테스트 방법

### API 직접 호출 (cURL)
```bash
curl -X POST "http://localhost:8000/api/v1/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "이 제품의 장단점은 무엇인가요?", "product_url": "https://prod.danawa.com/info/?pcode=18233267"}'
```

## 🚀 향후 확장 계획

- **상품 비교 기능**: 여러 상품의 리뷰를 종합하여 비교 분석
- **유튜브 리뷰 연동**: 영상 리뷰를 텍스트로 변환하여 분석에 포함
- **광고성 리뷰 필터링**: 신뢰도 높은 리뷰만 선별하는 AI 필터 개발
- **사용자 맞춤 추천**: 사용자의 질문 패턴을 분석하여 개인화된 상품 추천

## 🤝 기여하기

이 프로젝트는 오픈소스로 진행됩니다. 개선 아이디어나 버그 리포트, 기능 추가 등 어떤 형태의 기여든 환영합니다.

1. 프로젝트를 Fork하세요.
2. 새로운 기능 브랜치를 만드세요 (`git checkout -b feature/AmazingFeature`).
3. 변경사항을 커밋하세요 (`git commit -m 'Add some AmazingFeature'`).
4. 브랜치에 푸시하세요 (`git push origin feature/AmazingFeature`).
5. Pull Request를 열어주세요.

---

**개발자**: 천주호  
**GitHub**: [https://github.com/phantomer-ai/review_talk](https://github.com/phantomer-ai/review_talk)