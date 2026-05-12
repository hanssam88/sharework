import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationKind? _filter;

  static const _filters = <_FilterOption>[
    _FilterOption(label: '전체', kind: null),
    _FilterOption(label: '채용', kind: NotificationKind.hire),
    _FilterOption(label: '지원', kind: NotificationKind.application),
    _FilterOption(label: '리뷰', kind: NotificationKind.review),
    _FilterOption(label: '시스템', kind: NotificationKind.system),
  ];

  @override
  Widget build(BuildContext context) {
    final all = Dummy.notifications;
    final list =
        _filter == null ? all : all.where((n) => n.kind == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('모두 읽음',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _filters.map((f) {
                  final on = _filter == f.kind;
                  final count = f.kind == null
                      ? all.length
                      : all.where((n) => n.kind == f.kind).length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('${f.label} ($count)'),
                      selected: on,
                      showCheckmark: false,
                      selectedColor: AppColors.brandDark,
                      labelStyle: TextStyle(
                        color: on ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _filter = f.kind),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_none, message: '해당 카테고리에 알림이 없어요')
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => NotificationCard(
                      noti: list[i],
                      onTap: () {
                        if (list[i].jobId != null) {
                          context.push('/job/${list[i].jobId}');
                        }
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final NotificationKind? kind;
  const _FilterOption({required this.label, required this.kind});
}
