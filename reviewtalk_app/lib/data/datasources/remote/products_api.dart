import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/user_id_manager.dart';
import '../../models/product_model.dart';

/// 통합 상품 API 클라이언트
class ProductsApi {
  final ApiClient _apiClient;

  ProductsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// 사용자의 채팅 상품 목록 조회
  Future<List<ProductModel>> getUserChatProducts() async {
    try {
      final userId = await UserIdManager().getUserId();
      AppLogger.i('[ProductsApi] 사용자 채팅 상품 조회 시작: $userId');

      final response = await _apiClient.get(
        '/api/v1/products',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true) {
          final productsJson = data['products'] as List<dynamic>? ?? [];
          final products = productsJson
              .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          AppLogger.i('[ProductsApi] 사용자 채팅 상품 조회 성공: ${products.length}개');
          return products;
        } else {
          AppLogger.w('[ProductsApi] 사용자 채팅 상품 조회 실패: ${data['message']}');
          return [];
        }
      } else {
        AppLogger.e('[ProductsApi] 사용자 채팅 상품 조회 HTTP 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      AppLogger.e('[ProductsApi] 사용자 채팅 상품 조회 예외: $e');
      return [];
    }
  }

  /// 특가 상품 목록 조회
  Future<List<ProductModel>> getSpecialDeals({
    int limit = 10,
    bool onlyCrawled = true,
  }) async {
    try {
      AppLogger.i('[ProductsApi] 특가 상품 조회 시작: limit=$limit, onlyCrawled=$onlyCrawled');

      final response = await _apiClient.get(
        '/api/v1/special-deals',
        queryParameters: {
          'limit': limit,
          'only_crawled': onlyCrawled,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true) {
          final productsJson = data['products'] as List<dynamic>? ?? [];
          final products = productsJson
              .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          AppLogger.i('[ProductsApi] 특가 상품 조회 성공: ${products.length}개');
          return products;
        } else {
          AppLogger.w('[ProductsApi] 특가 상품 조회 실패: ${data['message']}');
          return [];
        }
      } else {
        AppLogger.e('[ProductsApi] 특가 상품 조회 HTTP 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      AppLogger.e('[ProductsApi] 특가 상품 조회 예외: $e');
      return [];
    }
  }

  /// 통합 상품 목록 조회 (사용자 채팅 상품 + 특가 상품)
  Future<List<ProductModel>> getCombinedProducts({
    int specialDealsLimit = 6,
    bool onlySpecialCrawled = true,
  }) async {
    try {
      AppLogger.i('[ProductsApi] 통합 상품 목록 조회 시작');

      // 두 API를 병렬로 호출
      final results = await Future.wait([
        getUserChatProducts(),
        getSpecialDeals(limit: specialDealsLimit, onlyCrawled: onlySpecialCrawled),
      ]);

      final userProducts = results[0];
      final specialProducts = results[1];

      // 중복 제거 (productId 기준)
      final allProducts = <String, ProductModel>{};
      
      // 사용자 채팅 상품을 먼저 추가 (우선순위)
      for (final product in userProducts) {
        allProducts[product.productId] = product;
      }
      
      // 특가 상품 추가 (중복되지 않는 것만)
      for (final product in specialProducts) {
        if (!allProducts.containsKey(product.productId)) {
          allProducts[product.productId] = product;
        }
      }

      final combinedList = allProducts.values.toList();
      
      // 정렬: 사용자 채팅 상품 > 특가 상품 > 생성일시 역순
      combinedList.sort((a, b) {
        // 1. 사용자가 채팅한 상품이 우선
        if (userProducts.any((p) => p.productId == a.productId) && 
            !userProducts.any((p) => p.productId == b.productId)) {
          return -1;
        }
        if (!userProducts.any((p) => p.productId == a.productId) && 
            userProducts.any((p) => p.productId == b.productId)) {
          return 1;
        }
        
        // 2. 특가 상품이 우선
        if (a.isSpecial && !b.isSpecial) return -1;
        if (!a.isSpecial && b.isSpecial) return 1;
        
        // 3. 생성일시 역순
        if (a.createdAt != null && b.createdAt != null) {
          try {
            final dateA = DateTime.parse(a.createdAt!);
            final dateB = DateTime.parse(b.createdAt!);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        }
        
        return 0;
      });

      AppLogger.i('[ProductsApi] 통합 상품 조회 완료: 총 ${combinedList.length}개 (사용자: ${userProducts.length}, 특가: ${specialProducts.length})');
      return combinedList;
      
    } catch (e) {
      AppLogger.e('[ProductsApi] 통합 상품 조회 예외: $e');
      return [];
    }
  }

  /// 특정 상품 정보 조회
  Future<ProductModel?> getProduct(String productId) async {
    try {
      AppLogger.i('[ProductsApi] 상품 정보 조회: $productId');

      final response = await _apiClient.get(
        '/api/v1/products/$productId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true && data['product'] != null) {
          final product = ProductModel.fromJson(data['product'] as Map<String, dynamic>);
          AppLogger.i('[ProductsApi] 상품 정보 조회 성공: ${product.name}');
          return product;
        } else {
          AppLogger.w('[ProductsApi] 상품 정보 조회 실패: ${data['message']}');
          return null;
        }
      } else {
        AppLogger.e('[ProductsApi] 상품 정보 조회 HTTP 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.e('[ProductsApi] 상품 정보 조회 예외: $e');
      return null;
    }
  }

  /// 상품 통계 정보 조회
  Future<Map<String, dynamic>?> getProductStatistics() async {
    try {
      AppLogger.i('[ProductsApi] 상품 통계 조회 시작');

      final response = await _apiClient.get(
        '/api/v1/products/statistics/overview',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true && data['statistics'] != null) {
          AppLogger.i('[ProductsApi] 상품 통계 조회 성공');
          return data['statistics'] as Map<String, dynamic>;
        } else {
          AppLogger.w('[ProductsApi] 상품 통계 조회 실패: ${data['message']}');
          return null;
        }
      } else {
        AppLogger.e('[ProductsApi] 상품 통계 조회 HTTP 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.e('[ProductsApi] 상품 통계 조회 예외: $e');
      return null;
    }
  }
}