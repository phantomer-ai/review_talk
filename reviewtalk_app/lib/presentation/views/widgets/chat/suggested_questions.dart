import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// 추천 질문 버튼들을 표시하는 위젯
class SuggestedQuestions extends StatelessWidget {
  final List<String> questions;
  final ValueChanged<String>? onQuestionSelected;
  final bool isLoading;

  const SuggestedQuestions({
    super.key,
    required this.questions,
    this.onQuestionSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                AppStrings.suggestedQuestionsTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 질문 버튼들 (가로 스크롤)
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: questions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final question = questions[index];
              return _QuestionChip(
                question: question,
                onTap:
                    isLoading ? null : () => onQuestionSelected?.call(question),
                isEnabled: !isLoading,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 개별 질문 칩 위젯
class _QuestionChip extends StatelessWidget {
  final String question;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _QuestionChip({
    required this.question,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isEnabled
                    ? AppColors.primaryContainer
                    : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEnabled ? AppColors.primary : AppColors.outline,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 질문 아이콘
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color:
                    isEnabled ? AppColors.primary : AppColors.onSurfaceVariant,
              ),

              const SizedBox(width: 6),

              // 질문 텍스트
              Text(
                question,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isEnabled
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 기본 추천 질문들을 제공하는 위젯
class DefaultSuggestedQuestions extends StatelessWidget {
  final ValueChanged<String>? onQuestionSelected;
  final bool isLoading;

  const DefaultSuggestedQuestions({
    super.key,
    this.onQuestionSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SuggestedQuestions(
      questions: AppStrings.suggestedQuestions,
      onQuestionSelected: onQuestionSelected,
      isLoading: isLoading,
    );
  }
}

/// 컴팩트한 추천 질문 그리드 (세로 방향)
class CompactSuggestedQuestions extends StatelessWidget {
  final List<String> questions;
  final ValueChanged<String>? onQuestionSelected;
  final bool isLoading;
  final int maxVisible;

  const CompactSuggestedQuestions({
    super.key,
    required this.questions,
    this.onQuestionSelected,
    this.isLoading = false,
    this.maxVisible = 4,
  });

  @override
  Widget build(BuildContext context) {
    final visibleQuestions = questions.take(maxVisible).toList();

    if (visibleQuestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Row(
            children: [
              Icon(Icons.help_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '이런 것들을 물어보세요!',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 질문 그리드
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                visibleQuestions
                    .map(
                      (question) => _CompactQuestionButton(
                        question: question,
                        onTap:
                            isLoading
                                ? null
                                : () => onQuestionSelected?.call(question),
                        isEnabled: !isLoading,
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

/// 컴팩트한 질문 버튼
class _CompactQuestionButton extends StatelessWidget {
  final String question;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _CompactQuestionButton({
    required this.question,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.surface : AppColors.disabled,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled ? AppColors.outline : AppColors.disabled,
            ),
          ),
          child: Text(
            question,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  isEnabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
