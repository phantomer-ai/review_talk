import 'package:equatable/equatable.dart';

/// 채팅 응답의 소스 리뷰 모델 (서버 응답 전용)
class SourceReviewModel extends Equatable {
  final String document;
  final Map<String, dynamic> metadata;
  final double? distance;

  const SourceReviewModel({
    required this.document,
    required this.metadata,
    this.distance,
  });

  factory SourceReviewModel.fromJson(Map<String, dynamic> json) {
    return SourceReviewModel(
      document: json['document'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'document': document, 'metadata': metadata, 'distance': distance};
  }

  @override
  List<Object?> get props => [document, metadata, distance];
}

/// 채팅 요청 모델
class ChatRequestModel extends Equatable {
  final String? productId;
  final String question;
  final String? chatRoomId;

  const ChatRequestModel({
    required this.question,
    this.productId,
    this.chatRoomId,
  });

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    final map = {'question': question};
    if (productId != null) map['product_id'] = productId.toString();
    if (chatRoomId != null) map['chat_room_id'] = chatRoomId.toString();
    return map;
  }

  @override
  List<Object?> get props => [productId, question, chatRoomId];

  @override
  String toString() {
    return 'ChatRequestModel(productId: $productId, question: $question, chatRoomId: $chatRoomId)';
  }
}

/// 채팅 응답 모델
class ChatResponseModel extends Equatable {
  final bool success;
  final String aiResponse;
  final List<SourceReviewModel> sourceReviews;
  final String? message;

  const ChatResponseModel({
    required this.success,
    required this.aiResponse,
    required this.sourceReviews,
    this.message,
  });

  /// JSON에서 객체로 변환
  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    return ChatResponseModel(
      success: json['success'] as bool? ?? false,
      aiResponse: json['ai_response'] as String? ?? '응답을 가져올 수 없습니다.',
      sourceReviews:
          (json['source_reviews'] as List<dynamic>? ?? [])
              .map(
                (reviewJson) => SourceReviewModel.fromJson(
                  reviewJson as Map<String, dynamic>,
                ),
              )
              .toList(),
      message: json['message'] as String?,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'ai_response': aiResponse,
      'source_reviews': sourceReviews.map((review) => review.toJson()).toList(),
      'message': message,
    };
  }

  @override
  List<Object?> get props => [success, aiResponse, sourceReviews, message];

  @override
  String toString() {
    return 'ChatResponseModel(success: $success, aiResponse: $aiResponse, sourceReviewsCount: ${sourceReviews.length})';
  }
}

/// 채팅 메시지 모델 (UI용)
class ChatMessageModel extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatResponseModel? responseData; // AI 응답의 경우 추가 데이터

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.responseData,
  });

  /// 사용자 메시지 생성자
  factory ChatMessageModel.user({required String content}) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  /// AI 응답 메시지 생성자
  factory ChatMessageModel.ai({
    required String content,
    ChatResponseModel? responseData,
  }) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      responseData: responseData,
    );
  }

  /// JSON에서 객체로 변환
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      responseData:
          json['responseData'] != null
              ? ChatResponseModel.fromJson(
                json['responseData'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'responseData': responseData?.toJson(),
    };
  }

  /// 복사본 생성
  ChatMessageModel copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    ChatResponseModel? responseData,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      responseData: responseData ?? this.responseData,
    );
  }

  @override
  List<Object?> get props => [id, content, isUser, timestamp, responseData];

  @override
  String toString() {
    return 'ChatMessageModel(id: $id, content: $content, isUser: $isUser, timestamp: $timestamp)';
  }
}
