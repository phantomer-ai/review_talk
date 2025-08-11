import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'url_input_screen.dart';
import 'chat_history_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';

/// 메인 화면 - 하단 탭 네비게이션
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 채팅 화면 표시 상태
  bool _showChatScreen = false;
  String? _chatProductId;
  String? _chatProductName;
  String? _chatProductImage;
  String? _chatProductPrice;

  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _bottomNavItems;

  @override
  void initState() {
    super.initState();

    _screens = [
      UrlInputScreen(onChatRequested: _showChat), // 홈 - 기존 URL 입력 기능
      ChatHistoryScreen(
        onUrlSelected: _goToHome,
        onChatRequested: _showChat,
      ), // 히스토리 - 검색 기록
      const SettingsScreen(), // 설정
    ];

    _bottomNavItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: '',
      ),
    ];
  }

  /// 홈 탭으로 이동
  void _goToHome() {
    setState(() {
      _currentIndex = 0;
      _showChatScreen = false;
    });
  }

  /// 채팅 화면 표시
  void _showChat(
    String productId,
    String? productName,
    String? productImage,
    String? productPrice,
  ) {
    setState(() {
      _showChatScreen = true;
      _chatProductId = productId;
      _chatProductName = productName;
      _chatProductImage = productImage;
      _chatProductPrice = productPrice;
    });
  }

  /// 채팅 화면 닫기
  void _closeChat() {
    setState(() {
      _showChatScreen = false;
      _chatProductId = null;
      _chatProductName = null;
      _chatProductImage = null;
      _chatProductPrice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 기본 탭 화면들
          IndexedStack(index: _currentIndex, children: _screens),

          // 채팅 화면 오버레이
          if (_showChatScreen)
            ChatScreen(
              productId: _chatProductId!,
              productName: _chatProductName,
              productImage: _chatProductImage,
              productPrice: _chatProductPrice,
              onBack: _closeChat,
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // 다른 탭으로 이동하면 채팅 화면 닫기
            if (_showChatScreen) {
              _closeChat();
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 8,
        items: _bottomNavItems,
      ),
    );
  }
}
