/// API 관련 상수들
class ApiConstants {
  // Base URL for Android emulator
  static const String baseUrl = 'http://192.168.35.68:8000';

  // API endpoints
  static const String crawlReviews = '/api/v1/crawl-reviews';
  static const String chat = '/api/v1/chat';

  // Timeouts
  static const int connectTimeout = 10000; // 10초
  static const int receiveTimeout = 120000; // 60초 (크롤링 작업용)
  static const int sendTimeout = 10000; // 10초

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
