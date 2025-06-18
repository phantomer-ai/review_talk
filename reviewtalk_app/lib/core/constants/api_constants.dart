import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API 관련 상수들
class ApiConstants {
  // Base URL (.env의 BASE_URL, 없으면 기본값)
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://192.168.1.15:8000';

  // API endpoints
  static const String crawlReviews = '/api/v1/crawl-reviews';
  static const String chat = '/api/v1/chat';
  static const String chatRooms = '/api/v1/chat-rooms/';

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
}
