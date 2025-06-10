import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../viewmodels/url_input_viewmodel.dart';
import '../widgets/common/custom_button.dart';

/// 크롤링 진행 상태를 표시하는 로딩 화면
class LoadingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const LoadingScreen({super.key, this.onComplete, this.onCancel});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 회전 애니메이션 설정
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // 펄스 애니메이션 설정
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 애니메이션 시작
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);

    // ViewModel 리스너 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<UrlInputViewModel>();
      viewModel.addListener(_onViewModelChange);
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();

    // 리스너 제거
    final viewModel = context.read<UrlInputViewModel>();
    viewModel.removeListener(_onViewModelChange);

    super.dispose();
  }

  void _onViewModelChange() {
    final viewModel = context.read<UrlInputViewModel>();

    // 크롤링 완료시 콜백 호출
    if (viewModel.crawlResult != null && !viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete?.call();
      });
    }

    // 에러 발생시 화면 닫기
    if (viewModel.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
    }
  }

  void _onCancel() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(AppStrings.loadingCancel),
            content: const Text(AppStrings.loadingCancelConfirm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel),
              ),
              CustomButton.primary(
                text: AppStrings.confirm,
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                  widget.onCancel?.call(); // 취소 콜백 호출
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _onCancel();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<UrlInputViewModel>(
          builder: (context, viewModel, child) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 상단 여백
                    const Spacer(flex: 2),

                    // 로딩 애니메이션
                    _buildLoadingAnimation(viewModel),

                    const SizedBox(height: 32),

                    // 제목
                    Text(
                      AppStrings.loadingTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // 진행률
                    _buildProgressIndicator(viewModel),

                    const SizedBox(height: 24),

                    // 상태 메시지
                    _buildStatusMessage(viewModel),

                    const Spacer(flex: 3),

                    // 취소 버튼
                    CustomButton.outlined(
                      text: AppStrings.cancel,
                      onPressed: _onCancel,
                      icon: Icons.close,
                      width: double.infinity,
                      height: 48,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingAnimation(UrlInputViewModel viewModel) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 외부 원 (펄스 애니메이션)
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withOpacity(0.3),
                ),
              ),
            );
          },
        ),

        // 중간 원
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryContainer,
          ),
        ),

        // 내부 회전 애니메이션
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  size: 40,
                  color: AppColors.onPrimary,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(UrlInputViewModel viewModel) {
    final progress = viewModel.crawlProgress;

    return Column(
      children: [
        // 진행률 텍스트
        Text(
          '${(progress * 100).toInt()}%',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 16),

        // 진행률 바
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: AppColors.outlineVariant,
          ),
          child: Stack(
            children: [
              // 진행률 채우기
              FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                ),
              ),

              // 반짝이는 효과
              if (progress < 1.0)
                Positioned(
                  left:
                      (MediaQuery.of(context).size.width - 48) * progress - 20,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value - 0.8,
                        child: Container(
                          width: 40,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.surface,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(UrlInputViewModel viewModel) {
    final message =
        viewModel.crawlStatusMessage ??
        _getDefaultStatusMessage(viewModel.crawlProgress);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 상태 아이콘
          Icon(
            _getStatusIcon(viewModel.crawlProgress),
            size: 20,
            color: AppColors.primary,
          ),

          const SizedBox(width: 12),

          // 상태 메시지
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDefaultStatusMessage(double progress) {
    if (progress < 0.2) {
      return AppStrings.loadingPreparing;
    } else if (progress < 0.4) {
      return AppStrings.loadingFetchingProduct;
    } else if (progress < 0.8) {
      return AppStrings.loadingCollectingReviews;
    } else if (progress < 1.0) {
      return AppStrings.loadingAnalyzing;
    } else {
      return AppStrings.loadingComplete;
    }
  }

  IconData _getStatusIcon(double progress) {
    if (progress < 0.2) {
      return Icons.hourglass_empty;
    } else if (progress < 0.4) {
      return Icons.download;
    } else if (progress < 0.8) {
      return Icons.list_alt;
    } else if (progress < 1.0) {
      return Icons.psychology;
    } else {
      return Icons.check_circle;
    }
  }
}
