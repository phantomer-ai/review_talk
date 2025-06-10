import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/remote/review_api.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewApiDataSource _reviewApiDataSource;

  ReviewRepositoryImpl({required ReviewApiDataSource reviewApiDataSource})
    : _reviewApiDataSource = reviewApiDataSource;

  @override
  Future<Either<Failure, CrawlReviewsResponseModel>> crawlReviews({
    required String productUrl,
    int maxReviews = 50,
  }) async {
    try {
      final request = CrawlReviewsRequestModel(
        productUrl: productUrl,
        maxReviews: maxReviews,
      );

      final result = await _reviewApiDataSource.crawlReviews(request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on TimeoutException catch (e) {
      return Left(TimeoutFailure(message: e.message));
    } on JsonParsingException catch (e) {
      return Left(JsonParsingFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(
        GeneralFailure(message: '알 수 없는 오류가 발생했습니다: ${e.toString()}'),
      );
    }
  }
}
