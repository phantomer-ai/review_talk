import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'url_input_screen.dart';
import 'chat_history_screen.dart';
import 'settings_screen.dart';

/// 메인 화면 - 하단 탭 네비게이션
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _bottomNavItems;

  @override
  void initState() {
    super.initState();

    _screens = [
      const UrlInputScreen(), // 홈 - 기존 URL 입력 기능
      ChatHistoryScreen(onUrlSelected: _goToHome), // 히스토리 - 검색 기록
      const SettingsScreen(), // 설정
    ];

    _bottomNavItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: '홈',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: '채팅',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: '설정',
      ),
    ];
  }

  /// 홈 탭으로 이동
  void _goToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        elevation: 8,
        items: _bottomNavItems,
      ),
    );
  }
}
