import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// 로딩 인디케이터 위젯
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;
  final bool showMessage;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 50,
            height: size ?? 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
            ),
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 진행률을 표시하는 로딩 위젯
class ProgressLoadingWidget extends StatelessWidget {
  final double progress;
  final String? title;
  final String? subtitle;
  final VoidCallback? onCancel;

  const ProgressLoadingWidget({
    super.key,
    required this.progress,
    this.title,
    this.subtitle,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 로딩 애니메이션
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                backgroundColor: AppColors.outlineVariant,
              ),
            ),

            const SizedBox(height: 24),

            // 제목
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],

            // 진행률 표시
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.titleLarge?.copyWith(
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
              child: FractionallySizedBox(
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
            ),

            const SizedBox(height: 16),

            // 상태 메시지
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            // 취소 버튼
            if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text(AppStrings.cancel),
              ),
          ],
        ),
      ),
    );
  }
}

/// 인라인 로딩 위젯 (작은 크기)
class InlineLoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;

  const InlineLoadingWidget({super.key, this.message, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 8),
          Text(
            message!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// 오버레이 로딩 위젯 (전체 화면을 덮는 로딩)
class OverlayLoadingWidget extends StatelessWidget {
  final String? message;
  final bool isVisible;

  const OverlayLoadingWidget({super.key, this.message, this.isVisible = true});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: AppColors.scrim.withValues(alpha: 0.7),
      child: LoadingWidget(
        message: message ?? AppStrings.loadingTitle,
        color: AppColors.surface,
      ),
    );
  }
}

/// 하단 고정 크롤링 로딩바 위젯
class BottomCrawlingLoadingWidget extends StatelessWidget {
  final double progress;
  final String statusMessage;
  final VoidCallback? onCancel;

  const BottomCrawlingLoadingWidget({
    super.key,
    required this.progress,
    required this.statusMessage,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상태 메시지
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress > 0 ? progress : null,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      '중지',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 진행률 바
            LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: AppColors.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
            if (progress > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
