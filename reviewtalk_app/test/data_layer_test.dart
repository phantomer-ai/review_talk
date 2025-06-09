import 'package:flutter_test/flutter_test.dart';
import 'package:reviewtalk_app/core/network/api_client.dart';
import 'package:reviewtalk_app/data/datasources/remote/review_api.dart';
import 'package:reviewtalk_app/data/datasources/remote/chat_api.dart';
import 'package:reviewtalk_app/data/repositories/review_repository_impl.dart';
import 'package:reviewtalk_app/data/repositories/chat_repository_impl.dart';
import 'package:reviewtalk_app/data/models/review_model.dart';
import 'package:reviewtalk_app/data/models/chat_model.dart';

void main() {
  group('Data Layer 구현 테스트', () {
    late ApiClient apiClient;
    late ReviewApiDataSource reviewApiDataSource;
    late ChatApiDataSource chatApiDataSource;
    late ReviewRepositoryImpl reviewRepository;
    late ChatRepositoryImpl chatRepository;

    setUp(() {
      // ApiClient 인스턴스 생성
      apiClient = ApiClient();

      // DataSource 인스턴스 생성
      reviewApiDataSource = ReviewApiDataSourceImpl(apiClient: apiClient);
      chatApiDataSource = ChatApiDataSourceImpl(apiClient: apiClient);

      // Repository 인스턴스 생성
      reviewRepository = ReviewRepositoryImpl(
        reviewApiDataSource: reviewApiDataSource,
      );
      // 기존 데이터소스가 필요하므로 임시로 null 처리
      // chatRepository = ChatRepositoryImpl(chatApiDataSource: chatApiDataSource);
    });

    test('ReviewModel JSON 직렬화/역직렬화 테스트', () {
      // Given
      final reviewJson = {
        'id': 'test_id',
        'content': '좋은 상품입니다',
        'rating': 5,
        'reviewer': '테스터',
        'date': '2024-01-01T00:00:00.000Z',
        'metadata': {'source': 'test'},
      };

      // When
      final review = ReviewModel.fromJson(reviewJson);
      final backToJson = review.toJson();

      // Then
      expect(review.id, 'test_id');
      expect(review.content, '좋은 상품입니다');
      expect(review.rating, 5);
      expect(review.reviewer, '테스터');
      expect(backToJson['id'], 'test_id');
      expect(backToJson['content'], '좋은 상품입니다');
    });

    test('CrawlReviewsRequestModel JSON 직렬화 테스트', () {
      // Given
      final request = CrawlReviewsRequestModel(
        productUrl: 'https://example.com/product',
        maxReviews: 100,
      );

      // When
      final json = request.toJson();

      // Then
      expect(json['product_url'], 'https://example.com/product');
      expect(json['max_reviews'], 100);
    });

    test('ChatRequestModel JSON 직렬화 테스트', () {
      // Given
      final request = ChatRequestModel(
        productId: 'product123',
        question: '이 상품의 품질은 어떤가요?',
      );

      // When
      final json = request.toJson();

      // Then
      expect(json['product_id'], 'product123');
      expect(json['question'], '이 상품의 품질은 어떤가요?');
    });

    test('ChatResponseModel JSON 역직렬화 테스트', () {
      // Given
      final responseJson = {
        'success': true,
        'answer': '전반적으로 품질이 좋습니다',
        'confidence': 0.8,
        'source_reviews': [
          {
            'id': 'review1',
            'content': '품질 좋아요',
            'rating': 5,
            'reviewer': '구매자1',
            'date': '2024-01-01T00:00:00.000Z',
          },
        ],
        'message': null,
      };

      // When
      final response = ChatResponseModel.fromJson(responseJson);

      // Then
      expect(response.success, true);
      expect(response.answer, '전반적으로 품질이 좋습니다');
      expect(response.confidence, 0.8);
      expect(response.sourceReviews.length, 1);
      expect(response.sourceReviews.first.content, '품질 좋아요');
    });

    test('ApiClient 인스턴스 생성 테스트', () {
      // When
      final client = ApiClient();

      // Then
      expect(client, isNotNull);
    });

    test('ReviewApiDataSource 인스턴스 생성 테스트', () {
      // When
      final dataSource = ReviewApiDataSourceImpl(apiClient: apiClient);

      // Then
      expect(dataSource, isNotNull);
    });

    test('ChatApiDataSource 인스턴스 생성 테스트', () {
      // When
      final dataSource = ChatApiDataSourceImpl(apiClient: apiClient);

      // Then
      expect(dataSource, isNotNull);
    });

    test('ReviewRepository 인스턴스 생성 테스트', () {
      // When
      final repository = ReviewRepositoryImpl(
        reviewApiDataSource: reviewApiDataSource,
      );

      // Then
      expect(repository, isNotNull);
    });
  });
}
