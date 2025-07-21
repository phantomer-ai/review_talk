import 'package:equatable/equatable.dart';

/// 개별 리뷰 모델
class ReviewModel extends Equatable {
  final String id;
  final String content;
  final int rating;
  final String reviewer;
  final DateTime date;
  final Map<String, dynamic>? metadata;

  const ReviewModel({
    required this.id,
    required this.content,
    required this.rating,
    required this.reviewer,
    required this.date,
    this.metadata,
  });

  /// JSON에서 객체로 변환
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['review_id'] as String,
      content: json['content'] as String,
      rating: json['rating'] as int,
      reviewer: json['author'] as String,
      date:
          json['date'] != null
              ? DateTime.parse(json['date'] as String)
              : DateTime.now(), // null인 경우 현재 시간 사용
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'rating': rating,
      'reviewer': reviewer,
      'date': date.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 복사본 생성
  ReviewModel copyWith({
    String? id,
    String? content,
    int? rating,
    String? reviewer,
    DateTime? date,
    Map<String, dynamic>? metadata,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      reviewer: reviewer ?? this.reviewer,
      date: date ?? this.date,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, content, rating, reviewer, date, metadata];

  @override
  String toString() {
    return 'ReviewModel(id: $id, content: $content, rating: $rating, reviewer: $reviewer, date: $date)';
  }
}

/// 크롤링 응답 모델 (백엔드 CrawlResponse에 맞게 수정)
class CrawlReviewsResponseModel extends Equatable {
  final bool success;
  final String message;
  final int reviewsFound;
  final String? productId;
  final Map<String, dynamic>? productInfo;
  final String? errorMessage;

  const CrawlReviewsResponseModel({
    required this.success,
    required this.message,
    required this.reviewsFound,
    this.productId,
    this.productInfo,
    this.errorMessage,
  });

  // 편의 속성들 (기존 코드 호환성을 위해)
  String get productName =>
      productInfo?['name'] ?? productInfo?['product_name'] ?? '상품명 없음';
  String? get productImage => productInfo?['image_url'];
  String? get productPrice => productInfo?['price'];
  String? get productBrand => productInfo?['brand'];
  List<ReviewModel> get reviews => []; // 백엔드에서 리뷰 목록을 직접 반환하지 않음
  int get totalReviews => reviewsFound;

  /// JSON에서 객체로 변환
  factory CrawlReviewsResponseModel.fromJson(Map<String, dynamic> json) {
    return CrawlReviewsResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String,
      reviewsFound: json['reviews_found'] as int? ?? 0,
      productId: json['product_id'] as String?,
      productInfo: json['product_info'] as Map<String, dynamic>?,
      errorMessage: json['error_message'] as String?,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'reviews_found': reviewsFound,
      'product_id': productId,
      'product_info': productInfo,
      'error_message': errorMessage,
    };
  }

  @override
  List<Object?> get props => [
    success,
    message,
    reviewsFound,
    productId,
    productInfo,
    errorMessage,
  ];

  @override
  String toString() {
    return 'CrawlReviewsResponseModel(success: $success, message: $message, reviewsFound: $reviewsFound, productId: $productId)';
  }
}

/// 크롤링 요청 모델
class CrawlReviewsRequestModel extends Equatable {
  final String productUrl;
  final int maxReviews;

  const CrawlReviewsRequestModel({
    required this.productUrl,
    this.maxReviews = 50,
  });

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {'product_url': productUrl, 'max_reviews': maxReviews};
  }

  @override
  List<Object> get props => [productUrl, maxReviews];

  @override
  String toString() {
    return 'CrawlReviewsRequestModel(productUrl: $productUrl, maxReviews: $maxReviews)';
  }
}
