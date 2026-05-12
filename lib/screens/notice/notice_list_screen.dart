import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class NoticeListScreen extends StatelessWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [...Dummy.notices]..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.campaign_outlined,
              message: '공지가 없어요',
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final n = items[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: n.pinned ? AppColors.brandSoft : AppColors.chipBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      n.pinned ? Icons.push_pin : Icons.campaign_outlined,
                      color:
                          n.pinned ? AppColors.brandDark : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    n.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    fmtRelative(n.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textFaint),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textFaint),
                  onTap: () => context.push('/notice/${n.id}'),
                );
              },
            ),
    );
  }
}
