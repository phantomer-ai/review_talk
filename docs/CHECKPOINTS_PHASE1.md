# CHECKPOINTS_PHASE1 
# Phase 1: 프로젝트 기반 구축
## 백엔드 & 프론트엔드 초기화

---

## 📋 **Phase 1 목표**
- ✅ uv 기반 FastAPI 프로젝트 생성
- ✅ Flutter MVVM 프로젝트 생성
- ✅ 기본 폴더 구조 완성
- ✅ Hello World API & 앱 동작 확인

**예상 소요시간:** 35분

---

## 🏗️ **Checkpoint 1.1: 백엔드 프로젝트 초기화**
⏱️ **20분**

### **목표**
uv 기반 FastAPI 프로젝트 생성 및 기본 구조 설정

### **완료 기준**
- ✅ pyproject.toml 설정 완료
- ✅ 기본 폴더 구조 생성
- ✅ /health 엔드포인트 동작
- ✅ uv run dev 명령어로 서버 실행

### **Cursor 명령어**
```
uv 기반 FastAPI 프로젝트를 초기화해주세요.

요구사항:
- 프로젝트명: reviewtalk-backend
- Python 3.11+
- 기본 의존성: fastapi, uvicorn, pydantic, python-dotenv
- 폴더 구조: app/ 내부에 main.py

구현 내용:
1. pyproject.toml 생성 (uv scripts 포함: dev, test, lint)
2. app/main.py - 기본 FastAPI 앱
3. app/core/config.py - 환경변수 설정
4. .env 파일 템플릿
5. /health 엔드포인트 추가

폴더 구조:
reviewtalk-backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   └── core/
│       ├── __init__.py
│       └── config.py
├── pyproject.toml
└── .env

서버 실행 명령어: uv run dev
```

### **검증 방법**
```bash
# 서버 실행
uv run dev

# 브라우저에서 확인
http://localhost:8000/health
http://localhost:8000/docs  # Swagger 문서
```

---

## 📱 **Checkpoint 1.2: Flutter 프로젝트 초기화**
⏱️ **15분**

### **목표**
Flutter 프로젝트 생성 및 MVVM Clean Architecture 폴더 구조 설정

### **완료 기준**
- ✅ Flutter 프로젝트 생성
- ✅ pubspec.yaml 의존성 설정
- ✅ Clean Architecture 폴더 구조
- ✅ 기본 MaterialApp 동작

### **Cursor 명령어**
```
Flutter 프로젝트를 생성하고 MVVM Clean Architecture로 폴더를 구성해주세요.

요구사항:
- 프로젝트명: reviewtalk_app
- MVVM + Clean Architecture 구조
- 기본 의존성 추가

폴더 구조:
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── network/
│   │   └── api_client.dart
│   └── utils/
│       └── validators.dart
├── data/
│   ├── datasources/
│   │   └── remote/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── viewmodels/
│   └── views/
│       ├── screens/
│       └── widgets/
└── injection_container.dart

pubspec.yaml 의존성:
- dio: ^5.4.0
- provider: ^6.1.1
- get_it: ^7.6.4
- shared_preferences: ^2.2.2
- flutter_spinkit: ^5.2.0
- equatable: ^2.0.5

main.dart에서 기본 MaterialApp 설정 포함
```

### **검증 방법**
```bash
# Flutter 앱 실행
flutter run

# 기본 화면이 정상 표시되는지 확인
```

---

## ✅ **Phase 1 완료 체크리스트**

### **백엔드 확인사항**
- [ ] `uv run dev` 명령어로 서버 실행됨
- [ ] `http://localhost:8000/health` 접속 가능
- [ ] `http://localhost:8000/docs` Swagger 문서 표시됨
- [ ] pyproject.toml에 필요한 의존성 모두 포함
- [ ] .env 파일 템플릿 생성

### **프론트엔드 확인사항**
- [ ] `flutter run` 명령어로 앱 실행됨
- [ ] Clean Architecture 폴더 구조 완성
- [ ] pubspec.yaml 의존성 설정 완료
- [ ] 기본 MaterialApp 화면 표시
- [ ] 빌드 에러 없음

### **공통 확인사항**
- [ ] Git 저장소 초기화 및 커밋
- [ ] 기본 .gitignore 설정
- [ ] README.md 작성

---

## 🚀 **다음 단계 준비사항**

Phase 1 완료 후 다음 작업을 위한 준비:

1. **기존 다나와 크롤링 코드 준비**
   - 기존 크롤링 함수를 FastAPI와 연동할 예정
   - Playwright 기반 코드를 app/infrastructure/crawler/ 폴더에 배치

2. **OpenAI API 키 준비**
   - .env 파일에 OPENAI_API_KEY 설정
   - Phase 2에서 AI 챗봇 기능 구현시 사용

3. **개발 환경 점검**
   - 백엔드와 프론트엔드가 동시에 실행 가능한지 확인
   - 포트 충돌 없는지 확인 (백엔드: 8000, 프론트엔드: 자동할당)

**Phase 1 완료시 CHECKPOINT_PHASE2.md 파일을 참조하여 다음 단계를 진행하세요.**