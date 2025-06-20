import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../data/models/chat_model.dart';
import '../entities/chat_message.dart';

/// 채팅 리포지토리 인터페이스
abstract class ChatRepository {
  /// AI에게 메시지 전송
  Future<Either<Failure, ChatResponseModel>> sendMessage({
    required String productId,
    required String question,
  });

  /// 채팅 기록 저장
  Future<void> saveMessage(ChatMessage message);

  /// 채팅 기록 불러오기
  Future<List<ChatMessage>> getChatHistory({
    String? userId,
    String? productId,
    int? limit,
  });

  /// 채팅 기록 삭제
  Future<void> clearChatHistory({String? productId});
}
