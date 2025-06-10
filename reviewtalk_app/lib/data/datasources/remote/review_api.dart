import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../models/review_model.dart';

abstract class ReviewApiDataSource {
  /// 상품 리뷰 크롤링
  Future<CrawlReviewsResponseModel> crawlReviews(
    CrawlReviewsRequestModel request,
  );
}

class ReviewApiDataSourceImpl implements ReviewApiDataSource {
  final ApiClient _apiClient;

  ReviewApiDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<CrawlReviewsResponseModel> crawlReviews(
    CrawlReviewsRequestModel request,
  ) async {
    try {
      print('[ReviewApi] 리뷰 크롤링 요청: ${request.productUrl}');

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.crawlReviews,
        data: request.toJson(),
        options: Options(
          receiveTimeout: Duration(seconds: 120), // 크롤링 작업용 2분 타임아웃
        ),
      );

      print('[ReviewApi] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final responseModel = CrawlReviewsResponseModel.fromJson(
          response.data!,
        );
        print('[ReviewApi] 크롤링 성공: ${responseModel.reviews.length}개 리뷰');
        return responseModel;
      } else {
        throw ServerException(
          message: '리뷰 크롤링에 실패했습니다.',
          statusCode: response.statusCode,
        );
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      print('[ReviewApi] 예외 발생: $e');
      if (e.toString().contains('FormatException') ||
          e.toString().contains('type')) {
        throw JsonParsingException(message: '서버 응답을 파싱하는 중 오류가 발생했습니다.');
      }
      throw ServerException(
        message: '리뷰 크롤링 중 알 수 없는 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }
}
