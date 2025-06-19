import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat/suggested_questions.dart';
import '../widgets/common/error_widget.dart';

/// AI 채팅 스크린 - 새로운 깔끔한 디자인
class ChatScreen extends StatefulWidget {
  final String productId;
  final String? productName;
  final String? productImage;
  final String? productPrice;

  const ChatScreen({
    super.key,
    required this.productId,
    this.productName,
    this.productImage,
    this.productPrice,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 채팅 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ChatViewModel>();
      viewModel.initializeChat(
        productId: widget.productId,
        productName: widget.productName ?? '상품',
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          // 에러 상태 처리
          if (viewModel.hasError) {
            return CustomErrorWidget.general(
              message: viewModel.errorMessage,
              onRetry: () => viewModel.clearError(),
            );
          }

          return Column(
            children: [
              // 상품 정보 표시 (간소화)
              if (viewModel.productName != null) _buildProductHeader(viewModel),

              // 채팅 메시지 영역
              Expanded(
                child: Column(
                  children: [
                    // 추천 질문 (메시지가 적을 때만 표시)
                    if (viewModel.messages.length <= 1) ...[
                      const SizedBox(height: 16),
                      DefaultSuggestedQuestions(
                        onQuestionSelected: (question) {
                          viewModel.selectSuggestedQuestion(question);
                          _scrollToBottom();
                        },
                        isLoading: viewModel.isLoading,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 환영 메시지 또는 채팅 메시지 목록
                    Expanded(
                      child:
                          viewModel.messages.isEmpty
                              ? _buildWelcomeMessage()
                              : _buildMessageList(viewModel),
                    ),
                  ],
                ),
              ),

              // 채팅 입력 위젯
              _buildChatInput(viewModel),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'chat',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      centerTitle: false,
      actions: [
        Consumer<ChatViewModel>(
          builder: (context, viewModel, child) {
            return IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {
                _showClearChatDialog(context, viewModel);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductHeader(ChatViewModel viewModel) {
    print('🔍 채팅 화면 상품 정보:');
    print('  - 상품명: ${viewModel.productName}');
    print('  - 이미지 URL: ${widget.productImage}');
    print('  - 가격: ${widget.productPrice}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 상품 이미지
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  widget.productImage != null &&
                          widget.productImage!.trim().isNotEmpty
                      ? Image.network(
                        'http://192.168.35.68:8000/api/v1/special-deals/image-proxy?url=${Uri.encodeComponent(widget.productImage!)}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            print('✅ 채팅 상품 이미지 로딩 성공: ${widget.productImage}');
                            return child;
                          }
                          print('⏳ 채팅 상품 이미지 로딩 중: ${widget.productImage}');
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ 채팅 상품 이미지 로딩 실패: ${widget.productImage}');
                          print('❌ 오류: $error');
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.broken_image,
                              size: 24,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      )
                      : Container(
                        width: 60,
                        height: 60,
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.shopping_bag,
                          size: 24,
                          color: AppColors.primary,
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
                Text(
                  viewModel.productName!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.productPrice != null &&
                    widget.productPrice!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.productPrice!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              '안녕하세요! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '상품에 대해 궁금한 것을 물어보세요.\n리뷰를 바탕으로 답변해드릴게요!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatViewModel viewModel) {
    // 메시지 변화 감지 시 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: viewModel.messages.length,
      itemBuilder: (context, index) {
        final message = viewModel.messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ChatMessageWidget(message: message),
        );
      },
    );
  }

  Widget _buildChatInput(ChatViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline.withOpacity(0.2), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ChatInputWidget(
            onSendMessage: (message) async {
              await viewModel.sendMessage(message);
              _scrollToBottom();
            },
            isLoading: viewModel.isLoading,
          ),
        ),
      ),
    );
  }

  void _showClearChatDialog(BuildContext context, ChatViewModel viewModel) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('채팅 기록 삭제'),
            content: const Text('모든 채팅 기록을 삭제하시겠습니까?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  viewModel.clearChat();
                  Navigator.pop(context);
                },
                child: Text('삭제', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
    );
  }
}
