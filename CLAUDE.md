# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# ReviewTalk Project - Claude Development Guide

## Project Overview

ReviewTalk is a mobile chatbot application that analyzes Danawa product reviews using AI to answer user questions. It consists of a FastAPI backend and a Flutter frontend following clean architecture principles.

**Key Features:**
- Product review crawling from Danawa
- AI-powered Q&A using OpenAI GPT-4 and ChromaDB
- Cross-platform mobile app (Android/iOS)
- Real-time chat interface

## Project Structure

```
reviewtalk_mvp/
├── reviewtalk-backend/          # FastAPI Python backend
│   ├── app/
│   │   ├── main.py             # FastAPI application entry point
│   │   ├── core/               # Core configuration
│   │   ├── api/routes/         # API endpoints (chat.py, crawl.py)
│   │   ├── services/           # Business logic layer
│   │   ├── models/             # Pydantic schemas
│   │   ├── infrastructure/     # External integrations
│   │   └── utils/              # Utilities
│   ├── data/                   # Database and vector store
│   ├── pyproject.toml          # Python dependencies (uv)
│   └── env_template.txt        # Environment variables template
├── reviewtalk_app/             # Flutter mobile frontend
│   ├── lib/
│   │   ├── main.dart           # Flutter app entry point
│   │   ├── core/               # Constants, network, utils
│   │   ├── data/               # Data layer (APIs, models, repositories)
│   │   ├── domain/             # Domain layer (entities, use cases)
│   │   ├── presentation/       # UI layer (MVVM pattern)
│   │   └── injection_container.dart # Dependency injection
│   ├── pubspec.yaml            # Flutter dependencies
│   └── analysis_options.yaml   # Dart linting rules
└── docs/                       # Project documentation
    ├── PROJECT_OVERVIEW.md     # Detailed project overview
    └── CHECKPOINTS_*.md        # Development phase checkpoints
```

## Technology Stack

### Backend (Python)
- **Framework**: FastAPI 0.115+ with Python 3.11+
- **Package Manager**: uv for fast dependency management
- **AI/ML**: OpenAI GPT-4, ChromaDB (vector database), Sentence-Transformers
- **Web Scraping**: Playwright (primary), BeautifulSoup4 (parsing)
- **Database**: SQLite (development), ready for PostgreSQL scaling
- **Validation**: Pydantic v2 for data validation
- **Server**: Uvicorn ASGI server

### Frontend (Flutter)
- **Framework**: Flutter 3.16+ with Dart 3.2+
- **Architecture**: MVVM + Clean Architecture
- **State Management**: Provider 6.1+
- **HTTP Client**: Dio 5.4+ for API communication
- **Dependency Injection**: GetIt 7.6+
- **Local Storage**: SharedPreferences
- **UI**: Material Design 3

## Key Commands

### Backend Development
```bash
# Setup and run backend
cd reviewtalk-backend
uv install                                          # Install dependencies
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000  # Run development server

# Testing and quality assurance
uv run pytest                                      # Run all tests
uv run pytest tests/test_ai_service.py            # Run specific test file
uv run pytest -v                                  # Run tests with verbose output

# Database utilities
uv run python check_db.py                         # Quick database inspection
uv run python check_both_db.py                    # Check both main and special products databases
uv run python check_reviews.py                    # Review data inspection
uv run python test_special_deals.py               # Comprehensive special deals system test

# API documentation
# http://localhost:8000/docs                       # Swagger UI
# http://localhost:8000/redoc                      # ReDoc

# Special deals testing
python check_special_deals.py                     # Standalone special deals test (from root)
```

### Frontend Development
```bash
# Setup and run Flutter app
cd reviewtalk_app
flutter pub get                                     # Install dependencies
flutter run -d chrome                              # Run in web browser
flutter run                                        # Run on connected device/emulator

# Testing and quality assurance
flutter test                                       # Run all tests
flutter test test/widget_test.dart                 # Run specific test file
flutter test --coverage                            # Run tests with coverage
flutter analyze                                    # Static analysis

# Build commands
flutter build apk                                   # Build Android APK
flutter build ios                                  # Build iOS app
./android/gradlew assembleDebug                    # Android Gradle build

# Development utilities
flutter clean && flutter pub get                   # Clean and reinstall dependencies
flutter doctor                                     # Check Flutter installation
```

## API Endpoints

### Core Endpoints
- `GET /` - Root endpoint with API information
- `GET /health` - Health check endpoint
- `POST /api/v1/crawl-reviews` - Crawl Danawa product reviews
- `POST /api/v1/chat` - AI chat with review-based answers
- `GET /api/v1/product-overview` - Product review summary
- `GET /api/v1/database-stats` - Vector database statistics

### Request/Response Examples
```json
// POST /api/v1/crawl-reviews
{
  "product_url": "https://prod.danawa.com/info/?pcode=123456",
  "max_reviews": 20
}

// POST /api/v1/chat  
{
  "question": "배터리 성능이 어때요?",
  "product_id": "optional-product-id"
}
```

## Architecture Patterns

### Backend (Clean Architecture)
```
API Layer (FastAPI routes) 
    ↓
Service Layer (Business logic)
    ↓  
Infrastructure Layer (External APIs, DB)
```

### Frontend (MVVM + Clean Architecture)
```
Presentation Layer (Views + ViewModels)
    ↓
Domain Layer (Use Cases + Entities)
    ↓
Data Layer (Repositories + Data Sources)
```

## Environment Setup

### Backend Environment Variables
Create `.env` file from `env_template.txt`:
```bash
OPENAI_API_KEY=sk-your-openai-api-key-here
DATABASE_URL=sqlite:///./data/reviewtalk.db
CORS_ORIGINS=*
DEBUG=true
```

### Flutter Configuration
- Android emulator: Backend URL is `http://10.0.2.2:8000`
- iOS simulator: Backend URL is `http://localhost:8000`
- Physical device: Use your computer's IP address

## Development Workflow

### 1. Backend Development
- Use `uv` for fast Python package management
- Follow FastAPI best practices with Pydantic validation
- Implement services with dependency injection
- Add comprehensive error handling
- Use async/await for I/O operations

### 2. Frontend Development
- Follow Flutter clean architecture with MVVM
- Use Provider for state management
- Implement proper error handling and loading states
- Use GetIt for dependency injection
- Follow Material Design 3 guidelines

### 3. Testing Strategy
- **Backend**: pytest with comprehensive test coverage
  - `tests/test_ai_service.py`: AI service functionality
  - `tests/test_chat.py`: Chat API endpoints
  - `tests/test_conversation.py`: Conversation management
  - `tests/test_schemas.py`: Pydantic schema validation
  - Multiple database repository tests
- **Frontend**: Flutter testing framework
  - `test/widget_test.dart`: UI widget tests
  - `test/viewmodel_test.dart`: Business logic tests
  - `test/data_layer_test.dart`: Data layer unit tests
- **Integration**: Database utilities for manual testing and validation

## Database Schema

### SQLite (Development)
- **users**: User identity and profile management (user_id, user_name, user_type, created_at)
  - user_type: 'human' or 'ai' to distinguish between participants
- **products**: Product metadata and URLs
- **reviews**: Product review content, ratings, and author information
- **chat_room**: User-specific chat sessions
- **conversations**: Message history with unified structure
  - message: The actual message content
  - chat_user_id: References users.user_id (both human and AI participants)
  - related_review_ids: Comma-separated list of related review IDs
  - created_at: Message timestamp
- **special_products**: Special deals tracking and monitoring

### ChromaDB (Vector Store)
- Document embeddings for review similarity search
- Metadata filtering by product_id
- Sentence-transformer embeddings

## Deployment

### Backend
- **Platform**: Railway (recommended)
- **Database**: Railway PostgreSQL (production)
- **Environment**: Docker container with uv

### Frontend
- **Android**: APK distribution
- **iOS**: TestFlight or App Store
- **Web**: Firebase Hosting or Vercel

## Common Issues & Solutions

### Backend Issues
1. **OpenAI API Key**: Ensure valid API key in environment
2. **Playwright**: Run `playwright install` for browser dependencies
3. **ChromaDB**: Check data directory permissions
4. **CORS**: Configure proper origins for Flutter app

### Frontend Issues
1. **Network**: Check backend URL configuration for target platform
2. **Dependencies**: Run `flutter clean && flutter pub get`
3. **Build**: Ensure proper Android/iOS SDK setup
4. **State Management**: Check Provider context usage

## Code Style & Standards

### Backend (Python)
- Follow PEP 8 style guidelines
- Use type hints everywhere
- Async/await for I/O operations
- Comprehensive docstrings
- Error handling with proper HTTP status codes

### Frontend (Dart/Flutter)
- Follow Dart style guide
- Use dart analyzer rules from `analysis_options.yaml`
- Implement proper widget lifecycle management
- Use const constructors where possible
- Handle loading/error states in UI

## Git Workflow

Current branch: `feature-one`
Main branch: `main`

### Commit Message Format
```
type: short description

Longer description if needed

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Performance Considerations

### Backend
- Use async operations for I/O
- Implement proper caching for frequently accessed data
- Optimize ChromaDB queries with metadata filtering
- Use connection pooling for database

### Frontend
- Implement pagination for large lists
- Use proper image caching
- Optimize rebuild cycles with const widgets
- Implement proper loading states

## Security Considerations

- Store API keys securely in environment variables
- Implement proper CORS configuration
- Validate all user inputs with Pydantic
- Use HTTPS in production
- Implement rate limiting for API endpoints

## Monitoring & Debugging

### Backend
- FastAPI automatic API documentation at `/docs`
- Health check endpoint at `/health`
- Structured logging with appropriate levels
- Error tracking and performance monitoring

### Frontend
- Flutter Inspector for widget debugging
- Network traffic monitoring with Dio interceptors
- Crashlytics for production error tracking
- Performance profiling with Flutter DevTools

## Future Enhancements

- [ ] User authentication and personalization
- [ ] Product comparison features
- [ ] YouTube review integration
- [ ] Advanced filtering for biased reviews
- [ ] Push notifications
- [ ] Offline capability
- [ ] Multi-language support

---

**Development Status**: Advanced Phase - Feature Development ✅
- ✅ Core backend API with FastAPI
- ✅ Flutter mobile app with clean architecture
- ✅ AI integration (OpenAI GPT-4 + ChromaDB)
- ✅ Database schema with conversations system
- ✅ Special deals monitoring system
- 🚧 Current: Feature enhancements and optimizations

**Current Branch**: `feature-one`
**Developer**: Single full-stack developer
**Started**: June 8, 2025