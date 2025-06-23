import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// URL 입력 폼 위젯
class UrlInputForm extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController maxReviewsController;
  final FocusNode urlFocusNode;
  final ValueChanged<String>? onUrlChanged;
  final ValueChanged<String>? onMaxReviewsChanged;
  final String? errorMessage;

  const UrlInputForm({
    super.key,
    required this.urlController,
    required this.maxReviewsController,
    required this.urlFocusNode,
    this.onUrlChanged,
    this.onMaxReviewsChanged,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // URL 입력 필드
        _buildUrlInputField(context),

        const SizedBox(height: 24),

        // 최대 리뷰 수 입력 필드
        _buildMaxReviewsField(context),
      ],
    );
  }

  Widget _buildUrlInputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '다나와 상품 URL',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: urlController,
          focusNode: urlFocusNode,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          maxLines: 1,
          onChanged: onUrlChanged,
          decoration: InputDecoration(
            hintText: AppStrings.urlInputPlaceholder,
            hintStyle: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: const Icon(Icons.link, color: AppColors.primary),
            suffixIcon:
                urlController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        urlController.clear();
                        onUrlChanged?.call('');
                      },
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(16),
            errorText: errorMessage,
            errorMaxLines: 2,
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
        ),

        const SizedBox(height: 8),

        // URL 안내 텍스트
        Text(
          AppStrings.urlInputHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildMaxReviewsField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.maxReviewsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          AppStrings.maxReviewsDescription,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            // 최대 리뷰 수 입력
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: maxReviewsController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLines: 1,
                onChanged: onMaxReviewsChanged,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  hintText: '50',
                  prefixIcon: const Icon(
                    Icons.format_list_numbered,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
              ),
            ),

            const SizedBox(width: 12),

            // 개수 단위 표시
            Text(
              '개',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),

            const SizedBox(width: 16),

            // 범위 표시
            Expanded(
              flex: 3,
              child: Text(
                '(1 ~ 200개)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 추천 버튼들
        _buildRecommendedCounts(),
      ],
    );
  }

  Widget _buildRecommendedCounts() {
    const recommendedCounts = [20, 50, 100, 200];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          recommendedCounts
              .map(
                (count) => FilterChip(
                  label: Text('$count개'),
                  selected: maxReviewsController.text == count.toString(),
                  onSelected: (selected) {
                    if (selected) {
                      maxReviewsController.text = count.toString();
                      onMaxReviewsChanged?.call(count.toString());
                    }
                  },
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceVariant,
                  side: BorderSide(
                    color:
                        maxReviewsController.text == count.toString()
                            ? AppColors.primary
                            : AppColors.outline,
                  ),
                  labelStyle: TextStyle(
                    color:
                        maxReviewsController.text == count.toString()
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                    fontWeight:
                        maxReviewsController.text == count.toString()
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              )
              .toList(),
    );
  }
}
