import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../datasources/remote/chat_api.dart';
import '../models/chat_model.dart';

/// 채팅 리포지토리 구현
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatApiDataSource _chatApiDataSource;
  final List<ChatMessage> _chatHistory = [];

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required ChatApiDataSource chatApiDataSource,
  }) : _chatApiDataSource = chatApiDataSource;

  @override
  Future<Either<Failure, ChatResponseModel>> sendMessage({
    required String productId,
    required String question,
  }) async {
    try {
      final request = ChatRequestModel(
        productId: productId,
        question: question,
      );

      final result = await _chatApiDataSource.sendMessage(request);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on TimeoutException catch (e) {
      return Left(TimeoutFailure(message: e.message));
    } on JsonParsingException catch (e) {
      return Left(JsonParsingFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(
        GeneralFailure(message: '알 수 없는 오류가 발생했습니다: ${e.toString()}'),
      );
    }
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    // 중복 메시지 체크 (같은 ID가 있으면 저장하지 않음)
    if (!_chatHistory.any((msg) => msg.id == message.id)) {
      _chatHistory.add(message);
    }
  }

  @override
  Future<List<ChatMessage>> getChatHistory({
    String? userId,
    String? productId,
    int? limit,
  }) async {
    try {
      if (userId == null || productId == null) {
        // userId나 productId가 없으면 빈 목록 반환
        return [];
      }

      final conversations = await _chatApiDataSource.getChatHistory(
        userId: userId,
        productId: productId,
        limit: limit,
      );

      // 백엔드 응답을 ChatMessage 엔티티로 변환
      return conversations.map((conversation) {
        return ChatMessage(
          id: conversation['id']?.toString() ?? '',
          content: conversation['message'] ?? '',
          isUser: conversation['chat_user_id'] == 'user',
          timestamp:
              DateTime.tryParse(conversation['created_at'] ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } on ServerException catch (e) {
      AppLogger.e('[ChatRepository] 서버 오류: ${e.message}');
      return [];
    } on NetworkException catch (e) {
      AppLogger.e('[ChatRepository] 네트워크 오류: ${e.message}');
      return [];
    } catch (e) {
      AppLogger.e('[ChatRepository] 채팅 기록 조회 오류', e);
      return [];
    }
  }

  @override
  Future<void> clearChatHistory({String? productId}) async {
    // 로컬 캐시 제거 (productId별 필터링은 향후 개선 시 추가)
    _chatHistory.clear();
    
    // TODO: 실제 환경에서는 backend API 호출하여 서버의 채팅 기록도 삭제
    // if (productId != null) {
    //   await _chatApiDataSource.deleteChatHistory(productId: productId);
    // }
  }
}
