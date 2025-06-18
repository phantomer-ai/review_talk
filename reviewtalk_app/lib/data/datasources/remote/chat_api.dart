import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../models/chat_model.dart';
import '../../../core/utils/user_id_manager.dart';

abstract class ChatApiDataSource {
  /// AI 채팅 요청
  Future<ChatResponseModel> sendMessage(ChatRequestModel request);
}

class ChatApiDataSourceImpl implements ChatApiDataSource {
  final ApiClient _apiClient;

  ChatApiDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<ChatResponseModel> sendMessage(ChatRequestModel request) async {
    try {
      print('[ChatApi] 메시지 전송: [38;5;10m[1m${request.question}[0m');
      final userId = await UserIdManager().getUserId();
      final data = request.toJson();
      if (!data.containsKey('user_id')) {
        data['user_id'] = userId;
      }
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.chat,
        data: data,
        options: Options(
          receiveTimeout: const Duration(seconds: 120), // AI 응답 생성을 위한 긴 타임아웃
        ),
      );

      print('[ChatApi] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final responseModel = ChatResponseModel.fromJson(response.data!);
        print('[ChatApi] 응답 성공: ${responseModel.aiResponse}');
        return responseModel;
      } else {
        throw ServerException(
          message: 'AI 응답을 가져오는데 실패했습니다.',
          statusCode: response.statusCode,
        );
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      print('[ChatApi] 예외 발생: $e');
      if (e.toString().contains('FormatException') ||
          e.toString().contains('type')) {
        throw JsonParsingException(message: '서버 응답을 파싱하는 중 오류가 발생했습니다.');
      }
      throw ServerException(
        message: 'AI 채팅 중 알 수 없는 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }
}
