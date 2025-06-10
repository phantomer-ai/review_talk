import 'package:equatable/equatable.dart';

/// 리뷰 엔티티 (도메인 객체)
class Review extends Equatable {
  final String id;
  final String content;
  final int rating;
  final String reviewer;
  final DateTime date;
  final Map<String, dynamic>? metadata;

  const Review({
    required this.id,
    required this.content,
    required this.rating,
    required this.reviewer,
    required this.date,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, content, rating, reviewer, date, metadata];

  @override
  String toString() {
    return 'Review(id: $id, content: $content, rating: $rating, reviewer: $reviewer, date: $date)';
  }
}
