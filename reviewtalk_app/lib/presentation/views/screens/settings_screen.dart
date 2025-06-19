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
        title: const Text('설정 탭'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: Consumer<UrlInputViewModel>(
        builder: (context, viewModel, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 📊 이용 통계 섹션
              _buildSectionHeader(context, '📊 이용 통계'),
              _buildUsageStats(context, viewModel),
              const SizedBox(height: 24),

              // ⚙️ 설정 섹션
              _buildSectionHeader(context, '⚙️ 설정'),
              _buildSettingsTiles(context),
              const SizedBox(height: 24),

              // 📋 최근 분석 기록 섹션
              _buildSectionHeader(context, '📋 최근 분석 기록'),
              _buildRecentAnalysis(context, viewModel),
              const SizedBox(height: 24),

              // ℹ️ 앱 정보 섹션
              _buildSectionHeader(context, 'ℹ️ 앱 정보'),
              _buildAppInfo(context),
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

  Widget _buildUsageStats(BuildContext context, UrlInputViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${viewModel.recentUrls.length}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '분석한 상품',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.outline.withOpacity(0.3),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '156', // 더미 데이터
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '질문한 횟수',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTiles(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildSettingTile(
          context,
          icon: Icons.notifications_outlined,
          title: '알림 설정',
          trailing: Switch(
            value: true, // 더미 값
            onChanged: (value) {
              // TODO: 알림 설정 구현
            },
          ),
        ),
        _buildSettingTile(
          context,
          icon: Icons.dark_mode_outlined,
          title: '다크 모드',
          trailing: Switch(
            value: false, // 더미 값
            onChanged: (value) {
              // TODO: 다크 모드 구현
            },
          ),
        ),
        _buildSettingTile(
          context,
          icon: Icons.system_update_outlined,
          title: '자동 업데이트',
          trailing: Switch(
            value: true, // 더미 값
            onChanged: (value) {
              // TODO: 자동 업데이트 설정 구현
            },
          ),
        ),
        _buildAppInfoTile(
          context,
          icon: Icons.delete_outline,
          title: '캐시 삭제',
          subtitle: '앱 데이터를 정리합니다',
          onTap:
              () => _showClearHistoryDialog(
                context,
                context.read<UrlInputViewModel>(),
              ),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: trailing,
      ),
    );
  }

  Widget _buildRecentAnalysis(
    BuildContext context,
    UrlInputViewModel viewModel,
  ) {
    if (viewModel.recentUrls.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: AppColors.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                '분석 기록이 없습니다',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ...viewModel.recentUrls.take(4).map((url) {
            final index = viewModel.recentUrls.indexOf(url);
            final productCode = _extractProductCode(url);
            final title =
                productCode != null ? '상품 $productCode' : '분석 ${index + 1}';
            final timeAgo = _getTimeAgo(index); // 더미 시간 데이터

            return ListTile(
              leading: Icon(Icons.analytics, color: AppColors.primary),
              title: Text(title),
              subtitle: Text(timeAgo),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 해당 채팅으로 이동 구현
              },
            );
          }),
          if (viewModel.recentUrls.length > 4)
            ListTile(
              title: const Text(
                '더 보기',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.primary),
              ),
              onTap: () {
                // TODO: 전체 기록 보기 구현
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Column(
      children: [
        _buildAppInfoTile(
          context,
          icon: Icons.info_outline,
          title: '앱 버전',
          subtitle: 'v1.0.0',
          onTap: () => _showAppInfoDialog(context),
        ),
        _buildAppInfoTile(
          context,
          icon: Icons.people_outline,
          title: '개발자',
          subtitle: '오히려좋아팀',
          onTap: () => _showAppInfoDialog(context),
        ),
        _buildAppInfoTile(
          context,
          icon: Icons.contact_support_outlined,
          title: '문의하기',
          subtitle: '문제 신고 및 의견 보내기',
          onTap: () => _showContactDialog(context),
        ),
        _buildAppInfoTile(
          context,
          icon: Icons.star_outline,
          title: '리뷰 남기기',
          subtitle: '앱스토어에서 평가하기',
          onTap: () => _showReviewDialog(context),
        ),
      ],
    );
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

  String _getTimeAgo(int index) {
    // 더미 시간 데이터
    const timeTexts = ['2일 전', '3일 전', '5일 전', '1주일 전'];
    return timeTexts[index % timeTexts.length];
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('문의하기'),
            content: const Text(
              '문의사항이 있으시면 이메일로 연락해주세요.\n\nreviewtalk@example.com',
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

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('리뷰 남기기'),
            content: const Text('앱스토어에서 리뷰를 남겨주시면 앱 개선에 큰 도움이 됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: 앱스토어 리뷰 페이지로 이동
                },
                child: const Text('평가하기'),
              ),
            ],
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
