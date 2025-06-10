import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat/suggested_questions.dart';
import '../widgets/common/error_widget.dart';

/// AI 채팅 스크린
class ChatScreen extends StatefulWidget {
  final String productId;
  final String? productName;

  const ChatScreen({super.key, required this.productId, this.productName});

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
              // 상품 정보 표시
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.chatTitle),
          if (widget.productName != null)
            Text(
              widget.productName!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onPrimary.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      actions: [
        Consumer<ChatViewModel>(
          builder: (context, viewModel, child) {
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'clear':
                    _showClearChatDialog(context, viewModel);
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem<String>(
                      value: 'clear',
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline, color: AppColors.error),
                          SizedBox(width: 8),
                          Text(AppStrings.chatClearTitle),
                        ],
                      ),
                    ),
                  ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductHeader(ChatViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag,
              color: AppColors.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.productName!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimaryContainer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '리뷰 기반 AI 분석 상담',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.chatWelcomeTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.chatWelcomeMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ChatInputWidget(
            onSendMessage: (message) {
              viewModel.sendMessage(message);
              // 메시지 전송 후 스크롤을 맨 아래로
              Future.delayed(const Duration(milliseconds: 300), () {
                _scrollToBottom();
              });
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
            title: const Text(AppStrings.chatClearTitle),
            content: const Text(AppStrings.chatClearMessage),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () {
                  viewModel.clearChat();
                  Navigator.pop(context);
                  SuccessSnackBar.show(
                    context: context,
                    message: '채팅 기록이 삭제되었습니다',
                  );
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
    );
  }
}
