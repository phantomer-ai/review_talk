import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../models/special_product_model.dart';

/// 특가 상품 API 호출 서비스
class SpecialDealsApi {
  /// 특가 상품 목록 조회
  static Future<List<SpecialProductModel>> getSpecialDeals({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrlSync}/api/v1/special-deals?limit=$limit&offset=$offset',
      );

      print('🔍 특가 상품 API 호출: $url');

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      print('📡 API 응답 상태코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📊 API 응답 데이터: ${responseData.toString().substring(0, 200)}...');

        if (responseData['success'] == true) {
          final productsJson = responseData['products'] as List;
          print('🎁 수신된 상품 개수: ${productsJson.length}');

          final products =
              productsJson
                  .map(
                    (productJson) => SpecialProductModel.fromJson(productJson),
                  )
                  .toList();

          // 각 상품의 이미지 URL 확인
          for (int i = 0; i < products.length && i < 3; i++) {
            print('상품 ${i + 1}: ${products[i].productName}');
            print('이미지: ${products[i].imageUrl}');
          }

          return products;
        } else {
          throw Exception(
            responseData['error_message'] ?? '특가 상품을 불러올 수 없습니다.',
          );
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 특가 상품 API 호출 오류: $e');
      throw Exception('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 특가 상품 수동 크롤링 요청
  static Future<bool> crawlSpecialDeals({
    int maxProducts = 20,
    bool crawlReviews = false,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrlSync}/api/v1/special-deals/crawl',
      );

      final requestData = {
        'max_products': maxProducts,
        'crawl_reviews': crawlReviews,
        'max_reviews_per_product': 100,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('크롤링 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('특가 상품 크롤링 API 호출 오류: $e');
      return false;
    }
  }

  /// 특가 상품 통계 조회
  static Future<Map<String, dynamic>?> getSpecialDealsStats() async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrlSync}/api/v1/special-deals/stats/summary',
      );

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return responseData['stats'];
        }
      }
      return null;
    } catch (e) {
      print('특가 상품 통계 API 호출 오류: $e');
      return null;
    }
  }
}
