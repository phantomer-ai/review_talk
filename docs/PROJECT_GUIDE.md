# 리뷰톡 확장 가능한 MVP 개발 가이드
## MVVM 아키텍처 기반 체계적 구현

---

## 🛠️ **기술 스택**

### Backend
- **Framework**: FastAPI 0.104+
- **Language**: Python 3.9+
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
- **HTTP Client**: httpx
- **Environment**: python-dotenv
- **Testing**: pytest, pytest-asyncio

### Frontend
- **Framework**: Flutter 3.16+
- **Language**: Dart 3.2+
- **Architecture**: MVVM + Clean Architecture
- **State Management**: Provider 6.1+
- **HTTP**: dio 5.4+ (http 대신 더 강력한 기능)
- **Dependency Injection**: get_it 7.6+
- **Local Storage**: 
  - shared_preferences (설정 저장)
  - hive (구조화된 데이터)
- **UI Components**:
  - flutter_spinkit (로딩 애니메이션)
  - fluttertoast (알림)
  - cached_network_image (이미지 캐싱)
- **Network**: connectivity_plus (네트워크 상태)
- **Utils**: 
  - equatable (객체 비교)
  - dartz (함수형 프로그래밍 - Either)
  - uuid (고유 ID 생성)

### DevOps & Tools
- **Package Manager**: uv (Python 의존성 관리)
- **API Documentation**: FastAPI 자동 문서화 (Swagger)
- **Deployment**: 
  - Backend: Railway (추천) - GitHub 자동 배포
  - Database: Railway PostgreSQL (무료)
  - Frontend: APK 직접 배포 → Play Store 준비
- **Version Control**: Git + GitHub
- **API Testing**: Postman, Thunder Client
- **Code Quality**: 
  - Backend: black, flake8, mypy (uv scripts로 관리)
  - Frontend: flutter_lints

### 외부 API & Services
- **OpenAI API**: GPT-4, Embeddings
- **크롤링 타겟**: 다나와 (Playwright 기반)
- **배포**: Railway (백엔드), APK 직배포 (프론트)
- **Push Notifications**: Firebase Cloud Messaging (미래 확장)

---

## 🎯 **목표: 확장성 있는 MVP**

**완성 목표:**
- ✅ 깔끔한 MVVM 구조로 구현
- ✅ 새로운 기능 추가가 쉬운 아키텍처
- ✅ 코드 재사용성 극대화
- ✅ 유지보수 용이한 구조
- ✅ 프로덕션 레벨의 코드 품질

**확장 계획:**
- 🚀 상품 비교 기능
- 🚀 유튜브 리뷰 연동
- 🚀 광고 리뷰 필터링
- 🚀 사용자 맞춤 추천

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
│ (SharedPrefs)   │            │     (FAISS)      │
└─────────────────┘            └──────────────────┘
```

### 폴더 구조
```
reviewtalk/
├── backend/                           # FastAPI 백엔드
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                   # FastAPI 앱 진입점
│   │   ├── core/                     # 핵심 설정
│   │   │   ├── config.py            # 환경변수, 설정
│   │   │   └── dependencies.py      # DI 컨테이너
│   │   ├── api/                     # API 엔드포인트
│   │   │   ├── __init__.py
│   │   │   ├── routes/
│   │   │   │   ├── crawl.py         # 크롤링 API
│   │   │   │   ├── chat.py          # 챗봇 API
│   │   │   │   └── product.py       # 상품 관리 API
│   │   │   └── deps.py              # API 의존성
│   │   ├── services/                # 비즈니스 로직
│   │   │   ├── crawl_service.py     # 크롤링 서비스
│   │   │   ├── ai_service.py        # AI 챗봇 서비스
│   │   │   └── product_service.py   # 상품 관리 서비스
│   │   ├── models/                  # 데이터 모델
│   │   │   ├── schemas.py           # Pydantic 스키마
│   │   │   └── entities.py          # 도메인 엔티티
│   │   ├── infrastructure/          # 외부 의존성
│   │   │   ├── crawler/
│   │   │   │   ├── danawa_crawler.py
│   │   │   │   └── base_crawler.py  # 확장 가능한 크롤러 인터페이스
│   │   │   ├── ai/
│   │   │   │   ├── openai_client.py
│   │   │   │   ├── langchain_rag.py
│   │   │   │   └── vector_store.py
│   │   │   └── storage/
│   │   │       └── file_storage.py
│   │   └── utils/
│   │       ├── logger.py
│   │       └── exceptions.py
│   ├── requirements.txt
│   └── .env
└── frontend/                          # Flutter 앱 (MVVM)
    ├── lib/
    │   ├── main.dart                 # 앱 진입점
    │   ├── app/                      # 앱 설정
    │   │   ├── app.dart             # MaterialApp 설정
    │   │   ├── routes.dart          # 라우팅 설정
    │   │   └── themes.dart          # 테마 설정
    │   ├── core/                     # 핵심 기능
    │   │   ├── constants/           # 상수
    │   │   │   ├── api_constants.dart
    │   │   │   ├── app_constants.dart
    │   │   │   └── string_constants.dart
    │   │   ├── errors/              # 에러 처리
    │   │   │   ├── exceptions.dart
    │   │   │   └── failures.dart
    │   │   ├── network/             # 네트워크
    │   │   │   ├── api_client.dart
    │   │   │   └── network_info.dart
    │   │   └── utils/               # 유틸리티
    │   │       ├── validators.dart
    │   │       └── formatters.dart
    │   ├── data/                     # 데이터 레이어
    │   │   ├── datasources/         # 데이터 소스
    │   │   │   ├── remote/
    │   │   │   │   ├── review_api.dart
    │   │   │   │   └── chat_api.dart
    │   │   │   └── local/
    │   │   │       └── app_database.dart
    │   │   ├── models/              # 데이터 모델
    │   │   │   ├── review_model.dart
    │   │   │   ├── chat_model.dart
    │   │   │   └── product_model.dart
    │   │   └── repositories/        # 리포지토리 구현
    │   │       ├── review_repository_impl.dart
    │   │       └── chat_repository_impl.dart
    │   ├── domain/                   # 도메인 레이어
    │   │   ├── entities/            # 도메인 엔티티
    │   │   │   ├── review.dart
    │   │   │   ├── chat_message.dart
    │   │   │   └── product.dart
    │   │   ├── repositories/        # 리포지토리 인터페이스
    │   │   │   ├── review_repository.dart
    │   │   │   └── chat_repository.dart
    │   │   └── usecases/            # 유스케이스
    │   │       ├── crawl_reviews.dart
    │   │       ├── send_message.dart
    │   │       └── get_suggestions.dart
    │   ├── presentation/             # 프레젠테이션 레이어
    │   │   ├── viewmodels/          # ViewModel (MVVM)
    │   │   │   ├── base_viewmodel.dart
    │   │   │   ├── url_input_viewmodel.dart
    │   │   │   ├── chat_viewmodel.dart
    │   │   │   └── loading_viewmodel.dart
    │   │   ├── views/               # View (UI)
    │   │   │   ├── screens/
    │   │   │   │   ├── url_input_screen.dart
    │   │   │   │   ├── loading_screen.dart
    │   │   │   │   └── chat_screen.dart
    │   │   │   └── widgets/
    │   │   │       ├── common/
    │   │   │       │   ├── loading_widget.dart
    │   │   │       │   ├── error_widget.dart
    │   │   │       │   └── custom_button.dart
    │   │   │       ├── url_input/
    │   │   │       │   └── url_input_form.dart
    │   │   │       └── chat/
    │   │   │           ├── message_bubble.dart
    │   │   │           ├── suggested_questions.dart
    │   │   │           └── chat_input.dart
    │   │   └── providers/           # Provider 설정
    │   │       └── app_providers.dart
    │   └── injection_container.dart  # 의존성 주입
    ├── pubspec.yaml
    └── analysis_options.yaml
```

---

## 🔧 **백엔드 아키텍처 (Clean Architecture)**

### 1. 핵심 설정
```python
# backend/app/core/config.py
from pydantic import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # API 설정
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "ReviewTalk API"
    
    # OpenAI 설정
    OPENAI_API_KEY: str
    
    # 크롤링 설정
    MAX_REVIEWS: int = 50
    CRAWL_TIMEOUT: int = 30
    
    # CORS 설정
    CORS_ORIGINS: list = ["http://localhost:3000", "*"]
    
    # 벡터 DB 설정
    VECTOR_DB_PATH: str = "./data/vector_store"
    
    class Config:
        env_file = ".env"

settings = Settings()
```

### 2. 도메인 엔티티
```python
# backend/app/models/entities.py
from dataclasses import dataclass
from typing import List, Optional
from datetime import datetime

@dataclass
class Review:
    content: str
    rating: Optional[int] = None
    date: Optional[datetime] = None
    author: Optional[str] = None

@dataclass
class Product:
    id: str
    name: str
    url: str
    price: Optional[str] = None
    rating: Optional[float] = None
    reviews: List[Review] = None
    created_at: datetime = None

@dataclass
class ChatMessage:
    question: str
    answer: str
    confidence: float
    source_reviews: List[str]
    response_time: float
```

### 3. 서비스 레이어
```python
# backend/app/services/ai_service.py
from abc import ABC, abstractmethod
from typing import List
from ..models.entities import Review, ChatMessage

class AIServiceInterface(ABC):
    @abstractmethod
    async def generate_answer(self, question: str, reviews: List[Review]) -> ChatMessage:
        pass

class OpenAIService(AIServiceInterface):
    def __init__(self, openai_client, vector_store):
        self.openai_client = openai_client
        self.vector_store = vector_store
    
    async def generate_answer(self, question: str, reviews: List[Review]) -> ChatMessage:
        # RAG 기반 답변 생성 로직
        # 1. 질문과 관련된 리뷰 검색
        # 2. 컨텍스트 구성
        # 3. GPT 답변 생성
        # 4. 신뢰도 계산
        pass

# 확장성: 다른 AI 모델도 쉽게 추가 가능
class HuggingFaceService(AIServiceInterface):
    async def generate_answer(self, question: str, reviews: List[Review]) -> ChatMessage:
        # HuggingFace 모델 사용
        pass
```

### 4. API 엔드포인트
```python
# backend/app/api/routes/chat.py
from fastapi import APIRouter, Depends, HTTPException
from typing import List
from ...services.ai_service import AIServiceInterface
from ...models.schemas import ChatRequest, ChatResponse
from ...core.dependencies import get_ai_service

router = APIRouter()

@router.post("/chat", response_model=ChatResponse)
async def chat_with_reviews(
    request: ChatRequest,
    ai_service: AIServiceInterface = Depends(get_ai_service)
):
    try:
        result = await ai_service.generate_answer(
            question=request.question,
            reviews=request.reviews
        )
        return ChatResponse.from_entity(result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

---

## 📱 **Flutter MVVM 아키텍처**

### 1. Domain Layer (비즈니스 로직)
```dart
// lib/domain/entities/chat_message.dart
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final double? confidence;
  final List<String>? sourceReviews;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.confidence,
    this.sourceReviews,
  });
}

// lib/domain/repositories/chat_repository.dart
abstract class ChatRepository {
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String productId,
    required String question,
  });
  
  Future<Either<Failure, List<String>>> getSuggestions(String productId);
}

// lib/domain/usecases/send_message.dart
class SendMessage {
  final ChatRepository repository;
  
  SendMessage(this.repository);
  
  Future<Either<Failure, ChatMessage>> call({
    required String productId,
    required String question,
  }) async {
    return await repository.sendMessage(
      productId: productId,
      question: question,
    );
  }
}
```

### 2. Data Layer (데이터 관리)
```dart
// lib/data/models/chat_model.dart
class ChatModel extends ChatMessage {
  const ChatModel({
    required String id,
    required String text,
    required bool isUser,
    required DateTime timestamp,
    double? confidence,
    List<String>? sourceReviews,
  }) : super(
    id: id,
    text: text,
    isUser: isUser,
    timestamp: timestamp,
    confidence: confidence,
    sourceReviews: sourceReviews,
  );

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['answer'] ?? json['text'],
      isUser: json['is_user'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      confidence: json['confidence']?.toDouble(),
      sourceReviews: json['source_reviews']?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'source_reviews': sourceReviews,
    };
  }
}

// lib/data/datasources/remote/chat_api.dart
abstract class ChatApiDataSource {
  Future<ChatModel> sendMessage({
    required String productId,
    required String question,
  });
}

class ChatApiDataSourceImpl implements ChatApiDataSource {
  final ApiClient apiClient;
  
  ChatApiDataSourceImpl({required this.apiClient});
  
  @override
  Future<ChatModel> sendMessage({
    required String productId,
    required String question,
  }) async {
    final response = await apiClient.post(
      '/api/v1/chat',
      data: {
        'product_id': productId,
        'question': question,
      },
    );
    
    return ChatModel.fromJson(response);
  }
}

// lib/data/repositories/chat_repository_impl.dart
class ChatRepositoryImpl implements ChatRepository {
  final ChatApiDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  
  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });
  
  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String productId,
    required String question,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.sendMessage(
          productId: productId,
          question: question,
        );
        return Right(result);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(ConnectionFailure());
    }
  }
}
```

### 3. Presentation Layer (MVVM)
```dart
// lib/presentation/viewmodels/base_viewmodel.dart
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

// lib/presentation/viewmodels/chat_viewmodel.dart
class ChatViewModel extends BaseViewModel {
  final SendMessage sendMessageUseCase;
  final GetSuggestions getSuggestionsUseCase;
  
  ChatViewModel({
    required this.sendMessageUseCase,
    required this.getSuggestionsUseCase,
  });
  
  List<ChatMessage> _messages = [];
  List<String> _suggestions = [];
  String? _currentProductId;
  
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<String> get suggestions => List.unmodifiable(_suggestions);
  String? get currentProductId => _currentProductId;
  
  Future<void> initializeChat(String productId) async {
    _currentProductId = productId;
    await loadSuggestions();
  }
  
  Future<void> sendMessage(String question) async {
    if (_currentProductId == null) return;
    
    // 사용자 메시지 추가
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: question,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    _messages.add(userMessage);
    notifyListeners();
    
    setLoading(true);
    clearError();
    
    final result = await sendMessageUseCase.call(
      productId: _currentProductId!,
      question: question,
    );
    
    result.fold(
      (failure) => setError(_mapFailureToMessage(failure)),
      (response) {
        _messages.add(response);
        notifyListeners();
      },
    );
    
    setLoading(false);
  }
  
  Future<void> loadSuggestions() async {
    if (_currentProductId == null) return;
    
    final result = await getSuggestionsUseCase.call(_currentProductId!);
    result.fold(
      (failure) => {}, // 추천 질문 로딩 실패는 조용히 처리
      (suggestions) {
        _suggestions = suggestions;
        notifyListeners();
      },
    );
  }
  
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
  
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return '서버 오류가 발생했습니다.';
      case ConnectionFailure:
        return '인터넷 연결을 확인해주세요.';
      default:
        return '알 수 없는 오류가 발생했습니다.';
    }
  }
}

// lib/presentation/views/screens/chat_screen.dart
class ChatScreen extends StatelessWidget {
  final String productId;
  
  const ChatScreen({Key? key, required this.productId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => sl<ChatViewModel>()..initializeChat(productId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('리뷰톡'),
          backgroundColor: AppColors.primary,
        ),
        body: const ChatView(),
      ),
    );
  }
}

class ChatView extends StatelessWidget {
  const ChatView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // 제품 정보 표시
            ProductInfoWidget(),
            
            // 추천 질문
            if (viewModel.suggestions.isNotEmpty)
              SuggestedQuestionsWidget(
                suggestions: viewModel.suggestions,
                onQuestionSelected: viewModel.sendMessage,
              ),
            
            // 채팅 메시지 리스트
            Expanded(
              child: MessageListWidget(messages: viewModel.messages),
            ),
            
            // 로딩 인디케이터
            if (viewModel.isLoading)
              const LoadingWidget(),
            
            // 에러 메시지
            if (viewModel.errorMessage != null)
              ErrorWidget(
                message: viewModel.errorMessage!,
                onRetry: viewModel.clearError,
              ),
            
            // 메시지 입력
            ChatInputWidget(
              onSend: viewModel.sendMessage,
              enabled: !viewModel.isLoading,
            ),
          ],
        );
      },
    );
  }
}
```

### 4. 의존성 주입
```dart
// lib/injection_container.dart
final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => InternetConnectionChecker());

  // Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );
  sl.registerLazySingleton<ApiClient>(
    () => ApiClientImpl(httpClient: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ChatApiDataSource>(
    () => ChatApiDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => GetSuggestions(sl()));

  // ViewModels
  sl.registerFactory(
    () => ChatViewModel(
      sendMessageUseCase: sl(),
      getSuggestionsUseCase: sl(),
    ),
  );
}
```

### 5. 환경 설정 및 설치

### 5. 환경 설정 및 설치

#### Backend 설치 (uv 사용)
```bash
# uv 설치 (없다면)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 프로젝트 초기화
uv init reviewtalk-backend
cd reviewtalk-backend

# Python 버전 설정
uv python pin 3.11

# 의존성 설치
uv add fastapi uvicorn[standard] pydantic python-multipart python-dotenv
uv add openai langchain langchain-openai chromadb sentence-transformers
uv add playwright beautifulsoup4 requests
uv add sqlalchemy alembic
uv add --dev pytest pytest-asyncio httpx black flake8 mypy

# Playwright 브라우저 설치
uv run playwright install
```

#### 개발 서버 실행
```bash
# uv로 서버 실행
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 또는 스크립트로 등록
# pyproject.toml에 추가:
[tool.uv.scripts]
dev = "uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
test = "pytest"
lint = "black . && flake8 ."

# 실행
uv run dev
```

```toml
# backend/pyproject.toml (uv가 자동 생성)
[project]
name = "reviewtalk-backend"
version = "0.1.0"
description = "리뷰톡 백엔드 API 서버"
requires-python = ">=3.11"

dependencies = [
    # Core
    "fastapi>=0.104.1",
    "uvicorn[standard]>=0.24.0",
    "pydantic>=2.5.0",
    "python-multipart>=0.0.6",
    "python-dotenv>=1.0.0",
    
    # AI/ML
    "openai>=1.3.0",
    "langchain>=0.1.0",
    "langchain-openai>=0.0.2",
    "chromadb>=0.4.18",
    "sentence-transformers>=2.2.2",
    
    # Crawling
    "playwright>=1.40.0",
    "beautifulsoup4>=4.12.2",
    "requests>=2.31.0",
    
    # Database
    "sqlalchemy>=2.0.23",
    "alembic>=1.13.0",
    
    # Utils
    "python-dateutil>=2.8.2",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.3",
    "pytest-asyncio>=0.21.1",
    "httpx>=0.25.2",
    "black>=23.0.0",
    "flake8>=6.0.0",
    "mypy>=1.7.0",
]

[tool.uv.scripts]
dev = "uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
test = "pytest"
lint = "black . && flake8 ."
type-check = "mypy ."

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

#### Flutter 설치
```yaml
# frontend/pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Core
  dio: ^5.4.0
  get_it: ^7.6.4
  provider: ^6.1.1
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # UI
  flutter_spinkit: ^5.2.0
  fluttertoast: ^8.2.4
  cached_network_image: ^3.3.0
  
  # Utils
  equatable: ^2.0.5
  dartz: ^0.10.1
  uuid: ^4.2.1
  connectivity_plus: ^5.0.2
  
  # Development
  flutter_lints: ^3.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

#### 환경변수 설정
```bash
# backend/.env
OPENAI_API_KEY=sk-your-openai-api-key-here
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://10.0.2.2:3000
DEBUG=true
LOG_LEVEL=INFO
MAX_REVIEWS=50
CRAWL_TIMEOUT=30
VECTOR_DB_PATH=./data/vector_store
DATABASE_URL=sqlite:///./reviewtalk.db
```

---

## 🔧 **개발 단계별 가이드**

### Phase 1: 백엔드 기반 구축 (2시간)
1. **프로젝트 구조 생성**
2. **핵심 서비스 구현** (크롤링, AI)
3. **API 엔드포인트 구현**
4. **Postman 테스트**

### Phase 2: Flutter 기반 구축 (2.5시간)
1. **Domain Layer** - 엔티티, 유스케이스
2. **Data Layer** - 모델, 리포지토리
3. **Presentation Layer** - ViewModel, View
4. **의존성 주입 설정**

### Phase 3: 통합 및 테스트 (2시간)
1. **API 연동 테스트**
2. **전체 플로우 검증**
3. **에러 처리 강화**
4. **UI/UX polish**

### Phase 4: 최적화 및 배포 준비 (1.5시간)
1. **성능 최적화**
2. **코드 리팩토링**
3. **APK 빌드**
4. **데모 준비**

---

## 🚀 **확장성 고려사항**

### 새로운 크롤러 추가
```python
# 새로운 쇼핑몰 크롤러 추가시
class CoupangCrawler(BaseCrawler):
    def crawl(self, url: str) -> List[Review]:
        # 쿠팡 크롤링 로직
        pass

# 설정만 변경하면 자동으로 적용됨
```

### 새로운 AI 모델 추가
```python
# 새로운 AI 서비스 추가시
class ClaudeService(AIServiceInterface):
    async def generate_answer(self, question: str, reviews: List[Review]) -> ChatMessage:
        # Claude API 사용
        pass
```

### 새로운 화면 추가
```dart
// 새로운 기능 화면 추가시
class ComparisonViewModel extends BaseViewModel {
  // 상품 비교 로직
}

class ComparisonScreen extends StatelessWidget {
  // 상품 비교 UI
}
```

---

## 📋 **Cursor AI 활용 가이드**

### 1. 파일별 구현 요청
```
@docs/PROJECT_GUIDE.md 를 참고해서 backend/app/services/ai_service.py를 구현해주세요.

요구사항:
- AIServiceInterface 추상 클래스
- OpenAIService 구현체
- RAG 기반 답변 생성
- 에러 처리 포함
- 확장 가능한 구조로 설계
```

### 2. Flutter ViewModel 구현
```
@docs/PROJECT_GUIDE.md의 MVVM 구조를 따라 ChatViewModel을 구현해주세요.

요구사항:
- BaseViewModel 상속
- Provider 패턴 사용
- 적절한 상태 관리
- 에러 처리 및 로딩 상태
- 유스케이스 의존성 주입
```

### 3. 통합 테스트 요청
```
현재 구현된 백엔드와 Flutter 앱을 연동해서 전체 플로우가 작동하는지 확인해주세요.

확인사항:
- API 연결 상태
- 데이터 직렬화/역직렬화
- 에러 처리 동작
- UI 상태 변경
```

이 구조로 개발하면 **견고하고 확장 가능한 MVP**가 될 거야! 🎯