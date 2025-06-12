import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../viewmodels/url_input_viewmodel.dart';

/// 설정 화면
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: Consumer<UrlInputViewModel>(
        builder: (context, viewModel, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 크롤링 설정 섹션
              _buildSectionHeader(context, '크롤링 설정'),
              _buildMaxReviewsSetting(context, viewModel),
              const SizedBox(height: 24),

              // 앱 정보 섹션
              _buildSectionHeader(context, '앱 정보'),
              _buildAppInfoTile(
                context,
                icon: Icons.info_outline,
                title: '앱 버전',
                subtitle: '1.0.0',
                onTap: () => _showAppInfoDialog(context),
              ),
              _buildAppInfoTile(
                context,
                icon: Icons.description_outlined,
                title: '오픈소스 라이선스',
                subtitle: '사용된 오픈소스 라이브러리 정보',
                onTap: () => _showLicensePage(context),
              ),
              const SizedBox(height: 24),

              // 데이터 관리 섹션
              _buildSectionHeader(context, '데이터 관리'),
              _buildAppInfoTile(
                context,
                icon: Icons.delete_outline,
                title: '검색 기록 삭제',
                subtitle: '모든 검색 기록을 삭제합니다',
                onTap: () => _showClearHistoryDialog(context, viewModel),
                isDestructive: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMaxReviewsSetting(
    BuildContext context,
    UrlInputViewModel viewModel,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '수집할 리뷰 개수',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '현재: ${viewModel.maxReviews}개',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: viewModel.maxReviews.toDouble(),
              min: 10,
              max: 1000,
              divisions: 99, // (1000-10)/10 = 99개의 구간 (10개 단위)
              label: '${viewModel.maxReviews}개',
              onChanged: (value) {
                // 10개 단위로 반올림
                final roundedValue = (value / 10).round() * 10;
                viewModel.setMaxReviews(roundedValue);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '10개',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '1000개',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '리뷰 개수가 많을수록 더 정확한 분석이 가능하지만, 크롤링 시간이 오래 걸릴 수 있습니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.primary,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDestructive ? AppColors.error : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ReviewTalk'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('버전: 1.0.0'),
                SizedBox(height: 8),
                Text('다나와 상품 리뷰를 분석하여 AI와 채팅할 수 있는 앱입니다.'),
                SizedBox(height: 8),
                Text('개발자: ReviewTalk Team'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'ReviewTalk',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 ReviewTalk Team',
    );
  }

  void _showClearHistoryDialog(
    BuildContext context,
    UrlInputViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('검색 기록 삭제'),
            content: const Text('모든 검색 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  viewModel.clearRecentUrls();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('검색 기록이 삭제되었습니다.')),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }
}
