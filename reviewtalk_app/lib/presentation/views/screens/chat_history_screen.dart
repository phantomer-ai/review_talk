import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../viewmodels/url_input_viewmodel.dart';

/// 채팅 기록 아이템 모델
class ChatHistoryItem {
  final String productIcon;
  final String productName;
  final String lastMessage;
  final String timeAgo;
  final int messageCount;
  final bool isFromUrl;
  final String? url;

  ChatHistoryItem({
    required this.productIcon,
    required this.productName,
    required this.lastMessage,
    required this.timeAgo,
    required this.messageCount,
    required this.isFromUrl,
    this.url,
  });
}

/// 채팅 히스토리 화면 - 새로운 심플한 디자인
class ChatHistoryScreen extends StatelessWidget {
  final VoidCallback? onUrlSelected;

  const ChatHistoryScreen({super.key, this.onUrlSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '채팅 탭',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '💬 최근 채팅 기록',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 80,
        actions: [
          Consumer<UrlInputViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.recentUrls.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearDialog(context, viewModel),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<UrlInputViewModel>(
        builder: (context, viewModel, child) {
          // 더미 채팅 데이터 + 실제 URL 기록 조합
          final chatList = _buildChatList(viewModel.recentUrls);

          if (chatList.isEmpty) {
            return const _EmptyHistoryView();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: chatList.length,
                  itemBuilder: (context, index) {
                    final chatItem = chatList[index];
                    return _ChatHistoryItem(
                      chatItem: chatItem,
                      onTap: () => _onChatItemTap(context, chatItem),
                    );
                  },
                ),
              ),
              _buildNewAnalysisButton(context),
            ],
          );
        },
      ),
    );
  }

  // 더미 데이터와 실제 기록을 조합한 채팅 목록 생성
  List<ChatHistoryItem> _buildChatList(List<String> recentUrls) {
    // 더미 채팅 데이터 (debugging.md 참고)
    final dummyChatList = [
      ChatHistoryItem(
        productIcon: '🎧',
        productName: '삼성 갤럭시 버즈2 프로',
        lastMessage: '배터리 지속시간이 어떤가요?',
        timeAgo: '2시간 전',
        messageCount: 8,
        isFromUrl: false,
      ),
      ChatHistoryItem(
        productIcon: '💻',
        productName: 'LG 그램 17인치 노트북',
        lastMessage: '무게는 얼마나 되나요?',
        timeAgo: '1일 전',
        messageCount: 12,
        isFromUrl: false,
      ),
      ChatHistoryItem(
        productIcon: '🧹',
        productName: '다이슨 V15 무선청소기',
        lastMessage: '소음이 심한가요?',
        timeAgo: '3일 전',
        messageCount: 5,
        isFromUrl: false,
      ),
      ChatHistoryItem(
        productIcon: '📱',
        productName: '아이폰 15 프로',
        lastMessage: '카메라 성능은 어떤가요?',
        timeAgo: '1주일 전',
        messageCount: 15,
        isFromUrl: false,
      ),
    ];

    // 실제 URL 기록을 채팅 아이템으로 변환
    final urlChatList =
        recentUrls.map((url) {
          final productCode = _extractProductCode(url);
          return ChatHistoryItem(
            productIcon: '🛍️',
            productName: productCode != null ? '상품 $productCode' : '분석된 상품',
            lastMessage: '분석이 완료되었습니다',
            timeAgo: '방금 전',
            messageCount: 1,
            isFromUrl: true,
            url: url,
          );
        }).toList();

    // 더미 데이터 + 실제 데이터 조합
    return [...urlChatList, ...dummyChatList];
  }

  void _onChatItemTap(BuildContext context, ChatHistoryItem chatItem) {
    if (chatItem.isFromUrl && chatItem.url != null) {
      // 실제 URL 기록인 경우 - 홈 탭으로 이동
      final viewModel = Provider.of<UrlInputViewModel>(context, listen: false);
      viewModel.selectRecentUrl(chatItem.url!);
      onUrlSelected?.call();
    } else {
      // 더미 데이터인 경우 - 개별 채팅 화면으로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => IndividualChatScreen(
                productName: chatItem.productName,
                productIcon: chatItem.productIcon,
              ),
        ),
      );
    }
  }

  String? _extractProductCode(String url) {
    final patterns = [RegExp(r'code=(\d+)'), RegExp(r'pcode=(\d+)')];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  Widget _buildNewAnalysisButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline.withOpacity(0.2), width: 1),
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          // 홈 탭으로 이동
          onUrlSelected?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            Text(
              '🔍 새 상품 분석하기',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, UrlInputViewModel viewModel) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('기록 삭제'),
            content: const Text('모든 검색 기록을 삭제하시겠습니까?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  viewModel.clearRecentUrls();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }
}

/// 빈 기록 화면
class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              '검색 기록이 없습니다',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '홈에서 상품을 검색하면\n기록이 여기에 표시됩니다',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카카오톡 스타일 채팅 기록 아이템
class _ChatHistoryItem extends StatelessWidget {
  final ChatHistoryItem chatItem;
  final VoidCallback onTap;

  const _ChatHistoryItem({required this.chatItem, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 상품 아이콘
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      chatItem.productIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 채팅 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상품명과 시간
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chatItem.productName,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            chatItem.timeAgo,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 마지막 메시지와 개수
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chatItem.lastMessage,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chatItem.messageCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${chatItem.messageCount}개 대화',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: AppColors.onPrimary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // 화살표
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 개별 채팅 화면 (더미 구현)
class IndividualChatScreen extends StatelessWidget {
  final String productName;
  final String productIcon;

  const IndividualChatScreen({
    super.key,
    required this.productName,
    required this.productIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(productIcon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '리뷰 500개 분석 완료',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 추천 질문 영역
          Container(
            width: double.infinity,
            color: AppColors.primaryContainer,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 추천 질문:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSuggestedButton(context, '배터리는?'),
                    _buildSuggestedButton(context, '음질좋나?'),
                    _buildSuggestedButton(context, '가격대비?'),
                    _buildSuggestedButton(context, '단점?'),
                  ],
                ),
              ],
            ),
          ),
          // 채팅 영역
          Expanded(
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text(
                  '채팅 기능은 실제 데이터 연동 후 구현됩니다',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ),
          // 입력 영역
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '궁금한 점을 물어보세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.send, color: AppColors.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedButton(BuildContext context, String text) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
