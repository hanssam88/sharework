import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class MyPageScreen extends StatelessWidget {
  final String appType; // 'worker' or 'giver'
  const MyPageScreen({super.key, required this.appType});

  @override
  Widget build(BuildContext context) {
    final me = Dummy.me;
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // profile card
          InkWell(
            onTap: () => context.push('/profile/${me.id}'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.brandSoft,
                    child: Icon(Icons.person,
                        size: 36, color: AppColors.brandDark),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFFFC400), size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${me.rating} · 리뷰 ${me.reviewCount}개',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            appType == 'worker' ? '구직자 모드' : '구인자 모드',
                            style: const TextStyle(
                              color: AppColors.brandDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textFaint),
                ],
              ),
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '계정'),
          _Tile(icon: Icons.edit, label: '내 프로필 수정', onTap: () => context.push('/me/edit')),
          _Tile(
            icon: Icons.swap_horiz,
            label: appType == 'worker' ? '구인자 모드로 전환' : '구직자 모드로 전환',
            onTap: () =>
                context.go(appType == 'worker' ? '/giver' : '/worker'),
          ),
          _Tile(
            icon: Icons.notifications_outlined,
            label: '알림 설정',
            onTap: () => context.push('/me/notification-settings'),
          ),
          _Tile(
            icon: Icons.block,
            label: '차단 목록',
            onTap: () => context.push('/me/blocklist'),
          ),
          _Tile(icon: Icons.logout, label: '로그아웃', onTap: () => context.go('/auth/phone')),
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '활동'),
          if (appType == 'worker') ...[
            _Tile(icon: Icons.bookmark_border, label: '즐겨찾는 업체', onTap: () {}),
            _Tile(
              icon: Icons.account_balance_wallet_outlined,
              label: '정산 내역',
              onTap: () => context.push('/me/payments'),
            ),
          ] else ...[
            _Tile(icon: Icons.list_alt, label: '내 공고 관리', onTap: () {}),
            _Tile(
              icon: Icons.account_balance_wallet_outlined,
              label: '지급 내역',
              onTap: () => context.push('/me/payments'),
            ),
          ],
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '고객센터'),
          _Tile(
            icon: Icons.headset_mic_outlined,
            label: '고객센터 / 1:1 문의',
            onTap: () => context.push('/support'),
          ),
          _Tile(
            icon: Icons.help_outline,
            label: '자주 묻는 질문',
            onTap: () => context.push('/support/faq'),
          ),
          _Tile(
            icon: Icons.book_outlined,
            label: '이용가이드',
            onTap: () => context.push('/guide'),
          ),
          _Tile(
            icon: Icons.gavel_outlined,
            label: '이용약관',
            onTap: () => context.push('/terms'),
          ),
          _Tile(
            icon: Icons.privacy_tip_outlined,
            label: '개인정보 처리방침',
            onTap: () => context.push('/privacy'),
          ),
          _Tile(
            icon: Icons.campaign_outlined,
            label: '공지사항',
            onTap: () => context.push('/notice'),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Sharework v0.1.0 (mockup)',
              style: TextStyle(color: AppColors.textFaint, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textFaint),
      onTap: onTap,
    );
  }
}
