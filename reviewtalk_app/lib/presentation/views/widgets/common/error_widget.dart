import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import 'custom_button.dart';

/// 에러 표시 위젯
class CustomErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryText;
  final bool showRetryButton;

  const CustomErrorWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryText,
    this.showRetryButton = true,
  });

  /// 네트워크 에러 위젯
  const CustomErrorWidget.network({
    super.key,
    this.onRetry,
    this.retryText,
    this.showRetryButton = true,
  }) : title = AppStrings.errorNetwork,
       message = '인터넷 연결을 확인하고 다시 시도해주세요.',
       icon = Icons.wifi_off;

  /// 서버 에러 위젯
  const CustomErrorWidget.server({
    super.key,
    this.onRetry,
    this.retryText,
    this.showRetryButton = true,
  }) : title = AppStrings.errorServer,
       message = '잠시 후 다시 시도해주세요.',
       icon = Icons.error_outline;

  /// 일반 에러 위젯
  const CustomErrorWidget.general({
    super.key,
    this.message,
    this.onRetry,
    this.retryText,
    this.showRetryButton = true,
  }) : title = AppStrings.errorGeneral,
       icon = Icons.error_outline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 에러 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),

            const SizedBox(height: 24),

            // 에러 제목
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

            // 에러 메시지
            if (message != null) ...[
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            // 재시도 버튼
            if (showRetryButton && onRetry != null)
              CustomButton.primary(
                text: retryText ?? AppStrings.retry,
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
          ],
        ),
      ),
    );
  }
}

/// 인라인 에러 위젯 (작은 크기)
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Color? color;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: color ?? AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color ?? AppColors.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              iconSize: 18,
              color: color ?? AppColors.error,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }
}

/// 에러 스낵바 표시 헬퍼
class ErrorSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.onError, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.onError),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action:
            actionLabel != null && onAction != null
                ? SnackBarAction(
                  label: actionLabel,
                  textColor: AppColors.onError,
                  onPressed: onAction,
                )
                : null,
      ),
    );
  }
}

/// 성공 스낵바 표시 헬퍼
class SuccessSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.onSuccess,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.onSuccess),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
