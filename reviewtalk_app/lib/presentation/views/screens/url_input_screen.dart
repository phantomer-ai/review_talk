import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../viewmodels/url_input_viewmodel.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/url_input/url_input_form.dart';
import 'loading_screen.dart';
import 'chat_screen.dart';
import 'package:reviewtalk_app/core/utils/app_logger.dart';

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

  @override
  void initState() {
    super.initState();

    // ViewModel 리스너 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<UrlInputViewModel>();
      _urlController.text = viewModel.currentUrl;
      _maxReviewsController.text = viewModel.maxReviews.toString();
      viewModel.addListener(_onViewModelChange);
    });
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
              productId: viewModel.productId ?? viewModel.currentUrl,
              productName: result.productName,
            ),
      ),
    );
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
                    // URL 입력창을 최상단으로 이동
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 27,
                        vertical: 24,
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
                            value: viewModel.maxReviews.toDouble(),
                            min: 100,
                            max: 1000,
                            divisions: 9,
                            label: '${viewModel.maxReviews}',
                            onChanged: (value) {
                              viewModel.setMaxReviews(value.round());
                            },
                            activeColor: AppColors.mainBlue,
                            inactiveColor: Colors.white24,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 메인 타이틀 (Figma 위치)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80),
                      child: Text(
                        'chat what you want',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'LibreBarcode128Text', // Figma 폰트
                          fontSize: 40,
                          letterSpacing: 0,
                          fontWeight: FontWeight.normal,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    // 특가 상품 리스트 (더미 데이터)
                    const SizedBox(height: 32),
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
                    _buildDummySpecialDeals(),
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

  Widget _buildDummySpecialDeals() {
    // 더미 특가 상품 데이터
    final deals = [
      {
        'icon': Icons.headphones,
        'name': '갤럭시 버즈Pro',
        'discount': '15%',
        'chat': true,
      },
      {
        'icon': Icons.phone_iphone,
        'name': '아이폰15 프로',
        'discount': '5%',
        'chat': true,
      },
      {
        'icon': Icons.laptop_mac,
        'name': 'LG그램 노트북',
        'discount': '20%',
        'chat': true,
      },
      {
        'icon': Icons.cleaning_services,
        'name': '다이슨 청소기',
        'discount': '12%',
        'chat': true,
      },
      {'icon': Icons.monitor, 'name': '삼성모니터', 'discount': '8%', 'chat': true},
      {
        'icon': Icons.sports_esports,
        'name': 'PS5',
        'discount': '3%',
        'chat': true,
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 첫 번째 행
          Row(
            children: [
              Expanded(child: _buildDealCard(deals[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildDealCard(deals[1])),
              const SizedBox(width: 8),
              Expanded(child: _buildDealCard(deals[2])),
            ],
          ),
          const SizedBox(height: 16),
          // 두 번째 행
          Row(
            children: [
              Expanded(child: _buildDealCard(deals[3])),
              const SizedBox(width: 8),
              Expanded(child: _buildDealCard(deals[4])),
              const SizedBox(width: 8),
              Expanded(child: _buildDealCard(deals[5])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(Map deal) {
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
          Icon(deal['icon'], size: 32, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            deal['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${deal['discount']}↓',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('💬즉시채팅', style: TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}
