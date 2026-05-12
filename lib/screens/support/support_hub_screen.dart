import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class SupportHubScreen extends StatelessWidget {
  const SupportHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('고객센터')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.headset_mic_outlined,
                    size: 36, color: AppColors.brandDark),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('무엇을 도와드릴까요?',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text(
                        '평일 09:00 ~ 18:00 · 신고센터 매일 08:00 ~ 22:00',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.help_outline,
                  label: '자주 묻는 질문',
                  desc: 'FAQ',
                  onTap: () => context.push('/support/faq'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionCard(
                  icon: Icons.chat_outlined,
                  label: '1:1 문의',
                  desc: '고객센터에 직접 문의',
                  onTap: () => context.push('/support/inquiry'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.flag_outlined,
                  label: '신고센터',
                  desc: '부적절한 사용자 신고',
                  onTap: () => context.push('/report/user/0'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionCard(
                  icon: Icons.gavel_outlined,
                  label: '분쟁 조정',
                  desc: '정산·근무 분쟁 중재',
                  onTap: () => context.push('/support/dispute'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.campaign_outlined,
                  label: '공지사항',
                  desc: '최신 공지/업데이트',
                  onTap: () => context.push('/notice'),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text('이용가이드'),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textFaint),
            onTap: () => context.push('/guide'),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('이용약관'),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textFaint),
            onTap: () => context.push('/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보 처리방침'),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textFaint),
            onTap: () => context.push('/privacy'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.brandDark, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
