import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../data/models/review_model.dart';

abstract class ReviewRepository {
  /// 상품 리뷰 크롤링
  Future<Either<Failure, CrawlReviewsResponseModel>> crawlReviews({
    required String productUrl,
    int maxReviews = 50,
  });
}
