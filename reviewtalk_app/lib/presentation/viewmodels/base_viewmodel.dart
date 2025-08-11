import 'package:flutter/foundation.dart';

/// 모든 ViewModel이 상속받는 기본 클래스
abstract class BaseViewModel extends ChangeNotifier {
  // 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 에러 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 성공 메시지
  String? _successMessage;
  String? get successMessage => _successMessage;

  /// 로딩 상태 설정
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 에러 메시지 설정
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 성공 메시지 설정
  void setSuccess(String? success) {
    _successMessage = success;
    notifyListeners();
  }

  /// 에러 상태 초기화
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// 성공 상태 초기화
  void clearSuccess() {
    if (_successMessage != null) {
      _successMessage = null;
      notifyListeners();
    }
  }

  /// 모든 상태 초기화
  void clearAllMessages() {
    bool shouldNotify = false;

    if (_errorMessage != null) {
      _errorMessage = null;
      shouldNotify = true;
    }

    if (_successMessage != null) {
      _successMessage = null;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// 에러 여부 확인
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;

  /// 성공 여부 확인
  bool get hasSuccess => _successMessage != null && _successMessage!.isNotEmpty;

  /// 비동기 작업 실행 헬퍼 메서드
  Future<T?> executeWithLoading<T>(
    Future<T> Function() task, {
    String? errorPrefix,
    String? successMessage,
  }) async {
    try {
      setLoading(true);
      clearAllMessages();

      final result = await task();

      if (successMessage != null) {
        setSuccess(successMessage);
      }

      return result;
    } catch (e) {
      final errorMsg =
          errorPrefix != null ? '$errorPrefix: ${e.toString()}' : e.toString();
      setError(errorMsg);
      return null;
    } finally {
      setLoading(false);
    }
  }
}
