import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';

/// HTTP 클라이언트를 관리하는 클래스
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrlSync,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _initializeInterceptors();
  }

  void _initializeInterceptors() {
    // 요청/응답 로깅 인터셉터
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        logPrint: (object) {
          print('[API] $object');
        },
      ),
    );

    // 에러 처리 인터셉터
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // 커스텀 예외로 변환하고 원래 에러를 그대로 전달
          _handleDioError(error);
          handler.next(error);
        },
      ),
    );
  }

  /// GET 요청
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST 요청
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT 요청
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE 요청
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Dio 에러를 커스텀 예외로 변환
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(message: '연결 시간이 초과되었습니다.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        String message;

        switch (statusCode) {
          case 400:
            message = '잘못된 요청입니다.';
            break;
          case 401:
            message = '인증이 필요합니다.';
            break;
          case 403:
            message = '접근 권한이 없습니다.';
            break;
          case 404:
            message = '요청한 리소스를 찾을 수 없습니다.';
            break;
          case 500:
            message = '서버 내부 오류가 발생했습니다.';
            break;
          default:
            message = '서버 오류가 발생했습니다. (${statusCode ?? 'Unknown'})';
        }

        return ServerException(message: message, statusCode: statusCode);

      case DioExceptionType.connectionError:
        return NetworkException(message: '네트워크 연결을 확인해주세요.');

      case DioExceptionType.cancel:
        return NetworkException(message: '요청이 취소되었습니다.');

      default:
        return NetworkException(message: '알 수 없는 네트워크 오류가 발생했습니다.');
    }
  }
}
