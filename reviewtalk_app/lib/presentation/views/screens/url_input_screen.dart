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
              productId: viewModel.currentUrl,
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
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Consumer<UrlInputViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              // 메인 그라데이션 배경 (Figma 디자인)
              Container(
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
                        const Spacer(flex: 3),
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
                      ],
                    ),
                  ),
                ),
              ),
              // 하단 모달 (Figma 디자인) - 키보드가 올라오면 숨김
              if (!isKeyboardOpen)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomModal(viewModel),
                ),
            ],
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

  Widget _buildBottomModal(UrlInputViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: 264,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        color: AppColors.modalBackground,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          // 모달 핸들
          const SizedBox(height: 12),
          Container(
            width: 84,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.modalHandle,
            ),
          ),

          const SizedBox(height: 37), // Figma 위치에 맞춤
          // "my chat" 타이틀
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 27),
              child: Text(
                'my chat',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'SouliyoUnicode', // Figma 폰트
                  fontSize: 24,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal,
                  height: 1,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 최근 검색 기록
          if (viewModel.recentUrls.isNotEmpty)
            Expanded(child: _buildRecentSearches(viewModel))
          else
            Expanded(
              child: Center(
                child: Text(
                  '아직 검색 기록이 없습니다\n위에서 상품을 검색해보세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(UrlInputViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 27),
      itemCount: viewModel.recentUrls.take(4).length,
      itemBuilder: (context, index) {
        final url = viewModel.recentUrls[index];
        final productCode = _extractProductCode(url);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              _urlController.text = url;
              viewModel.setUrl(url);
              _startCrawling();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productCode != null
                              ? '상품 $productCode'
                              : '상품 ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatUrl(url),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _extractProductCode(String url) {
    final patterns = [RegExp(r'code=(\d+)'), RegExp(r'pcode=(\d+)')];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  String _formatUrl(String url) {
    if (url.length > 40) {
      return '${url.substring(0, 40)}...';
    }
    return url;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                deals.take(3).map((deal) => _buildDealCard(deal)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                deals
                    .skip(3)
                    .take(3)
                    .map((deal) => _buildDealCard(deal))
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(Map deal) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${deal['discount']}↓',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('💬즉시채팅', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
