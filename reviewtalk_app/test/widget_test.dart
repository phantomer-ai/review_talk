// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reviewtalk_app/main.dart';
import 'package:reviewtalk_app/core/constants/app_constants.dart';

void main() {
  testWidgets('ReviewTalk app basic test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ReviewTalkApp());

    // Verify that our app shows the correct title.
    expect(find.text(AppConstants.appName), findsWidgets);

    // Verify that the description is shown.
    expect(find.textContaining('다나와 상품 리뷰를'), findsOneWidget);

    // Verify that Phase 1 completion message is shown.
    expect(find.textContaining('Phase 1: 프로젝트 기반 구축 완료!'), findsOneWidget);

    // Verify that the chat icon is present.
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });
}
