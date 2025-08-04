import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../viewmodels/url_input_viewmodel.dart';

/// 크롤링 진행 상태를 표시하는 로딩 화면 - Figma 스타일
class LoadingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const LoadingScreen({super.key, this.onComplete, this.onCancel});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.repeat();

    // ViewModel 리스너 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<UrlInputViewModel>();
      viewModel.addListener(_onViewModelChange);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();

    // 리스너 제거
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

    // 크롤링 완료시 콜백 호출
    if (viewModel.crawlResult != null && !viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    }

    // 에러 발생시 화면 닫기
    if (viewModel.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 뒤로가기 비활성화
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.mainGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Consumer<UrlInputViewModel>(
            builder: (context, viewModel, child) {
              return SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // 로딩 스피너
                    _buildLoadingSpinner(),

                    const SizedBox(height: 48),

                    // 로딩 메시지
                    Text(
                      'AI가 리뷰를 읽고 있습니다',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // 상세 상태 메시지
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        viewModel.crawlStatusMessage.isNotEmpty
                            ? viewModel.crawlStatusMessage
                            : '상품 리뷰를 분석하고 있어요...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 진행률 바
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: LinearProgressIndicator(
                        value:
                            viewModel.crawlProgress > 0
                                ? viewModel.crawlProgress
                                : null,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                        minHeight: 3,
                      ),
                    ),

                    if (viewModel.crawlProgress > 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${(viewModel.crawlProgress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],

                    const Spacer(flex: 3),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSpinner() {
    return RotationTransition(
      turns: _animationController,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white.withValues(alpha: 0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }
}
