import 'package:equatable/equatable.dart';

/// 상품 엔티티 (도메인 객체)
class Product extends Equatable {
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

  const Product({
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
    return 'Product(id: $id, name: $name, brand: $brand, reviewCount: $reviewCount)';
  }
}
