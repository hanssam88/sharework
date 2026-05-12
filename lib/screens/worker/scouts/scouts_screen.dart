import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class ScoutsScreen extends StatelessWidget {
  const ScoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scouts = [...Dummy.scouts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(title: const Text('스카우트 제안')),
      body: scouts.isEmpty
          ? const EmptyState(
              icon: Icons.mark_email_unread_outlined,
              message: '받은 스카우트 제안이 없어요',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: scouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final s = scouts[i];
                return _ScoutCard(
                  scout: s,
                  onTap: () => context.push('/worker/scouts/${s.id}'),
                );
              },
            ),
    );
  }
}

class _ScoutCard extends StatelessWidget {
  final Scout scout;
  final VoidCallback onTap;
  const _ScoutCard({required this.scout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.brandSoft,
                    child: Icon(Icons.business,
                        size: 18, color: AppColors.brandDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scout.fromGiverName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(fmtRelative(scout.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textFaint)),
                      ],
                    ),
                  ),
                  _StatusBadge(status: scout.status),
                ],
              ),
              const SizedBox(height: 10),
              if (scout.jobTitle != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.chipBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.work_outline,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          scout.jobTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                scout.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              if (scout.offerHourly != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 16, color: AppColors.brandDark),
                    const SizedBox(width: 4),
                    Text(
                      '제안 시급 ${fmtMoney(scout.offerHourly!)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandDark),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ScoutStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late String text;
    late Color bg;
    late Color fg;
    switch (status) {
      case ScoutStatus.sent:
        text = '신규';
        bg = const Color(0xFFEEF4FF);
        fg = const Color(0xFF2F66E2);
        break;
      case ScoutStatus.accepted:
        text = '수락';
        bg = AppColors.brandSoft;
        fg = AppColors.brandDark;
        break;
      case ScoutStatus.declined:
        text = '거절';
        bg = const Color(0xFFFDECEC);
        fg = AppColors.danger;
        break;
      case ScoutStatus.expired:
        text = '만료';
        bg = AppColors.chipBg;
        fg = AppColors.textMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
