/// 서버 관련 예외
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// 네트워크 연결 예외
class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

/// 캐시 관련 예외
class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

/// JSON 파싱 예외
class JsonParsingException implements Exception {
  final String message;

  const JsonParsingException({required this.message});

  @override
  String toString() => 'JsonParsingException: $message';
}

/// 타임아웃 예외
class TimeoutException implements Exception {
  final String message;

  const TimeoutException({required this.message});

  @override
  String toString() => 'TimeoutException: $message';
}
