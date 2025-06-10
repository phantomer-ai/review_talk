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

/// 다나와 URL 입력 화면
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

      // URL 컨트롤러 초기화
      _urlController.text = viewModel.currentUrl;
      _maxReviewsController.text = viewModel.maxReviews.toString();

      // ViewModel 변화 감지
      viewModel.addListener(_onViewModelChange);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _maxReviewsController.dispose();
    _urlFocusNode.dispose();

    // 리스너 제거
    final viewModel = context.read<UrlInputViewModel>();
    viewModel.removeListener(_onViewModelChange);

    super.dispose();
  }

  void _onViewModelChange() {
    final viewModel = context.read<UrlInputViewModel>();

    // 크롤링 완료시 채팅 화면으로 이동
    if (viewModel.crawlResult != null && !viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToChat(viewModel);
      });
    }

    // 에러 발생시 스낵바 표시
    if (viewModel.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorSnackBar.show(
          context: context,
          message: viewModel.errorMessage!,
          actionLabel: AppStrings.retry,
          onAction: () => viewModel.clearError(),
        );
      });
    }

    // 성공 메시지 표시
    if (viewModel.hasSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SuccessSnackBar.show(
          context: context,
          message: viewModel.successMessage!,
        );
      });
    }
  }

  void _navigateToChat(UrlInputViewModel viewModel) {
    final result = viewModel.crawlResult!;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
              productId: viewModel.currentUrl, // 전체 URL 전달
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

    if (success) {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.urlInputTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: Consumer<UrlInputViewModel>(
        builder: (context, viewModel, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더 섹션
                  _buildHeader(),

                  const SizedBox(height: 32),

                  // URL 입력 폼
                  UrlInputForm(
                    urlController: _urlController,
                    maxReviewsController: _maxReviewsController,
                    urlFocusNode: _urlFocusNode,
                    onUrlChanged: viewModel.setUrl,
                    onMaxReviewsChanged: (value) {
                      final count = int.tryParse(value) ?? 50;
                      viewModel.setMaxReviews(count);
                    },
                    errorMessage: viewModel.getUrlValidationError(),
                  ),

                  const SizedBox(height: 24),

                  // 분석 시작 버튼
                  CustomButton.primary(
                    text: AppStrings.urlInputButton,
                    onPressed: viewModel.isUrlValid() ? _startCrawling : null,
                    isLoading: viewModel.isLoading,
                    isEnabled: !viewModel.isLoading,
                    icon: Icons.search,
                    height: 56,
                    semanticLabel: AppStrings.urlInputButton,
                  ),

                  const SizedBox(height: 32),

                  // URL 형식 안내
                  _buildUrlExamples(),

                  const SizedBox(height: 32),

                  // 최근 검색 기록
                  if (viewModel.recentUrls.isNotEmpty) ...[
                    _buildRecentSearches(viewModel),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 앱 아이콘
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.smart_toy,
            size: 40,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 16),

        // 제목
        Text(
          AppStrings.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),

        const SizedBox(height: 8),

        // 부제목
        Text(
          AppStrings.urlInputSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUrlExamples() {
    return Card(
      color: AppColors.surfaceVariant,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  AppStrings.urlInputExampleTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ...const [
              AppStrings.urlInputExample1,
              AppStrings.urlInputExample2,
              AppStrings.urlInputExample3,
            ].map(
              (example) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  example,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontFamily: 'Monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(UrlInputViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.recentSearchTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text(AppStrings.recentSearchClear),
                        content: const Text(
                          AppStrings.recentSearchClearConfirm,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(AppStrings.cancel),
                          ),
                          TextButton(
                            onPressed: () {
                              viewModel.clearRecentUrls();
                              Navigator.pop(context);
                            },
                            child: const Text(AppStrings.delete),
                          ),
                        ],
                      ),
                );
              },
              child: const Text(AppStrings.recentSearchClear),
            ),
          ],
        ),

        const SizedBox(height: 16),

        ...viewModel.recentUrls
            .take(5)
            .map(
              (url) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.history, color: AppColors.primary),
                  title: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onTap: () {
                    _urlController.text = url;
                    viewModel.selectRecentUrl(url);
                    _urlFocusNode.requestFocus();
                  },
                ),
              ),
            ),
      ],
    );
  }
}
