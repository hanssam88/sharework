import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

enum _Sort { recent, payDesc, distance }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _keyword = '';
  final Set<JobCategory> _categories = {};
  final Set<WorkType> _workTypes = {};
  RangeValues _payRange = const RangeValues(10000, 30000);
  _Sort _sort = _Sort.recent;
  bool _sameDayOnly = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Job> get _results {
    var items = Dummy.jobs.where((j) => j.status == JobStatus.open).toList();
    if (_keyword.isNotEmpty) {
      items = items
          .where((j) =>
              j.title.contains(_keyword) ||
              j.address.contains(_keyword) ||
              j.tags.any((t) => t.contains(_keyword)))
          .toList();
    }
    if (_categories.isNotEmpty) {
      items = items.where((j) => _categories.contains(j.category)).toList();
    }
    if (_workTypes.isNotEmpty) {
      items = items.where((j) => _workTypes.contains(j.workType)).toList();
    }
    items = items
        .where((j) => j.pay >= _payRange.start && j.pay <= _payRange.end)
        .toList();
    if (_sameDayOnly) {
      items = items.where((j) => j.sameDayPayment).toList();
    }
    switch (_sort) {
      case _Sort.recent:
        items.sort((a, b) => a.startAt.compareTo(b.startAt));
        break;
      case _Sort.payDesc:
        items.sort((a, b) => b.pay.compareTo(a.pay));
        break;
      case _Sort.distance:
        // 목업: 거리 데이터 없음 → id 기준 임의 정렬
        items.sort((a, b) => a.id.compareTo(b.id));
        break;
    }
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
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('상세 필터',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                const Text('카테고리',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: JobCategory.values.map((c) {
                    final on = _categories.contains(c);
                    return FilterChip(
                      label: Text(c.label),
                      selected: on,
                      onSelected: (v) {
                        setSheet(() {
                          if (v) {
                            _categories.add(c);
                          } else {
                            _categories.remove(c);
                          }
                        });
                      },
                      selectedColor: AppColors.brandSoft,
                      checkmarkColor: AppColors.brandDark,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('근무 유형',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WorkType.values.map((w) {
                    final on = _workTypes.contains(w);
                    return FilterChip(
                      label: Text(w.label),
                      selected: on,
                      onSelected: (v) {
                        setSheet(() {
                          if (v) {
                            _workTypes.add(w);
                          } else {
                            _workTypes.remove(w);
                          }
                        });
                      },
                      selectedColor: AppColors.brandSoft,
                      checkmarkColor: AppColors.brandDark,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  '시급/일급 범위  ${fmtMoney(_payRange.start.round())} ~ ${fmtMoney(_payRange.end.round())}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                RangeSlider(
                  values: _payRange,
                  min: 10000,
                  max: 200000,
                  divisions: 38,
                  activeColor: AppColors.brandDark,
                  labels: RangeLabels(
                    fmtMoney(_payRange.start.round()),
                    fmtMoney(_payRange.end.round()),
                  ),
                  onChanged: (v) => setSheet(() => _payRange = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _sameDayOnly,
                  onChanged: (v) => setSheet(() => _sameDayOnly = v),
                  title: const Text('당일지급만 보기'),
                  activeColor: AppColors.brandDark,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setSheet(() {
                            _categories.clear();
                            _workTypes.clear();
                            _payRange = const RangeValues(10000, 30000);
                            _sameDayOnly = false;
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
    final results = _results;
    final filterCount = _categories.length +
        _workTypes.length +
        (_sameDayOnly ? 1 : 0);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '동·역·업종으로 검색',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            fillColor: Colors.transparent,
          ),
          onChanged: (v) => setState(() => _keyword = v),
        ),
        actions: [
          if (_keyword.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                setState(() => _keyword = '');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _FilterButton(
                  label: filterCount > 0 ? '필터 $filterCount' : '필터',
                  active: filterCount > 0,
                  onTap: _openFilter,
                  leading: Icons.tune,
                ),
                const SizedBox(width: 6),
                _SortDropdown(
                  value: _sort,
                  onChanged: (v) => setState(() => _sort = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    message: '조건에 맞는 공고가 없어요',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final j = results[i];
                      return JobCard(
                        job: j,
                        onTap: () => context.push('/job/${j.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData leading;
  const _FilterButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.brandSoft : AppColors.chipBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(leading,
                size: 16,
                color: active ? AppColors.brandDark : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.brandDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final _Sort value;
  final ValueChanged<_Sort> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  String _label(_Sort s) {
    switch (s) {
      case _Sort.recent:
        return '최신순';
      case _Sort.payDesc:
        return '시급 높은순';
      case _Sort.distance:
        return '가까운순';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_Sort>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.expand_more,
              size: 16, color: AppColors.textMuted),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
          dropdownColor: Colors.white,
          items: _Sort.values
              .map((s) => DropdownMenuItem(value: s, child: Text(_label(s))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
