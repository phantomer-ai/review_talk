import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/special_product_model.dart';
import '../../../data/datasources/remote/special_deals_api.dart';
import '../../viewmodels/url_input_viewmodel.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/url_input/url_input_form.dart';
import 'loading_screen.dart';
import 'chat_screen.dart';

/// Figma 디자인을 참고한 메인 화면
class UrlInputScreen extends StatefulWidget {
  const UrlInputScreen({super.key});

  @override
  State<UrlInputScreen> createState() => _UrlInputScreenState();
}

class _UrlInputScreenState extends State<UrlInputScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _maxReviewsController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  List<SpecialProductModel> _specialDeals = [];
  bool _isLoadingDeals = false;

  @override
  void initState() {
    super.initState();

    // ViewModel 리스너 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<UrlInputViewModel>();
      _urlController.text = viewModel.currentUrl;
      _maxReviewsController.text = viewModel.maxReviews.toString();
      viewModel.addListener(_onViewModelChange);

      // 특가 상품 로드
      _loadSpecialDeals();
    });
  }

  /// 대체 로고 위젯 생성
  Widget _buildFallbackLogo() {
    return Container(
      height: 60,
      child: Center(
        child: Text(
          '📱 ReviewTalk',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _maxReviewsController.dispose();
    _urlFocusNode.dispose();

    try {
      final viewModel = context.read<UrlInputViewModel>();
      viewModel.removeListener(_onViewModelChange);
    } catch (e) {
      // 이미 dispose된 경우 무시
    }

    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;

    final viewModel = context.read<UrlInputViewModel>();

    // 크롤링 완료시 채팅 화면으로 이동
    if (viewModel.crawlResult != null && !viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToChat(viewModel);
        }
      });
    }

    // 에러 발생시 스낵바 표시
    if (viewModel.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage ?? '오류가 발생했습니다'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }

    // 성공 메시지 표시
    if (viewModel.hasSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SuccessSnackBar.show(
            context: context,
            message: viewModel.successMessage!,
          );
        }
      });
    }
  }

  void _navigateToChat(UrlInputViewModel viewModel) {
    final result = viewModel.crawlResult!;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
              productId: viewModel.currentUrl,
              productName: result.productName,
              productImage: result.productImage,
              productPrice: result.productPrice,
            ),
      ),
    );
  }

  /// 특가 상품 데이터 로드
  Future<void> _loadSpecialDeals() async {
    if (!mounted) return;

    setState(() {
      _isLoadingDeals = true;
    });

    try {
      final deals = await SpecialDealsApi.getSpecialDeals(limit: 6);
      print('특가 상품 로드 완료: ${deals.length}개');
      for (int i = 0; i < deals.length && i < 3; i++) {
        print('상품 ${i + 1}: ${deals[i].productName}');
        print('이미지 URL: ${deals[i].imageUrl}');
        print('가격: ${deals[i].price}');
        print('할인율: ${deals[i].discountRate}');
        print('---');
      }
      if (mounted) {
        setState(() {
          _specialDeals = deals;
          _isLoadingDeals = false;
        });
      }
    } catch (e) {
      print('특가 상품 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingDeals = false;
        });
      }
    }
  }

  /// 특가 상품 채팅 시작
  void _startChatWithProduct(SpecialProductModel product) {
    if (!product.canChat) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.shortName}의 리뷰 데이터가 아직 준비되지 않았습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
              productId: product.productId,
              productName: product.productName,
              productImage: product.imageUrl,
              productPrice: product.price,
            ),
      ),
    );
  }

  /// 다나와 상품 페이지 열기
  Future<void> _openDanawaProduct(SpecialProductModel product) async {
    try {
      final uri = Uri.parse(product.productUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 외부 브라우저에서 열기
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('상품 페이지를 열 수 없습니다.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상품 페이지 열기 오류: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _startCrawling() async {
    final viewModel = context.read<UrlInputViewModel>();

    // URL 설정
    viewModel.setUrl(_urlController.text);

    // 최대 리뷰 수 설정
    final maxReviews = int.tryParse(_maxReviewsController.text) ?? 50;
    viewModel.setMaxReviews(maxReviews);

    // 키보드 숨기기
    FocusScope.of(context).unfocus();

    // 크롤링 시작
    final success = await viewModel.startCrawling();

    if (success && mounted) {
      // 로딩 화면으로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => LoadingScreen(
                onComplete: () => _navigateToChat(viewModel),
                onCancel: () {
                  viewModel.resetCrawlState();
                  Navigator.of(context).pop();
                },
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Consumer<UrlInputViewModel>(
        builder: (context, viewModel, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.mainGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 로고 영역 (최상단 중앙)
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 16),
                      child: Center(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(color: Colors.transparent),
                          child: Image.asset(
                            'assets/images/ReviewTalk_logo_white.png',
                            height: 60,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('🚨 로고 이미지 로딩 실패: $error');
                              debugPrint('🚨 스택 트레이스: $stackTrace');
                              return _buildFallbackLogo();
                            },
                          ),
                        ),
                      ),
                    ),
                    // URL 입력창
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 27,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchInput(viewModel),
                          const SizedBox(height: 24),
                          // 크롤링 개수 슬라이더
                          Text(
                            '리뷰 ${viewModel.maxReviews}개 크롤링',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Slider(
                            value: viewModel.maxReviews.toDouble().clamp(
                              50,
                              300,
                            ),
                            min: 50,
                            max: 300,
                            divisions: 5,
                            label: '${viewModel.maxReviews}',
                            onChanged: (value) {
                              viewModel.setMaxReviews(value.round());
                            },
                            activeColor: AppColors.mainBlue,
                            inactiveColor: Colors.white24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '수집하는 리뷰가 많을수록 채팅은 정확하지만 리뷰수집 시간이 오래걸릴수있습니다',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 특가 상품 리스트
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 27),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '🏷️ 놓치면 후회하는 오늘의 특가',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSpecialDeals(),
                    const SizedBox(height: 50), // 하단 여백
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchInput(UrlInputViewModel viewModel) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: TextField(
        controller: _urlController,
        focusNode: _urlFocusNode,
        onChanged: viewModel.setUrl,
        onSubmitted: (_) => _startCrawling(),
        decoration: InputDecoration(
          hintText: '다나와 상품 URL을 입력하세요',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 24),
          suffixIcon:
              viewModel.isUrlValid()
                  ? IconButton(
                    onPressed: viewModel.isLoading ? null : _startCrawling,
                    icon:
                        viewModel.isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.mainBlue,
                                ),
                              ),
                            )
                            : Icon(
                              Icons.arrow_forward,
                              color: AppColors.mainBlue,
                            ),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildSpecialDeals() {
    if (_isLoadingDeals) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_specialDeals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.local_offer,
                size: 48,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                '아직 특가 상품이 없습니다',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '잠시 후 다시 확인해보세요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 6개씩 2행으로 표시
    final firstRow = _specialDeals.take(3).toList();
    final secondRow = _specialDeals.skip(3).take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 첫 번째 행
          if (firstRow.isNotEmpty)
            Row(
              children: [
                for (int i = 0; i < firstRow.length; i++) ...[
                  Expanded(child: _buildDealCard(firstRow[i])),
                  if (i < firstRow.length - 1) const SizedBox(width: 8),
                ],
                // 빈 공간을 채우기 위해 더미 카드 추가
                for (int i = firstRow.length; i < 3; i++) ...[
                  const SizedBox(width: 8),
                  Expanded(child: Container()),
                ],
              ],
            ),
          if (firstRow.isNotEmpty && secondRow.isNotEmpty)
            const SizedBox(height: 16),
          // 두 번째 행
          if (secondRow.isNotEmpty)
            Row(
              children: [
                for (int i = 0; i < secondRow.length; i++) ...[
                  Expanded(child: _buildDealCard(secondRow[i])),
                  if (i < secondRow.length - 1) const SizedBox(width: 8),
                ],
                // 빈 공간을 채우기 위해 더미 카드 추가
                for (int i = secondRow.length; i < 3; i++) ...[
                  const SizedBox(width: 8),
                  Expanded(child: Container()),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDealCard(SpecialProductModel product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상품 이미지 (클릭 가능)
          GestureDetector(
            onTap: () => _openDanawaProduct(product),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    product.imageUrl != null &&
                            product.imageUrl!.trim().isNotEmpty
                        ? Image.network(
                          'http://192.168.35.68:8000/api/v1/special-deals/image-proxy?url=${Uri.encodeComponent(product.imageUrl!)}',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print('✅ 이미지 로딩 성공: ${product.imageUrl}');
                              return child;
                            }
                            print('⏳ 이미지 로딩 중: ${product.imageUrl}');
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade100,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ 이미지 로딩 실패: ${product.imageUrl}');
                            print('❌ 오류: $error');
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.red.shade50,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 20,
                                    color: Colors.red.shade300,
                                  ),
                                  Text(
                                    'FAIL',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                        : Container(
                          width: 60,
                          height: 60,
                          color: Colors.orange.shade50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 20,
                                color: Colors.orange.shade400,
                              ),
                              Text(
                                'NO URL',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 상품명 (클릭 가능)
          GestureDetector(
            onTap: () => _openDanawaProduct(product),
            child: Text(
              product.shortName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Colors.black87,
                decoration: TextDecoration.underline, // 클릭 가능함을 표시
                decorationColor: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          // 할인율
          if (product.discountRate != null && product.discountRate!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product.discountRate!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 4),
          // 가격 정보
          Column(
            children: [
              if (product.price != null && product.price!.isNotEmpty)
                Text(
                  product.price!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (product.originalPrice != null &&
                  product.originalPrice!.isNotEmpty)
                Text(
                  product.originalPrice!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.lineThrough,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 채팅 버튼
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed:
                  product.canChat ? () => _startChatWithProduct(product) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    product.canChat ? AppColors.primary : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                product.canChat ? '💬즉시채팅' : '⏳준비중',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
