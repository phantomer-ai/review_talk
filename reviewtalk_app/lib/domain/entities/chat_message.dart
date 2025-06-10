import 'package:equatable/equatable.dart';

/// 채팅 메시지 엔터티 (도메인 객체)
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageStatus status;
  final List<String>? sourceReviews;
  final double? confidence; // AI 응답의 신뢰도

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.status = ChatMessageStatus.sent,
    this.sourceReviews,
    this.confidence,
  });

  /// 사용자 메시지 생성자
  factory ChatMessage.user({required String content}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      status: ChatMessageStatus.sending,
    );
  }

  /// AI 응답 메시지 생성자
  factory ChatMessage.ai({
    required String content,
    List<String>? sourceReviews,
    double? confidence,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      status: ChatMessageStatus.sent,
      sourceReviews: sourceReviews,
      confidence: confidence,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    ChatMessageStatus? status,
    List<String>? sourceReviews,
    double? confidence,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      sourceReviews: sourceReviews ?? this.sourceReviews,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  List<Object?> get props => [
    id,
    content,
    isUser,
    timestamp,
    status,
    sourceReviews,
    confidence,
  ];

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, isUser: $isUser, status: $status)';
  }
}

/// 채팅 메시지 상태
enum ChatMessageStatus {
  sending, // 전송 중
  sent, // 전송 완료
  error, // 에러 발생
}
