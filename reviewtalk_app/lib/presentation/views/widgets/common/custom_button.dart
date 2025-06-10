import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// 커스텀 버튼 위젯
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final CustomButtonStyle style;
  final IconData? icon;
  final double? width;
  final double? height;
  final String? semanticLabel;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.style = CustomButtonStyle.primary,
    this.icon,
    this.width,
    this.height,
    this.semanticLabel,
  });

  /// Primary 버튼 (주요 액션용)
  const CustomButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
    this.semanticLabel,
  }) : style = CustomButtonStyle.primary;

  /// Secondary 버튼 (보조 액션용)
  const CustomButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
    this.semanticLabel,
  }) : style = CustomButtonStyle.secondary;

  /// Outlined 버튼 (테두리만 있는 버튼)
  const CustomButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
    this.semanticLabel,
  }) : style = CustomButtonStyle.outlined;

  /// Text 버튼 (배경 없는 텍스트 버튼)
  const CustomButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
    this.semanticLabel,
  }) : style = CustomButtonStyle.text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isButtonEnabled = isEnabled && !isLoading && onPressed != null;

    Widget buttonChild;

    if (isLoading) {
      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getTextColor(theme, isButtonEnabled),
          ),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)],
      );
    } else {
      buttonChild = Text(text);
    }

    Widget button;

    switch (style) {
      case CustomButtonStyle.primary:
        button = ElevatedButton(
          onPressed: isButtonEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isButtonEnabled ? AppColors.primary : AppColors.disabled,
            foregroundColor: _getTextColor(theme, isButtonEnabled),
            disabledBackgroundColor: AppColors.disabled,
            disabledForegroundColor: AppColors.onSurface.withOpacity(0.38),
            elevation: isButtonEnabled ? 2 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: buttonChild,
        );
        break;

      case CustomButtonStyle.secondary:
        button = ElevatedButton(
          onPressed: isButtonEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isButtonEnabled ? AppColors.secondary : AppColors.disabled,
            foregroundColor: _getTextColor(theme, isButtonEnabled),
            disabledBackgroundColor: AppColors.disabled,
            disabledForegroundColor: AppColors.onSurface.withOpacity(0.38),
            elevation: isButtonEnabled ? 1 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: buttonChild,
        );
        break;

      case CustomButtonStyle.outlined:
        button = OutlinedButton(
          onPressed: isButtonEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isButtonEnabled ? AppColors.primary : AppColors.disabled,
            disabledForegroundColor: AppColors.onSurface.withOpacity(0.38),
            side: BorderSide(
              color: isButtonEnabled ? AppColors.primary : AppColors.disabled,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: buttonChild,
        );
        break;

      case CustomButtonStyle.text:
        button = TextButton(
          onPressed: isButtonEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor:
                isButtonEnabled ? AppColors.primary : AppColors.disabled,
            disabledForegroundColor: AppColors.onSurface.withOpacity(0.38),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    // 크기 지정이 있는 경우 컨테이너로 감싸기
    if (width != null || height != null) {
      button = SizedBox(width: width, height: height ?? 48, child: button);
    }

    // 접근성 라벨 추가
    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: isButtonEnabled,
        child: button,
      );
    }

    return button;
  }

  Color _getTextColor(ThemeData theme, bool isEnabled) {
    if (!isEnabled) {
      return AppColors.onSurface.withOpacity(0.38);
    }

    switch (style) {
      case CustomButtonStyle.primary:
        return AppColors.onPrimary;
      case CustomButtonStyle.secondary:
        return AppColors.onSecondary;
      case CustomButtonStyle.outlined:
      case CustomButtonStyle.text:
        return AppColors.primary;
    }
  }
}

/// 버튼 스타일 열거형
enum CustomButtonStyle { primary, secondary, outlined, text }
