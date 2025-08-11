# Phase 3: Flutter 앱 개발
## MVVM Clean Architecture 구현

---

## 📋 **Phase 3 목표**
- ✅ Clean Architecture 데이터 레이어 구현
- ✅ MVVM 패턴으로 ViewModel 및 상태관리 구현
- ✅ 사용자 인터페이스 화면 구현
- ✅ 백엔드 API와 완전 연동

**예상 소요시간:** 145분

---

## 🔌 **Checkpoint 3.1: 데이터 레이어 구현**
⏱️ **40분**

### **목표**
Clean Architecture의 Data Layer를 구현하여 백엔드 API와 통신하는 기반 구축

### **완료 기준**
- ✅ API 클라이언트 (dio 기반) 구현
- ✅ 데이터 모델 클래스 (JSON 직렬화 포함) 완성
- ✅ Repository 패턴 구현
- ✅ 에러 처리 및 네트워크 상태 관리

### **Cursor 명령어**
```
Flutter 앱의 데이터 레이어를 Clean Architecture로 구현해주세요.

현재 상황:
- Phase 1에서 Flutter 프로젝트 기본 구조 완성
- Phase 2에서 백엔드 API 완성 (FastAPI)
- 백엔드 API 엔드포인트: POST /api/v1/crawl-reviews, POST /api/v1/chat

구현 내용:
1. lib/core/network/api_client.dart - dio 기반 HTTP 클라이언트
2. lib/core/constants/api_constants.dart - API URL 상수
3. lib/data/models/ - 데이터 모델들
   - review_model.dart
   - chat_model.dart  
   - product_model.dart
4. lib/data/datasources/remote/ - API 데이터 소스
   - review_api.dart
   - chat_api.dart
5. lib/data/repositories/ - Repository 구현체
   - review_repository_impl.dart
   - chat_repository_impl.dart
6. lib/core/errors/ - 에러 처리
   - exceptions.dart
   - failures.dart

필요한 기능:
- dio 인터셉터 (로그, 에러 처리)
- JSON 직렬화/역직렬화
- 네트워크 연결 상태 확인
- API 응답 에러 처리 (4xx, 5xx)
- 타임아웃 설정

API 연동 대상:
POST /api/v1/crawl-reviews
- 요청: {"product_url": "string", "max_reviews": int}
- 응답: {"success": bool, "product_id": "string", "product_name": "string", "reviews": [...]}

POST /api/v1/chat  
- 요청: {"product_id": "string", "question": "string"}
- 응답: {"success": bool, "answer": "string", "confidence": float, "source_reviews": [...]}

baseUrl: http://10.0.2.2:8000 (Android 에뮬레이터용)
```

### **검증 방법**
```dart
// API 클라이언트 단위 테스트
final apiClient = ApiClient();
final response = await apiClient.post('/api/v1/crawl-reviews', data: {
  'product_url': '실제_다나와_URL',
  'max_reviews': 5
});
print('API 응답: $response');

// 모델 직렬화 테스트
final testJson = {'success': true, 'product_name': '테스트 상품'};
final model = ProductModel.fromJson(testJson);
print('모델 변환: ${model.toJson()}');
```

---

## 🧠 **Checkpoint 3.2: ViewModel 및 상태관리**
⏱️ **45분**

### **목표**
MVVM 패턴으로 비즈니스 로직을 분리하고 Provider 기반 상태관리 구현

### **완료 기준**
- ✅ BaseViewModel 클래스 구현
- ✅ ChatViewModel, UrlInputViewModel 구현
- ✅ Domain Layer (UseCase) 구현
- ✅ Provider 설정 및 의존성 주입
- ✅ 로딩/에러 상태 관리

### **Cursor 명령어**
```
MVVM 패턴으로 ViewModel과 상태관리를 구현해주세요.

현재 상황:
- Checkpoint 3.1에서 데이터 레이어 완성
- Repository 패턴으로 API 연동 준비 완료
- Provider + get_it으로 상태관리 및 의존성 주입 예정

구현 내용:
1. lib/domain/ - 도메인 레이어
   - entities/review.dart - 리뷰 엔티티
   - entities/chat_message.dart - 채팅 메시지 엔티티
   - entities/product.dart - 상품 엔티티
   - repositories/review_repository.dart - Repository 인터페이스
   - repositories/chat_repository.dart - Repository 인터페이스
   - usecases/crawl_reviews.dart - 리뷰 크롤링 유스케이스
   - usecases/send_message.dart - 메시지 전송 유스케이스

2. lib/presentation/viewmodels/ - ViewModel들
   - base_viewmodel.dart - 공통 기능 (로딩, 에러 상태)
   - url_input_viewmodel.dart - URL 입력 화면 로직
   - chat_viewmodel.dart - 채팅 화면 로직

3. lib/injection_container.dart - 의존성 주입 설정

필요한 기능:
- ChangeNotifier 기반 상태 관리
- 로딩 상태 (isLoading)
- 에러 상태 (errorMessage)
- 성공/실패 콜백
- 메시지 리스트 관리 (채팅)
- URL 유효성 검증
- 크롤링 진행 상태

상태 관리 패턴:
- BaseViewModel에서 공통 상태 (로딩, 에러) 관리
- 각 ViewModel에서 화면별 상태 관리
- Repository는 Either<Failure, Success> 패턴 사용
- UseCase에서 비즈니스 로직 처리

Provider 설정:
- MultiProvider로 여러 ViewModel 등록
- ChangeNotifierProvider 사용
- get_it으로 의존성 주입
```

### **검증 방법**
```dart
// ViewModel 테스트
final chatViewModel = ChatViewModel();
await chatViewModel.initializeChat('test_product_id');
await chatViewModel.sendMessage('배터리 어때요?');

print('메시지 개수: ${chatViewModel.messages.length}');
print('로딩 상태: ${chatViewModel.isLoading}');
print('에러: ${chatViewModel.errorMessage}');
```

---

## 🎨 **Checkpoint 3.3: UI 화면 구현**
⏱️ **60분**

### **목표**
사용자 인터페이스 화면들을 구현하고 ViewModel과 연결

### **완료 기준**
- ✅ URL 입력 화면 구현
- ✅ 로딩 화면 구현
- ✅ 채팅 화면 구현
- ✅ 공통 위젯들 구현
- ✅ 화면 간 네비게이션 설정

### **Cursor 명령어**
```
Flutter UI 화면들을 구현해주세요.

현재 상황:
- Checkpoint 3.2에서 ViewModel 및 상태관리 완성
- Provider 패턴으로 ViewModel과 View 연결 준비 완료
- Material Design 3 사용

구현 내용:
1. lib/presentation/views/screens/ - 주요 화면들
   - url_input_screen.dart - 다나와 URL 입력 화면
   - loading_screen.dart - 크롤링 진행 상태 화면
   - chat_screen.dart - 채팅 인터페이스 화면

2. lib/presentation/views/widgets/ - 재사용 위젯들
   - common/custom_button.dart - 커스텀 버튼
   - common/loading_widget.dart - 로딩 인디케이터
   - common/error_widget.dart - 에러 표시 위젯
   - url_input/url_input_form.dart - URL 입력 폼
   - chat/message_bubble.dart - 채팅 말풍선
   - chat/suggested_questions.dart - 추천 질문 버튼들
   - chat/chat_input.dart - 메시지 입력창

3. lib/core/constants/app_colors.dart - 앱 색상 정의
4. lib/core/constants/app_strings.dart - 문자열 상수
5. lib/main.dart - 라우팅 및 Provider 설정

화면별 기능:
URL 입력 화면:
- 다나와 URL 입력 TextFormField (유효성 검증)
- "리뷰 분석 시작" 버튼
- URL 형식 안내 텍스트
- 최근 검색 기록 (SharedPreferences)

로딩 화면:
- 크롤링 진행 상태 표시
- 진행률 인디케이터 (LinearProgressIndicator)
- 상태 메시지 ("리뷰 수집 중...", "AI 분석 중...")
- 취소 버튼

채팅 화면:
- 상품 정보 표시 (상단)
- 추천 질문 버튼들 (가로 스크롤)
- 채팅 메시지 리스트 (ListView)
- 메시지 입력창 (하단 고정)
- 전송 버튼 활성화/비활성화

디자인 요구사항:
- Material Design 3 색상 사용
- 반응형 레이아웃 (다양한 화면 크기)
- 접근성 고려 (semantic labels)
- 키보드 대응 (resizeToAvoidBottomInset)
- 로딩 중 UI 차단
```

### **검증 방법**
```dart
// 화면 전환 테스트
1. URL 입력 → "분석 시작" → 로딩 화면
2. 로딩 완료 → 채팅 화면 이동
3. 추천 질문 클릭 → 메시지 전송
4. 에러 상황 → 에러 메시지 표시
5. 뒤로가기 → 이전 화면 복귀
```

---

## ✅ **Phase 3 완료 체크리스트**

### **데이터 레이어 확인사항**
- [ ] dio 기반 API 클라이언트 정상 동작
- [ ] JSON 직렬화/역직렬화 테스트 통과
- [ ] Repository 패턴으로 API 호출 성공
- [ ] 네트워크 에러 처리 동작 확인
- [ ] 타임아웃 및 재시도 로직 구현

### **ViewModel 확인사항**
- [ ] Provider 패턴으로 상태 관리 동작
- [ ] 로딩/에러 상태 정상 표시
- [ ] UseCase 패턴으로 비즈니스 로직 분리
- [ ] 의존성 주입 (get_it) 정상 동작
- [ ] ViewModel 간 데이터 전달 확인

### **UI 확인사항**
- [ ] 모든 화면이 정상 렌더링
- [ ] 화면 간 네비게이션 동작
- [ ] Provider Consumer로 상태 변화 반영
- [ ] 로딩 인디케이터 표시/숨김
- [ ] 에러 메시지 사용자 친화적 표시

### **통합 테스트 확인사항**
- [ ] URL 입력부터 채팅까지 전체 플로우 동작
- [ ] 실제 백엔드 API와 연동 성공
- [ ] 다양한 화면 크기에서 정상 동작
- [ ] 메모리 누수 없음 (ViewModel dispose)

---

## 🐛 **문제 해결 가이드**

### **API 연동 문제**
```
문제: dio 요청 실패 (connection refused)
해결: baseUrl을 10.0.2.2:8000으로 설정 (Android 에뮬레이터)

문제: JSON 직렬화 에러
해결: 모델 클래스의 fromJson/toJson 메서드 확인

문제: Provider 상태 업데이트 안됨
해결: notifyListeners() 호출 확인
```

### **UI 관련 문제**
```
문제: 키보드가 UI를 가림
해결: Scaffold의 resizeToAvoidBottomInset: true

문제: ListView 스크롤 문제
해결: Expanded 위젯으로 감싸기

문제: 상태 변화가 UI에 반영 안됨
해결: Consumer<ViewModel> 위젯 사용 확인
```

---

## 🚀 **다음 단계 준비사항**

Phase 3 완료 후 통합 테스트를 위한 준비:

1. **백엔드 서버 실행 상태 확인**
   - FastAPI 서버가 정상 동작 중인지 확인
   - API 엔드포인트들이 모두 응답하는지 확인

2. **테스트 시나리오 준비**
   - 다양한 다나와 상품 URL 준비
   - 여러 가지 질문 패턴 준비
   - 에러 상황 테스트 케이스 준비

3. **성능 확인**
   - 앱 시작 시간 체크
   - API 응답 시간 체크
   - 메모리 사용량 확인

**Phase 3 완료시 CHECKPOINT_PHASE4.md 파일을 참조하여 통합 테스트를 진행하세요.**