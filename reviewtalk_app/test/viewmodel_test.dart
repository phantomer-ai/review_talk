import 'package:flutter_test/flutter_test.dart';
import 'package:reviewtalk_app/presentation/viewmodels/base_viewmodel.dart';
import 'package:reviewtalk_app/presentation/viewmodels/url_input_viewmodel.dart';
import 'package:reviewtalk_app/presentation/viewmodels/chat_viewmodel.dart';
import 'package:reviewtalk_app/domain/usecases/crawl_reviews.dart';
import 'package:reviewtalk_app/domain/usecases/send_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock 클래스들
class MockCrawlReviews extends CrawlReviews {
  MockCrawlReviews() : super(throw UnimplementedError());
}

class MockSendMessage extends SendMessage {
  MockSendMessage() : super(throw UnimplementedError());
}

void main() {
  group('ViewModel 구현 테스트', () {
    late SharedPreferences mockPrefs;

    setUpAll(() async {
      // SharedPreferences 모킹
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
    });

    test('BaseViewModel 초기 상태 테스트', () {
      // Given
      final viewModel = _TestViewModel();

      // Then
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
      expect(viewModel.successMessage, null);
      expect(viewModel.hasError, false);
      expect(viewModel.hasSuccess, false);
    });

    test('BaseViewModel 로딩 상태 변경 테스트', () {
      // Given
      final viewModel = _TestViewModel();
      bool notified = false;
      viewModel.addListener(() => notified = true);

      // When
      viewModel.setLoading(true);

      // Then
      expect(viewModel.isLoading, true);
      expect(notified, true);
    });

    test('BaseViewModel 에러 메시지 설정 테스트', () {
      // Given
      final viewModel = _TestViewModel();
      const errorMessage = '테스트 에러';

      // When
      viewModel.setError(errorMessage);

      // Then
      expect(viewModel.errorMessage, errorMessage);
      expect(viewModel.hasError, true);
    });

    test('BaseViewModel 성공 메시지 설정 테스트', () {
      // Given
      final viewModel = _TestViewModel();
      const successMessage = '테스트 성공';

      // When
      viewModel.setSuccess(successMessage);

      // Then
      expect(viewModel.successMessage, successMessage);
      expect(viewModel.hasSuccess, true);
    });

    test('BaseViewModel 메시지 초기화 테스트', () {
      // Given
      final viewModel = _TestViewModel();
      viewModel.setError('에러');
      viewModel.setSuccess('성공');

      // When
      viewModel.clearAllMessages();

      // Then
      expect(viewModel.errorMessage, null);
      expect(viewModel.successMessage, null);
      expect(viewModel.hasError, false);
      expect(viewModel.hasSuccess, false);
    });

    test('UrlInputViewModel 초기 상태 테스트', () {
      // Given
      final viewModel = UrlInputViewModel(
        crawlReviews: MockCrawlReviews(),
        prefs: mockPrefs,
      );

      // Then
      expect(viewModel.currentUrl, '');
      expect(viewModel.maxReviews, 50);
      expect(viewModel.recentUrls, isEmpty);
      expect(viewModel.crawlProgress, 0.0);
      expect(viewModel.crawlStatusMessage, '');
    });

    test('UrlInputViewModel URL 설정 테스트', () {
      // Given
      final viewModel = UrlInputViewModel(
        crawlReviews: MockCrawlReviews(),
        prefs: mockPrefs,
      );
      const testUrl = 'https://prod.danawa.com/info/?pcode=1234567';

      // When
      viewModel.setUrl(testUrl);

      // Then
      expect(viewModel.currentUrl, testUrl);
    });

    test('UrlInputViewModel URL 유효성 검증 테스트', () {
      // Given
      final viewModel = UrlInputViewModel(
        crawlReviews: MockCrawlReviews(),
        prefs: mockPrefs,
      );

      // 유효한 URL 테스트
      viewModel.setUrl('https://prod.danawa.com/info/?pcode=1234567');
      expect(viewModel.isUrlValid(), true);

      // 무효한 URL 테스트
      viewModel.setUrl('https://invalid-url.com');
      expect(viewModel.isUrlValid(), false);

      // 빈 URL 테스트
      viewModel.setUrl('');
      expect(viewModel.isUrlValid(), false);
    });

    test('UrlInputViewModel 최대 리뷰 수 설정 테스트', () {
      // Given
      final viewModel = UrlInputViewModel(
        crawlReviews: MockCrawlReviews(),
        prefs: mockPrefs,
      );

      // When & Then
      viewModel.setMaxReviews(100);
      expect(viewModel.maxReviews, 100);

      // 범위 밖 값 테스트 (0 이하)
      viewModel.setMaxReviews(-1);
      expect(viewModel.maxReviews, 100); // 변경되지 않아야 함

      // 범위 밖 값 테스트 (200 초과)
      viewModel.setMaxReviews(300);
      expect(viewModel.maxReviews, 100); // 변경되지 않아야 함
    });

    test('ChatViewModel 초기 상태 테스트', () {
      // Given
      final viewModel = ChatViewModel(sendMessage: MockSendMessage());

      // Then
      expect(viewModel.productId, null);
      expect(viewModel.productName, null);
      expect(viewModel.messages, isEmpty);
      expect(viewModel.currentMessage, '');
      expect(viewModel.isFirstMessage, true);
      expect(viewModel.canSendMessage, false);
    });

    test('ChatViewModel 채팅 초기화 테스트', () {
      // Given
      final viewModel = ChatViewModel(sendMessage: MockSendMessage());
      const productId = 'test_product_id';
      const productName = '테스트 상품';

      // When
      viewModel.initializeChat(productId: productId, productName: productName);

      // Then
      expect(viewModel.productId, productId);
      expect(viewModel.productName, productName);
      expect(viewModel.messages.length, 1); // 환영 메시지
      expect(viewModel.messages.first.isUser, false);
      expect(viewModel.isFirstMessage, false);
    });

    test('ChatViewModel 메시지 텍스트 업데이트 테스트', () {
      // Given
      final viewModel = ChatViewModel(sendMessage: MockSendMessage());
      const testMessage = '테스트 메시지';

      // When
      viewModel.updateMessageText(testMessage);

      // Then
      expect(viewModel.currentMessage, testMessage);
    });

    test('ChatViewModel 메시지 전송 가능 상태 테스트', () {
      // Given
      final viewModel = ChatViewModel(sendMessage: MockSendMessage());

      // 초기 상태 (전송 불가)
      expect(viewModel.canSendMessage, false);

      // 메시지만 입력 (여전히 전송 불가 - 상품 ID 없음)
      viewModel.updateMessageText('테스트');
      expect(viewModel.canSendMessage, false);

      // 채팅 초기화 후 (전송 가능)
      viewModel.initializeChat(productId: 'test_id', productName: '테스트 상품');
      expect(viewModel.canSendMessage, true);
    });

    test('ChatViewModel 채팅 기록 삭제 테스트', () {
      // Given
      final viewModel = ChatViewModel(sendMessage: MockSendMessage());
      viewModel.initializeChat(productId: 'test_id', productName: '테스트 상품');

      // When
      viewModel.clearChat();

      // Then
      expect(viewModel.messages.length, 1); // 환영 메시지만 남아있어야 함
      expect(viewModel.messages.first.content.contains('초기화'), true);
    });

    test('ChatViewModel 추천 질문 리스트 테스트', () {
      // Given
      final viewModel = ChatViewModel(sendMessage: MockSendMessage(), getChatHistory: ge(), chatRepository: null);

      // Then
      expect(viewModel.suggestedQuestions.isNotEmpty, true);
      expect(viewModel.suggestedQuestions.length, 8);
      expect(viewModel.suggestedQuestions.first.contains('장점'), true);
    });
  });
}

// 테스트용 BaseViewModel 구현체
class _TestViewModel extends BaseViewModel {}
