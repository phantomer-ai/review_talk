/// API 관련 상수들
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../network/server_discovery.dart';

class ApiConstants {
  static String? _baseUrl;

  /// 서버 자동 탐지 후 base URL 반환
  static Future<String> get baseUrl async {
    if (_baseUrl != null) {
      return _baseUrl!;
    }

    // 1. 환경변수에서 URL 확인
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      // 환경변수 URL이 실제로 작동하는지 확인
      if (await ServerDiscovery.testConnection(envUrl)) {
        _baseUrl = envUrl;
        print('✅ 환경변수 서버 사용: $envUrl');
        return _baseUrl!;
      }
    }

    // 2. 서버 자동 탐지
    _baseUrl = await ServerDiscovery.discoverServer();
    print('🎯 최종 서버 URL: $_baseUrl');
    return _baseUrl!;
  }

  /// 동기적으로 baseUrl 반환 (이미 설정된 경우)
  static String get baseUrlSync {
    return _baseUrl ?? 'http://localhost:8000';
  }

  /// 서버 URL 수동 설정
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// 서버 URL 초기화 (재탐지 강제)
  static void resetBaseUrl() {
    _baseUrl = null;
  }

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
