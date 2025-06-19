/// 특가 상품 데이터 모델
class SpecialProductModel {
  final String productId;
  final String productName;
  final String productUrl;
  final String? imageUrl;
  final String? price;
  final String? originalPrice;
  final String? discountRate;
  final String? brand;
  final String category;
  final double? rating;
  final int reviewCount;
  final bool isCrawled;
  final String? createdAt;
  final String? updatedAt;

  SpecialProductModel({
    required this.productId,
    required this.productName,
    required this.productUrl,
    this.imageUrl,
    this.price,
    this.originalPrice,
    this.discountRate,
    this.brand,
    required this.category,
    this.rating,
    this.reviewCount = 0,
    this.isCrawled = false,
    this.createdAt,
    this.updatedAt,
  });

  factory SpecialProductModel.fromJson(Map<String, dynamic> json) {
    return SpecialProductModel(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      productUrl: json['product_url'] ?? '',
      imageUrl: json['image_url'],
      price: json['price'],
      originalPrice: json['original_price'],
      discountRate: json['discount_rate'],
      brand: json['brand'],
      category: json['category'] ?? '특가상품',
      rating: json['rating']?.toDouble(),
      reviewCount: json['review_count'] ?? 0,
      isCrawled: json['is_crawled'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'product_url': productUrl,
      'image_url': imageUrl,
      'price': price,
      'original_price': originalPrice,
      'discount_rate': discountRate,
      'brand': brand,
      'category': category,
      'rating': rating,
      'review_count': reviewCount,
      'is_crawled': isCrawled,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// 할인율을 퍼센트 문자열로 반환
  String get discountText {
    if (discountRate != null && discountRate!.isNotEmpty) {
      return discountRate!;
    }
    return '특가';
  }

  /// 가격을 표시용 문자열로 반환
  String get priceText {
    if (price != null && price!.isNotEmpty) {
      return price!;
    }
    return '특가가격';
  }

  /// 상품명을 짧게 표시
  String get shortName {
    if (productName.length > 15) {
      return '${productName.substring(0, 15)}...';
    }
    return productName;
  }

  /// 채팅 가능 여부 (리뷰가 크롤링된 상품만)
  bool get canChat => isCrawled && reviewCount > 0;
}
