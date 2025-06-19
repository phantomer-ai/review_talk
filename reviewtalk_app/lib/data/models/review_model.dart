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

/// 크롤링 응답 모델
class CrawlReviewsResponseModel extends Equatable {
  final bool success;
  final String productId;
  final String productName;
  final String? productImage;
  final String? productPrice;
  final String? productBrand;
  final List<ReviewModel> reviews;
  final int totalReviews;
  final String? errorMessage;

  const CrawlReviewsResponseModel({
    required this.success,
    required this.productId,
    required this.productName,
    this.productImage,
    this.productPrice,
    this.productBrand,
    required this.reviews,
    required this.totalReviews,
    this.errorMessage,
  });

  /// JSON에서 객체로 변환
  factory CrawlReviewsResponseModel.fromJson(Map<String, dynamic> json) {
    return CrawlReviewsResponseModel(
      success: json['success'] as bool,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String?,
      productPrice: json['product_price'] as String?,
      productBrand: json['product_brand'] as String?,
      reviews:
          (json['reviews'] as List<dynamic>)
              .map(
                (reviewJson) =>
                    ReviewModel.fromJson(reviewJson as Map<String, dynamic>),
              )
              .toList(),
      totalReviews: json['total_reviews'] as int,
      errorMessage: json['error_message'] as String?,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'product_price': productPrice,
      'product_brand': productBrand,
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'total_reviews': totalReviews,
      'error_message': errorMessage,
    };
  }

  @override
  List<Object?> get props => [
    success,
    productId,
    productName,
    productImage,
    productPrice,
    productBrand,
    reviews,
    totalReviews,
    errorMessage,
  ];

  @override
  String toString() {
    return 'CrawlReviewsResponseModel(success: $success, productId: $productId, productName: $productName, reviewsCount: ${reviews.length})';
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
