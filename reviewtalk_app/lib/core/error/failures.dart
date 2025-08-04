import 'package:equatable/equatable.dart';

/// 모든 실패 상황의 베이스 클래스
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

/// 서버 관련 실패
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required super.message, this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

/// 네트워크 연결 실패
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// 캐시 관련 실패
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// JSON 파싱 실패
class JsonParsingFailure extends Failure {
  const JsonParsingFailure({required super.message});
}

/// 타임아웃 실패
class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message});
}

/// 일반적인 실패
class GeneralFailure extends Failure {
  const GeneralFailure({required super.message});
}
