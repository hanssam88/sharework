import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class RegularsScreen extends StatefulWidget {
  const RegularsScreen({super.key});

  @override
  State<RegularsScreen> createState() => _RegularsScreenState();
}

class _RegularsScreenState extends State<RegularsScreen> {
  late List<RegularWorker> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(Dummy.regulars);
  }

  void _remove(RegularWorker r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('단골 해제'),
        content: Text('${r.name} 님을 단골에서 해제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _items.removeWhere(
                  (x) => x.workerId == r.workerId));
            },
            child: const Text('해제'),
          ),
        ],
      ),
    );
  }

  void _scout(RegularWorker r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${r.name}님께 스카웃을 보냈어요 (목업)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단골 워커'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: '워커 찾기',
            onPressed: () => context.push('/giver/workers'),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.people_outline,
              message: '단골로 등록된 워커가 없어요',
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.people,
                          color: AppColors.brandDark),
                      const SizedBox(width: 8),
                      Text('단골 ${_items.length}명',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const Spacer(),
                      const Text('새 공고 시 우선 추천',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final r = _items[i];
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
                                InkWell(
                                  onTap: () => context.push(
                                      '/giver/workers/${r.workerId}'),
                                  child: const CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        AppColors.brandSoft,
                                    child: Icon(Icons.person,
                                        color: AppColors.brandDark),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: Color(0xFFFFC400),
                                              size: 14),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${r.rating} · ${r.reviewCount}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets
                                                    .symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.brandSoft,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      6),
                                            ),
                                            child: Text(
                                              '${r.hireCount}회 채용',
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                  color: AppColors
                                                      .brandDark),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'remove') _remove(r);
                                    if (v == 'profile') {
                                      context.push(
                                          '/giver/workers/${r.workerId}');
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'profile',
                                        child: Text('프로필 보기')),
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Text('단골 해제',
                                          style: TextStyle(
                                              color: AppColors.danger)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (r.tags.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: r.tags
                                    .map((t) => TagChip('#$t'))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '최근 근무 ${fmtRelative(r.lastWorkedAt)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textFaint),
                                ),
                                const Spacer(),
                                FilledButton.icon(
                                  onPressed: () => _scout(r),
                                  icon: const Icon(Icons.send, size: 16),
                                  label: const Text('스카웃'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
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
    );
  }
}
