import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

/// API 관련 상수들
class ApiConstants {
  // Base URL (.env의 BASE_URL, 없으면 환경별 기본값)
  static String get baseUrl {
    // .env 파일에서 BASE_URL이 설정되어 있으면 우선 사용ㅇ
    final envBaseUrl = dotenv.env['BASE_URL'];
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    // 환경별 기본값 설정
    if (kDebugMode) {
      // 🛠️ 개발 모드 (로컬 개발)
      if (kIsWeb) {
        return 'http://localhost:8000'; // 웹 개발 시
      } else {
        return 'http://192.168.35.188:8000'; // 모바일 개발 시 (현재 로컬 IP)
      }
    } else {
      // 🚀 배포 모드 (프로덕션)
      return 'https://api.reviewtalk.com'; // 실제 배포 시 도메인
      // 또는 'https://reviewtalk-api-xyz123.run.app' (Cloud Run URL)
    }
  }

  // API endpoints
  static const String crawlReviews = '/api/v1/crawl-reviews';
  static const String chat = '/api/v1/chat';
  static const String chatRooms = '/api/v1/chat-rooms/';
  static const String conversations = '/api/v1/conversations';

  // Timeouts
  static const int _millisecondsInSecond = 1000; // 1초를 밀리초로 표현 (상수로 정의)
  static const int _second = 60; // 1초를 밀리초로 표현 (상수로 정의)

  static const int connectTimeout = 30 * _millisecondsInSecond; // 30초
  static const int receiveTimeout =
      6 * _second * _millisecondsInSecond; // 6분 (크롤링 작업용)
  static const int sendTimeout = 10 * _millisecondsInSecond; // 10초

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 🔧 환경 확인용 (디버깅)
  static String get currentEnvironment {
    if (kDebugMode) {
      return kIsWeb ? 'Development (Web)' : 'Development (Mobile)';
    } else {
      return 'Production';
    }
  }
}
