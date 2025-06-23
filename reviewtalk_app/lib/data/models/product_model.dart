import 'package:equatable/equatable.dart';

/// 통합 상품 모델 (일반 상품과 특가 상품 모두 지원)
class ProductModel extends Equatable {
  final int? id;
  final String productId;
  final String name;
  final String url;
  final String? imageUrl;
  final String? brand;
  final String? price;
  final String? originalPrice;
  final String? discountRate;
  final String? category;
  final int reviewCount;
  final double? averageRating;
  final bool isCrawled;
  final bool isSpecial;
  final String? createdAt;
  final String? updatedAt;

  const ProductModel({
    this.id,
    required this.productId,
    required this.name,
    required this.url,
    this.imageUrl,
    this.brand,
    this.price,
    this.originalPrice,
    this.discountRate,
    this.category,
    this.reviewCount = 0,
    this.averageRating,
    this.isCrawled = false,
    this.isSpecial = false,
    this.createdAt,
    this.updatedAt,
  });

  /// JSON에서 객체로 변환
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // is_crawled, is_special 필드를 안전하게 bool 타입으로 변환하는 로컬 함수
    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false; // 기본값은 false
    }

    return ProductModel(
      id: json['id'] as int?,
      productId: json['product_id'] as String,
      name: json['product_name'] as String? ?? json['name'] as String? ?? '상품명 없음',
      url: json['product_url'] as String? ?? json['url'] as String? ?? '', // URL은 null일 수 없음
      imageUrl: json['image_url'] as String?,
      brand: json['brand'] as String?,
      price: json['price'] as String?,
      originalPrice: json['original_price'] as String?,
      discountRate: json['discount_rate'] as String?,
      category: json['category'] as String?,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      averageRating:
      json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      isCrawled: toBool(json['is_crawled']),
      isSpecial: toBool(json['is_special']),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': name,
      'product_url': url,
      'image_url': imageUrl,
      'brand': brand,
      'price': price,
      'original_price': originalPrice,
      'discount_rate': discountRate,
      'category': category,
      'review_count': reviewCount,
      'rating': averageRating,
      'is_crawled': isCrawled,
      'is_special': isSpecial,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // 기존 인터페이스 호환성을 위한 getter들
  String get productIcon => name.isNotEmpty ? name[0] : '🛒';
  String get shortName {
    final maxLength = 25;
    if (name.length > maxLength) {
      return '${name.substring(0, maxLength)}...';
    }
    return name;
  }

  String get chatStatusMessage {
    if (reviewCount > 0) {
      return '리뷰 $reviewCount개 분석 완료';
    }
    return '리뷰 분석 준비 중';
  }

  String get relativeTime {
    if (createdAt == null) return '시간 정보 없음';
    try {
      final createdDate = DateTime.parse(createdAt!);
      final difference = DateTime.now().difference(createdDate);

      if (difference.inDays > 7) {
        return '${createdDate.year}.${createdDate.month}.${createdDate.day}';
      }
      if (difference.inDays > 0) return '${difference.inDays}일 전';
      if (difference.inHours > 0) return '${difference.inHours}시간 전';
      if (difference.inMinutes > 0) return '${difference.inMinutes}분 전';
      return '방금 전';
    } catch (e) {
      return '시간 정보 오류';
    }
  }

  bool get canChat => isCrawled && reviewCount > 0;

  @override
  List<Object?> get props => [
    id,
    productId,
    name,
    url,
    imageUrl,
    brand,
    price,
    originalPrice,
    discountRate,
    category,
    reviewCount,
    averageRating,
    isCrawled,
    isSpecial,
    createdAt,
    updatedAt,
  ];
}