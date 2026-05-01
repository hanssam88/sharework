import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class WorkersSearchScreen extends StatefulWidget {
  const WorkersSearchScreen({super.key});

  @override
  State<WorkersSearchScreen> createState() => _WorkersSearchScreenState();
}

class _WorkersSearchScreenState extends State<WorkersSearchScreen> {
  String _keyword = '';
  final Set<String> _tagFilters = {};
  bool _verifiedOnly = false;
  double _minRating = 4.0;

  static const _allTags = [
    '시간엄수',
    '친절함',
    '성실함',
    '책임감',
    '바리스타',
    '서빙경험',
    '체력좋음',
    '꼼꼼함',
  ];

  List<AppUser> get _filtered {
    var items = Dummy.workers.where((u) => u.appType == AppType.worker).toList();
    if (_keyword.isNotEmpty) {
      items = items
          .where((u) =>
              u.name.contains(_keyword) ||
              u.tags.any((t) => t.contains(_keyword)) ||
              u.introduction.contains(_keyword))
          .toList();
    }
    if (_tagFilters.isNotEmpty) {
      items = items
          .where((u) => _tagFilters.every((t) => u.tags.contains(t)))
          .toList();
    }
    if (_verifiedOnly) {
      items = items.where((u) => u.identityVerified).toList();
    }
    items = items.where((u) => u.rating >= _minRating).toList();
    items.sort((a, b) => b.rating.compareTo(a.rating));
    return items;
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('워커 필터',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                const Text('태그',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allTags.map((t) {
                    final on = _tagFilters.contains(t);
                    return FilterChip(
                      label: Text('#$t'),
                      selected: on,
                      onSelected: (v) {
                        setSheet(() {
                          if (v) {
                            _tagFilters.add(t);
                          } else {
                            _tagFilters.remove(t);
                          }
                        });
                      },
                      selectedColor: AppColors.brandSoft,
                      checkmarkColor: AppColors.brandDark,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('최소 평점: ${_minRating.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  activeColor: AppColors.brandDark,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (v) => setSheet(() => _minRating = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _verifiedOnly,
                  onChanged: (v) => setSheet(() => _verifiedOnly = v),
                  title: const Text('본인인증 완료자만'),
                  activeColor: AppColors.brandDark,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setSheet(() {
                            _tagFilters.clear();
                            _minRating = 4.0;
                            _verifiedOnly = false;
                          });
                        },
                        child: const Text('초기화'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        child: const Text('적용'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final filterCount =
        _tagFilters.length + (_verifiedOnly ? 1 : 0) + (_minRating > 4.0 ? 1 : 0);
    return Scaffold(
      appBar: AppBar(title: const Text('워커 찾기')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '이름·태그·소개로 검색',
                      prefixIcon: Icon(Icons.search,
                          color: AppColors.textMuted),
                    ),
                    onChanged: (v) => setState(() => _keyword = v),
                  ),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  count: filterCount,
                  onTap: _openFilter,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.person_search,
                    message: '조건에 맞는 워커가 없어요',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _WorkerCard(u: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = count > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: on ? AppColors.brandSoft : AppColors.chipBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.tune,
                size: 16,
                color: on ? AppColors.brandDark : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              on ? '필터 $count' : '필터',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on ? AppColors.brandDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final AppUser u;
  const _WorkerCard({required this.u});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/giver/workers/${u.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.brandSoft,
                  child:
                      Icon(Icons.person, color: AppColors.brandDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(u.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          if (u.identityVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                size: 16, color: AppColors.brandDark),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFC400), size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${u.rating} · 리뷰 ${u.reviewCount}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => context.push('/giver/workers/${u.id}'),
                  child: const Text('스카웃'),
                ),
              ],
            ),
            if (u.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    u.tags.map((t) => TagChip('#$t')).toList(),
              ),
            ],
            if (u.introduction.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                u.introduction,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
