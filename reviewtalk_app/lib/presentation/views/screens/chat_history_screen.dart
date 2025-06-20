import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/special_product_model.dart';
import '../../../data/datasources/remote/special_deals_api.dart';
import '../../viewmodels/url_input_viewmodel.dart';
import 'chat_screen.dart';

/// 채팅 기록 아이템 모델
class ChatHistoryItem {
  final String productIcon;
  final String productName;
  final String lastMessage;
  final String timeAgo;
  final int messageCount;
  final bool isFromUrl;
  final String? url;
  final SpecialProductModel? specialProduct; // 특가 상품 데이터 추가

  ChatHistoryItem({
    required this.productIcon,
    required this.productName,
    required this.lastMessage,
    required this.timeAgo,
    required this.messageCount,
    required this.isFromUrl,
    this.url,
    this.specialProduct,
  });
}

/// 채팅 히스토리 화면 - 새로운 심플한 디자인
class ChatHistoryScreen extends StatefulWidget {
  final VoidCallback? onUrlSelected;

  const ChatHistoryScreen({super.key, this.onUrlSelected});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<SpecialProductModel> _specialDeals = [];
  bool _isLoadingDeals = false;

  @override
  void initState() {
    super.initState();
    _loadSpecialDeals();
  }

  /// 특가 상품 데이터 로드
  Future<void> _loadSpecialDeals() async {
    if (!mounted) return;

    setState(() {
      _isLoadingDeals = true;
    });

    try {
      final deals = await SpecialDealsApi.getSpecialDeals(limit: 6);
      if (mounted) {
        setState(() {
          _specialDeals = deals;
          _isLoadingDeals = false;
        });
      }
    } catch (e) {
      print('특가 상품 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingDeals = false;
        });
      }
    }
  }

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
                child: Container(
                  color: Colors.grey.shade50,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
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
              ),
              _buildNewAnalysisButton(context),
            ],
          );
        },
      ),
    );
  }

  // 실제 특가 상품 데이터와 URL 기록을 조합한 채팅 목록 생성
  List<ChatHistoryItem> _buildChatList(List<String> recentUrls) {
    // 특가 상품 데이터를 채팅 아이템으로 변환
    final specialDealsChatList =
        _specialDeals.map((product) {
          return ChatHistoryItem(
            productIcon: '🏷️', // 특가 상품 아이콘
            productName: product.shortName,
            lastMessage:
                product.canChat ? '리뷰 분석 완료! 궁금한 점을 물어보세요' : '리뷰 데이터 수집 중...',
            timeAgo: _getRelativeTime(product.createdAt),
            messageCount: product.reviewCount,
            isFromUrl: false,
            specialProduct: product,
          );
        }).toList();

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

    // URL 기록 + 특가 상품 데이터 조합
    return [...urlChatList, ...specialDealsChatList];
  }

  // 상대적 시간 계산
  String _getRelativeTime(String? createdAt) {
    if (createdAt == null) return '알 수 없음';

    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(created);

      if (difference.inMinutes < 1) {
        return '방금 전';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return '1주일 전';
      }
    } catch (e) {
      return '알 수 없음';
    }
  }

  void _onChatItemTap(BuildContext context, ChatHistoryItem chatItem) {
    if (chatItem.isFromUrl && chatItem.url != null) {
      // 실제 URL 기록인 경우 - 홈 탭으로 이동
      final viewModel = Provider.of<UrlInputViewModel>(context, listen: false);
      viewModel.selectRecentUrl(chatItem.url!);
      widget.onUrlSelected?.call();
    } else if (chatItem.specialProduct != null) {
      // 특가 상품인 경우 - 채팅 화면으로 이동
      final product = chatItem.specialProduct!;
      if (product.canChat) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  productId: product.productUrl, // productId 대신 productUrl 사용
                  productName: product.productName,
                  productImage: product.imageUrl,
                  productPrice: product.price,
                ),
          ),
        );
      } else {
        // 리뷰 데이터가 준비되지 않은 경우
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.shortName}의 리뷰 데이터가 아직 준비되지 않았습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      // 기타 경우 - 채팅 화면으로 이동 (기본 처리)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => ChatScreen(
                productId: chatItem.productName,
                productName: chatItem.productName,
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
          widget.onUrlSelected?.call();
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
              '새 상품 분석하기',
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

/// 상품 카드 스타일 채팅 기록 아이템
class _ChatHistoryItem extends StatelessWidget {
  final ChatHistoryItem chatItem;
  final VoidCallback onTap;

  const _ChatHistoryItem({required this.chatItem, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final product = chatItem.specialProduct;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상품 이미지
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        product?.imageUrl != null &&
                                product!.imageUrl!.trim().isNotEmpty
                            ? Image.network(
                              'http://192.168.35.68:8000/api/v1/special-deals/image-proxy?url=${Uri.encodeComponent(product.imageUrl!)}',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 32,
                                    color: AppColors.primary.withOpacity(0.5),
                                  ),
                                );
                              },
                            )
                            : Container(
                              width: 80,
                              height: 80,
                              color: AppColors.primary.withOpacity(0.1),
                              child: Center(
                                child: Text(
                                  chatItem.productIcon,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 16),
                // 상품 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상품명
                      Text(
                        chatItem.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // 할인율 (있는 경우)
                      if (product?.discountRate != null &&
                          product!.discountRate!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.discountRate!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // 가격 정보
                      if (product?.price != null &&
                          product!.price!.isNotEmpty) ...[
                        Text(
                          product.price!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        if (product.originalPrice != null &&
                            product.originalPrice!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            product.originalPrice!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 8),

                      // 채팅 상태 정보
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '리뷰 ${chatItem.messageCount}개 분석',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 시간 정보
                      Text(
                        chatItem.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 화살표 아이콘
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
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
