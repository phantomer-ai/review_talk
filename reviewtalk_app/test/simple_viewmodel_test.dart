import 'package:flutter_test/flutter_test.dart';
import 'package:reviewtalk_app/presentation/viewmodels/base_viewmodel.dart';

// BaseViewModel만 테스트하는 간단한 구현체
class SimpleTestViewModel extends BaseViewModel {}

void main() {
  group('ViewModel 기본 동작 테스트', () {
    test('BaseViewModel 초기 상태 확인', () {
      // Given
      final viewModel = SimpleTestViewModel();

      // Then
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
      expect(viewModel.successMessage, null);
      expect(viewModel.hasError, false);
      expect(viewModel.hasSuccess, false);
    });

    test('BaseViewModel 로딩 상태 변경', () {
      // Given
      final viewModel = SimpleTestViewModel();

      // When
      viewModel.setLoading(true);

      // Then
      expect(viewModel.isLoading, true);
    });

    test('BaseViewModel 에러 메시지 설정 및 확인', () {
      // Given
      final viewModel = SimpleTestViewModel();
      const errorMessage = '테스트 에러 메시지';

      // When
      viewModel.setError(errorMessage);

      // Then
      expect(viewModel.errorMessage, errorMessage);
      expect(viewModel.hasError, true);
    });

    test('BaseViewModel 성공 메시지 설정 및 확인', () {
      // Given
      final viewModel = SimpleTestViewModel();
      const successMessage = '테스트 성공 메시지';

      // When
      viewModel.setSuccess(successMessage);

      // Then
      expect(viewModel.successMessage, successMessage);
      expect(viewModel.hasSuccess, true);
    });

    test('BaseViewModel 메시지 초기화', () {
      // Given
      final viewModel = SimpleTestViewModel();
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

    test('BaseViewModel 개별 메시지 초기화', () {
      // Given
      final viewModel = SimpleTestViewModel();
      viewModel.setError('에러');
      viewModel.setSuccess('성공');

      // When - 에러만 클리어
      viewModel.clearError();

      // Then
      expect(viewModel.errorMessage, null);
      expect(viewModel.hasError, false);
      expect(viewModel.successMessage, '성공');
      expect(viewModel.hasSuccess, true);

      // When - 성공 메시지 클리어
      viewModel.clearSuccess();

      // Then
      expect(viewModel.successMessage, null);
      expect(viewModel.hasSuccess, false);
    });

    test('BaseViewModel executeWithLoading 성공 케이스', () async {
      // Given
      final viewModel = SimpleTestViewModel();
      const expectedResult = '테스트 결과';

      // When
      final result = await viewModel.executeWithLoading<String>(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return expectedResult;
      }, successMessage: '작업 완료!');

      // Then
      expect(result, expectedResult);
      expect(viewModel.isLoading, false);
      expect(viewModel.successMessage, '작업 완료!');
      expect(viewModel.errorMessage, null);
    });

    test('BaseViewModel executeWithLoading 실패 케이스', () async {
      // Given
      final viewModel = SimpleTestViewModel();
      const errorMsg = '테스트 에러';

      // When
      final result = await viewModel.executeWithLoading<String>(() async {
        throw Exception(errorMsg);
      }, errorPrefix: '작업 실패');

      // Then
      expect(result, null);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, '작업 실패: Exception: $errorMsg');
      expect(viewModel.successMessage, null);
    });
  });
}
