import 'package:equatable/equatable.dart';

/// 상품 모델
class ProductModel extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? imageUrl;
  final String? brand;
  final double? price;
  final String? category;
  final int reviewCount;
  final double? averageRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.url,
    this.imageUrl,
    this.brand,
    this.price,
    this.category,
    this.reviewCount = 0,
    this.averageRating,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSON에서 객체로 변환
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      imageUrl: json['image_url'] as String?,
      brand: json['brand'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      category: json['category'] as String?,
      reviewCount: json['review_count'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'image_url': imageUrl,
      'brand': brand,
      'price': price,
      'category': category,
      'review_count': reviewCount,
      'average_rating': averageRating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 복사본 생성
  ProductModel copyWith({
    String? id,
    String? name,
    String? url,
    String? imageUrl,
    String? brand,
    double? price,
    String? category,
    int? reviewCount,
    double? averageRating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      category: category ?? this.category,
      reviewCount: reviewCount ?? this.reviewCount,
      averageRating: averageRating ?? this.averageRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    url,
    imageUrl,
    brand,
    price,
    category,
    reviewCount,
    averageRating,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, brand: $brand, reviewCount: $reviewCount)';
  }
}

/// 상품 검색/목록 응답 모델
class ProductListResponseModel extends Equatable {
  final bool success;
  final List<ProductModel> products;
  final int totalCount;
  final int page;
  final int limit;
  final String? message;

  const ProductListResponseModel({
    required this.success,
    required this.products,
    required this.totalCount,
    this.page = 1,
    this.limit = 20,
    this.message,
  });

  /// JSON에서 객체로 변환
  factory ProductListResponseModel.fromJson(Map<String, dynamic> json) {
    return ProductListResponseModel(
      success: json['success'] as bool,
      products:
          (json['products'] as List<dynamic>)
              .map(
                (productJson) =>
                    ProductModel.fromJson(productJson as Map<String, dynamic>),
              )
              .toList(),
      totalCount: json['total_count'] as int,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      message: json['message'] as String?,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'products': products.map((product) => product.toJson()).toList(),
      'total_count': totalCount,
      'page': page,
      'limit': limit,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [
    success,
    products,
    totalCount,
    page,
    limit,
    message,
  ];

  @override
  String toString() {
    return 'ProductListResponseModel(success: $success, productsCount: ${products.length}, totalCount: $totalCount)';
  }
}
