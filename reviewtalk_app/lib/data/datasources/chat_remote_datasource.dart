import 'package:dio/dio.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

/// 채팅 원격 데이터소스
abstract class ChatRemoteDataSource {
  Future<ChatMessageModel> sendMessage({
    required String message,
    String? productId,
  });
}

/// 채팅 원격 데이터소스 구현
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;

  ChatRemoteDataSourceImpl({required this.dio});

  @override
  Future<ChatMessageModel> sendMessage({
    required String message,
    String? productId,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/chat',
        data: {
          'question': message,
          if (productId != null) 'product_id': productId,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;

        // 서버가 ai_response 필드로 답변을 반환함
        return ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: jsonData['ai_response'] ?? '죄송합니다. 응답을 생성할 수 없습니다.',
          isUser: false,
          timestamp: DateTime.now(),
          status: ChatMessageStatus.sent,
        );
      } else {
        throw ServerException(
          message: 'HTTP ${response.statusCode}: 서버 오류',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(
        message: '네트워크 오류: ${e.type.toString()}\n${e.message ?? e.toString()}',
      );
    } catch (e) {
      throw ServerException(message: '예상치 못한 오류: ${e.toString()}');
    }
  }
}
