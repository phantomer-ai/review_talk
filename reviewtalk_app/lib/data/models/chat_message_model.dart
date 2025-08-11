import '../../domain/entities/chat_message.dart';

/// 채팅 메시지 데이터 모델
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.content,
    required super.isUser,
    required super.timestamp,
    super.status,
    super.sourceReviews,
  });

  /// JSON에서 ChatMessageModel 생성
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      content: json['content'] ?? json['answer'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
      status: ChatMessageStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ChatMessageStatus.sent,
      ),
      sourceReviews:
          json['sourceReviews'] != null
              ? List<String>.from(json['sourceReviews'])
              : json['source_reviews'] != null
              ? List<String>.from(json['source_reviews'])
              : null,
    );
  }

  /// ChatMessageModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'sourceReviews': sourceReviews,
    };
  }

  /// 엔터티에서 모델 생성
  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      content: entity.content,
      isUser: entity.isUser,
      timestamp: entity.timestamp,
      status: entity.status,
      sourceReviews: entity.sourceReviews,
    );
  }
}
