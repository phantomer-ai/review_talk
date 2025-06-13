import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/review_model.dart';
import '../../domain/usecases/crawl_reviews.dart';
import 'base_viewmodel.dart';

/// URL 입력 화면 ViewModel
class UrlInputViewModel extends BaseViewModel {
  final CrawlReviews _crawlReviews;
  final SharedPreferences _prefs;

  UrlInputViewModel({
    required CrawlReviews crawlReviews,
    required SharedPreferences prefs,
  }) : _crawlReviews = crawlReviews,
       _prefs = prefs {
    _loadRecentUrls();
  }

  // URL 입력 상태
  String _currentUrl = '';
  String get currentUrl => _currentUrl;

  // 최대 리뷰 수 (백엔드 제한: 100개)
  int _maxReviews = 1000;
  int get maxReviews => _maxReviews;

  // 최근 검색 기록
  List<String> _recentUrls = [];
  List<String> get recentUrls => List.unmodifiable(_recentUrls);

  // 크롤링 진행 상태
  double _crawlProgress = 0.0;
  double get crawlProgress => _crawlProgress;

  String _crawlStatusMessage = '';
  String get crawlStatusMessage => _crawlStatusMessage;

  // 크롤링 결과
  CrawlReviewsResponseModel? _crawlResult;
  CrawlReviewsResponseModel? get crawlResult => _crawlResult;

  /// URL 설정
  void setUrl(String url) {
    _currentUrl = url.trim();
    notifyListeners();
  }

  /// 최대 리뷰 수 설정 (백엔드 제한: 최대 100개)
  void setMaxReviews(int count) {
    if (count > 0 && count <= 1000) {
      _maxReviews = count;
      notifyListeners();
    }
  }

  /// URL 유효성 검증
  bool isUrlValid() {
    if (_currentUrl.isEmpty) return false;

    // 다나와 URL 패턴 검증
    const danawaPatterns = [
      'prod.danawa.com',
      'shop.danawa.com',
      'danawa.com/product',
      'danawa.page.link',
    ];

    return danawaPatterns.any((pattern) => _currentUrl.contains(pattern));
  }

  /// URL 유효성 에러 메시지
  String? getUrlValidationError() {
    if (_currentUrl.isEmpty) {
      return '다나와 상품 URL을 입력해주세요';
    }

    if (!isUrlValid()) {
      return '올바른 다나와 상품 URL을 입력해주세요\n예: https://prod.danawa.com/info/?pcode=1234567\n또는: https://danawa.page.link/...';
    }

    return null;
  }

  /// 리뷰 크롤링 시작
  Future<bool> startCrawling() async {
    if (!isUrlValid()) {
      setError(getUrlValidationError());
      return false;
    }

    final result = await executeWithLoading<CrawlReviewsResponseModel>(
      () async {
        _updateCrawlProgress(0.1, '리뷰 수집을 준비하고 있습니다...');

        final params = CrawlReviewsParams(
          productUrl: _currentUrl,
          maxReviews: _maxReviews,
        );

        _updateCrawlProgress(0.3, '상품 정보를 가져오고 있습니다...');

        final result = await _crawlReviews(params);

        return result.fold(
          (failure) {
            throw Exception(failure.message);
          },
          (success) {
            _updateCrawlProgress(0.8, '리뷰 분석을 완료하고 있습니다...');
            return success;
          },
        );
      },
      errorPrefix: '리뷰 크롤링 실패',
      successMessage: '$_maxReviews개의 리뷰를 성공적으로 수집했습니다!',
    );

    if (result != null) {
      _crawlResult = result;
      _updateCrawlProgress(1.0, '완료!');
      await _saveToRecentUrls(_currentUrl);
      return true;
    }

    return false;
  }

  /// 크롤링 진행 상태 업데이트
  void _updateCrawlProgress(double progress, String message) {
    _crawlProgress = progress;
    _crawlStatusMessage = message;
    notifyListeners();
  }

  /// 최근 URL 기록 로드
  void _loadRecentUrls() {
    _recentUrls = _prefs.getStringList('recent_urls') ?? [];
    notifyListeners();
  }

  /// 최근 URL 기록에 저장
  Future<void> _saveToRecentUrls(String url) async {
    // 중복 제거
    _recentUrls.remove(url);

    // 맨 앞에 추가
    _recentUrls.insert(0, url);

    // 최대 10개까지만 저장
    if (_recentUrls.length > 10) {
      _recentUrls = _recentUrls.take(10).toList();
    }

    await _prefs.setStringList('recent_urls', _recentUrls);
    notifyListeners();
  }

  /// 최근 URL 선택
  void selectRecentUrl(String url) {
    setUrl(url);
  }

  /// 최근 URL 기록 삭제
  Future<void> clearRecentUrls() async {
    _recentUrls.clear();
    await _prefs.remove('recent_urls');
    notifyListeners();
  }

  /// 크롤링 상태 초기화
  void resetCrawlState() {
    _crawlProgress = 0.0;
    _crawlStatusMessage = '';
    _crawlResult = null;
    clearAllMessages();
  }
}
