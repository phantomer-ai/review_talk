import 'api_constants.dart'; // ApiConstants import 추가

/// 애플리케이션 전반에서 사용하는 상수들
class AppConstants {
  // API 관련 - 하드코딩된 baseUrl 제거하고 ApiConstants 사용
  static String get baseUrl => ApiConstants.baseUrlSync; // 이미 탐지된 URL 사용
  static const String apiVersion = '/api/v1';

  // 엔드포인트
  static const String crawlReviewsEndpoint = '$apiVersion/crawl-reviews';
  static const String chatEndpoint = '$apiVersion/chat';
  static const String healthEndpoint = '/health';

  // 타임아웃
  static const int connectTimeout = 30000; // 30초
  static const int receiveTimeout = 30000; // 30초

  // 로컬 스토리지 키
  static const String recentSearchesKey = 'recent_searches';
  static const String userPreferencesKey = 'user_preferences';

  // UI 관련
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const int maxRecentSearches = 10;

  // 메시지
  static const String appName = 'ReviewTalk';
  static const String defaultErrorMessage = '오류가 발생했습니다. 다시 시도해주세요.';
  static const String networkErrorMessage = '인터넷 연결을 확인해주세요.';
  static const String serverErrorMessage = '서버에 문제가 있습니다. 잠시 후 다시 시도해주세요.';
}
