import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// 채팅 기록 조회 유즈케이스
class GetChatHistory {
  final ChatRepository repository;

  GetChatHistory(this.repository);

  Future<List<ChatMessage>> call(GetChatHistoryParams params) async {
    return await repository.getChatHistory(
      userId: params.userId,
      productId: params.productId,
      limit: params.limit,
    );
  }
}

/// 채팅 기록 조회 파라미터
class GetChatHistoryParams {
  final String? userId;
  final String? productId;
  final int? limit;

  GetChatHistoryParams({this.userId, this.productId, this.limit});
}
