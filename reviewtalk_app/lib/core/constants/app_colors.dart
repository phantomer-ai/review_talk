import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 팔레트 - 파란보라 테마
class AppColors {
  AppColors._();

  // Primary Colors - 메인 파란보라색
  static const Color primary = Color(0xFF6B73FF);
  static const Color primaryContainer = Color(0xFF9B9EFF);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF000080);

  // Secondary Colors - 부드러운 보라톤
  static const Color secondary = Color(0xFF8E9FFF);
  static const Color secondaryContainer = Color(0xFFB5C2FF);
  static const Color onSecondary = Colors.white;
  static const Color onSecondaryContainer = Color(0xFF001A80);

  // Surface Colors - 깔끔한 흰색
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF7F8FF);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF4A4A4A);

  // Background Colors - 매우 연한 파란 배경
  static const Color background = Color(0xFFFAFBFF);
  static const Color onBackground = Color(0xFF1A1A1A);

  // Error Colors
  static const Color error = Color(0xFFFF5252);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onError = Colors.white;
  static const Color onErrorContainer = Color(0xFFC62828);

  // Success Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFFE8F5E8);
  static const Color onSuccess = Colors.white;
  static const Color onSuccessContainer = Color(0xFF2E7D32);

  // Warning Colors
  static const Color warning = Color(0xFFFF9800);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarning = Colors.white;
  static const Color onWarningContainer = Color(0xFFE65100);

  // Chat Colors - 메시지 말풍선
  static const Color userBubble = Color(0xFF6B73FF);
  static const Color aiBubble = Color(0xFFF7F8FF);
  static const Color onUserBubble = Colors.white;
  static const Color onAiBubble = Color(0xFF1A1A1A);

  // Neutral Colors
  static const Color outline = Color(0xFFDDDDDD);
  static const Color outlineVariant = Color(0xFFEEEEEE);
  static const Color scrim = Color(0xFF000000);

  // Additional Utility Colors
  static const Color transparent = Colors.transparent;
  static const Color shadow = Color(0x1A6B73FF);
  static const Color disabled = Color(0x61000000);

  // Loading Colors - 로딩 화면용
  static const Color loadingBackground = Color(0xFF6B73FF);
  static const Color onLoadingBackground = Colors.white;

  // Figma 디자인 색상들
  static const Color gradientStart = Color.fromRGBO(94, 90, 224, 0.68);
  static const Color gradientEnd = Color.fromRGBO(240, 241, 248, 1);
  static const Color mainBlue = Color.fromRGBO(77, 128, 238, 1);
  static const Color modalBackground = Color.fromRGBO(255, 255, 255, 1);
  static const Color modalHandle = Color.fromRGBO(245, 245, 245, 1);

  // Figma 그라데이션
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomLeft,
    colors: [gradientStart, gradientEnd],
  );
}
