import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../data/models/review_model.dart';
import '../repositories/review_repository.dart';

/// 리뷰 크롤링 유스케이스
class CrawlReviews {
  final ReviewRepository repository;

  CrawlReviews(this.repository);

  /// 리뷰 크롤링 실행
  Future<Either<Failure, CrawlReviewsResponseModel>> call(
    CrawlReviewsParams params,
  ) async {
    return await repository.crawlReviews(
      productUrl: params.productUrl,
      maxReviews: params.maxReviews,
    );
  }
}

/// 리뷰 크롤링 파라미터
class CrawlReviewsParams extends Equatable {
  final String productUrl;
  final int maxReviews;

  const CrawlReviewsParams({required this.productUrl, this.maxReviews = 50});

  @override
  List<Object> get props => [productUrl, maxReviews];

  @override
  String toString() {
    return 'CrawlReviewsParams(productUrl: $productUrl, maxReviews: $maxReviews)';
  }
}
