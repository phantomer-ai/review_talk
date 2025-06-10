import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 팔레트
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryContainer = Color(0xFFE3F2FD);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF0D47A1);

  // Secondary Colors
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryContainer = Color(0xFF018786);
  static const Color onSecondary = Colors.black;
  static const Color onSecondaryContainer = Colors.white;

  // Surface Colors
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // Background Colors
  static const Color background = Color(0xFFFEFBFF);
  static const Color onBackground = Color(0xFF1C1B1F);

  // Error Colors
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onError = Colors.white;
  static const Color onErrorContainer = Color(0xFF410E0B);

  // Success Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color onSuccess = Colors.white;
  static const Color onSuccessContainer = Color(0xFF1B5E20);

  // Warning Colors
  static const Color warning = Color(0xFFF57C00);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color onWarning = Colors.white;
  static const Color onWarningContainer = Color(0xFFE65100);

  // Chat Colors
  static const Color userBubble = Color(0xFF1976D2);
  static const Color aiBubble = Color(0xFFF5F5F5);
  static const Color onUserBubble = Colors.white;
  static const Color onAiBubble = Color(0xFF1C1B1F);

  // Neutral Colors
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
  static const Color scrim = Color(0xFF000000);

  // Additional Utility Colors
  static const Color transparent = Colors.transparent;
  static const Color shadow = Color(0x1A000000);
  static const Color disabled = Color(0x61000000);
}
