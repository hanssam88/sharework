import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key});

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  late List<SavedSearch> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(Dummy.savedSearches);
  }

  void _toggle(int id, bool v) {
    setState(() {
      _items = _items
          .map((s) => s.id == id ? s.copyWith(pushEnabled: v) : s)
          .toList();
    });
  }

  void _remove(int id) {
    setState(() => _items.removeWhere((s) => s.id == id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장된 검색이 삭제되었어요 (목업)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('저장된 검색·알림'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/me/saved-searches/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('새로 만들기'),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off_outlined,
              message: '저장된 검색이 없어요',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final s = _items[i];
                return _SearchCard(
                  search: s,
                  onToggle: (v) => _toggle(s.id, v),
                  onRemove: () => _remove(s.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/me/saved-searches/new'),
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('알림 만들기'),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final SavedSearch search;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRemove;
  const _SearchCard({
    required this.search,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Text(search.label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Switch(
                value: search.pushEnabled,
                activeColor: AppColors.brandDark,
                onChanged: onToggle,
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'remove') onRemove();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('삭제',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (search.keyword != null && search.keyword!.isNotEmpty)
                TagChip('"${search.keyword}"'),
              ...search.categories.map((c) => TagChip(c.label)),
              if (search.minHourly != null)
                TagChip('${fmtMoney(search.minHourly!)}↑'),
              if (search.radiusKm != null)
                TagChip('반경 ${search.radiusKm!.toStringAsFixed(0)}km'),
              if (search.sameDayOnly) const TagChip('당일지급'),
              if (search.nightOk) const TagChip('야간 가능'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            search.pushEnabled
                ? '새 공고가 등록되면 푸시 알림으로 알려드려요'
                : '알림이 일시정지되었어요',
            style: TextStyle(
              fontSize: 11,
              color: search.pushEnabled
                  ? AppColors.brandDark
                  : AppColors.textFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
