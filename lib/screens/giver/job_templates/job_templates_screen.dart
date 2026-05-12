import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class JobTemplatesScreen extends StatelessWidget {
  const JobTemplatesScreen({super.key});

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  String _recurrenceLabel(List<int> days) {
    if (days.isEmpty) return '1회성';
    final sorted = [...days]..sort();
    return '매주 ${sorted.map((d) => _weekdayLabels[d - 1]).join('·')}';
  }

  @override
  Widget build(BuildContext context) {
    final items = [...Dummy.jobTemplates]
      ..sort((a, b) => b.useCount.compareTo(a.useCount));
    return Scaffold(
      appBar: AppBar(title: const Text('공고 템플릿')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.dashboard_customize_outlined,
              message: '저장된 템플릿이 없어요',
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: const [
                      Icon(Icons.dashboard_customize,
                          color: AppColors.brandDark),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '자주 올리는 공고를 템플릿으로 저장해 한 번에 등록하세요.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = items[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t.category.label,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brandDark),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (t.useCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.chipBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '사용 ${t.useCount}회',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMuted),
                                    ),
                                  ),
                                const Spacer(),
                                PopupMenuButton<String>(
                                  iconSize: 18,
                                  onSelected: (v) {
                                    if (v == 'remove') {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('템플릿 삭제 (목업)')),
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Text('삭제',
                                          style: TextStyle(
                                              color: AppColors.danger)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(t.name,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(t.title,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textMuted)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _meta(Icons.payments_outlined,
                                    '${fmtMoney(t.payHourly)}/시간'),
                                _meta(Icons.people_outline,
                                    '${t.defaultPersonnel}명'),
                                _meta(Icons.repeat,
                                    _recurrenceLabel(t.recurrenceWeekdays)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('템플릿 편집 (목업)')),
                                      );
                                    },
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('편집'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop(t);
                                      context.push(
                                          '/giver/job/create?templateId=${t.id}');
                                    },
                                    icon: const Icon(Icons.add_box_outlined,
                                        size: 16),
                                    label: const Text('이 템플릿으로 등록'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('새 템플릿 만들기 (목업)')),
          );
        },
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('템플릿 만들기'),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(text,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
