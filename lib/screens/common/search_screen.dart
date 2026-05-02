import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

enum _Sort { recent, payDesc, distance }

enum _DateFilter { any, today, tomorrow, thisWeek, thisMonth }

extension _DateFilterX on _DateFilter {
  String get label {
    switch (this) {
      case _DateFilter.any:
        return '전체';
      case _DateFilter.today:
        return '오늘';
      case _DateFilter.tomorrow:
        return '내일';
      case _DateFilter.thisWeek:
        return '이번 주';
      case _DateFilter.thisMonth:
        return '이번 달';
    }
  }
}

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
  _DateFilter _dateFilter = _DateFilter.any;
  double _radiusKm = 10;

  // 최근 검색어 / 본 공고 (목업: 상태로만)
  final List<String> _recentSearches = ['카페', '잠실 행사', '주말 알바', '강남'];
  final List<int> _recentViewed = [1001, 1002, 1003];

  static const _popular = [
    '주말 알바',
    '카페',
    '단기',
    '식사제공',
    '당일지급',
    '행사',
    '마트',
    '야간',
  ];

  static const _suggestions = [
    '강남구 카페',
    '카페 알바',
    '잠실 행사 스태프',
    '주말 8시간',
    '평일 저녁',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matchDateFilter(Job j) {
    final now = DateTime.now();
    switch (_dateFilter) {
      case _DateFilter.any:
        return true;
      case _DateFilter.today:
        return j.startAt.year == now.year &&
            j.startAt.month == now.month &&
            j.startAt.day == now.day;
      case _DateFilter.tomorrow:
        final t = now.add(const Duration(days: 1));
        return j.startAt.year == t.year &&
            j.startAt.month == t.month &&
            j.startAt.day == t.day;
      case _DateFilter.thisWeek:
        return j.startAt.difference(now).inDays.abs() <= 7;
      case _DateFilter.thisMonth:
        return j.startAt.year == now.year && j.startAt.month == now.month;
    }
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
    items = items.where(_matchDateFilter).toList();

    switch (_sort) {
      case _Sort.recent:
        items.sort((a, b) => a.startAt.compareTo(b.startAt));
        break;
      case _Sort.payDesc:
        items.sort((a, b) => b.pay.compareTo(a.pay));
        break;
      case _Sort.distance:
        items.sort((a, b) => a.id.compareTo(b.id));
        break;
    }
    return items;
  }

  void _runSearch(String kw) {
    _controller.text = kw;
    setState(() {
      _keyword = kw;
      if (kw.isNotEmpty && !_recentSearches.contains(kw)) {
        _recentSearches.insert(0, kw);
        if (_recentSearches.length > 8) _recentSearches.removeLast();
      }
    });
  }

  int get _filterCount =>
      _categories.length +
      _workTypes.length +
      (_sameDayOnly ? 1 : 0) +
      (_dateFilter == _DateFilter.any ? 0 : 1);

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
                const Text('근무 시작',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _DateFilter.values.map((d) {
                    final on = _dateFilter == d;
                    return ChoiceChip(
                      label: Text(d.label),
                      selected: on,
                      showCheckmark: false,
                      selectedColor: AppColors.brandDark,
                      labelStyle: TextStyle(
                        color: on ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setSheet(() => _dateFilter = d),
                    );
                  }).toList(),
                ),
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
                const SizedBox(height: 8),
                Text('반경 ${_radiusKm.toStringAsFixed(0)}km',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: AppColors.brandDark,
                  label: '${_radiusKm.toStringAsFixed(0)}km',
                  onChanged: (v) => setSheet(() => _radiusKm = v),
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
                            _dateFilter = _DateFilter.any;
                            _radiusKm = 10;
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

  Widget _activeFiltersBar() {
    final chips = <Widget>[];

    if (_dateFilter != _DateFilter.any) {
      chips.add(_filterChip(_dateFilter.label, () {
        setState(() => _dateFilter = _DateFilter.any);
      }));
    }
    for (final c in _categories) {
      chips.add(_filterChip(c.label, () {
        setState(() => _categories.remove(c));
      }));
    }
    for (final w in _workTypes) {
      chips.add(_filterChip(w.label, () {
        setState(() => _workTypes.remove(w));
      }));
    }
    if (_sameDayOnly) {
      chips.add(_filterChip('당일지급', () {
        setState(() => _sameDayOnly = false);
      }));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    chips.add(GestureDetector(
      onTap: () {
        setState(() {
          _categories.clear();
          _workTypes.clear();
          _sameDayOnly = false;
          _dateFilter = _DateFilter.any;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          '전체 해제',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.danger.withOpacity(0.8),
          ),
        ),
      ),
    ));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .map((c) =>
                  Padding(padding: const EdgeInsets.only(right: 6), child: c))
              .toList(),
        ),
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandDark)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 14, color: AppColors.brandDark),
          ),
        ],
      ),
    );
  }

  Widget _emptyKeywordView() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 추천 검색어 / 인기 키워드
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.trending_up,
                      size: 18, color: AppColors.brandDark),
                  SizedBox(width: 4),
                  Text('인기 검색어',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _popular.asMap().entries.map((e) {
                  return ActionChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${e.key + 1}.',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandDark)),
                        const SizedBox(width: 4),
                        Text(e.value,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    onPressed: () => _runSearch(e.value),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        // 최근 검색어
        if (_recentSearches.isNotEmpty)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    const Text('최근 검색',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          setState(() => _recentSearches.clear()),
                      child: const Text('모두 지우기',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _recentSearches
                      .map((kw) => InputChip(
                            label: Text(kw,
                                style: const TextStyle(fontSize: 12)),
                            onPressed: () => _runSearch(kw),
                            onDeleted: () =>
                                setState(() => _recentSearches.remove(kw)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

        // 최근 본 공고
        if (_recentViewed.isNotEmpty) ...[
          const Divider(height: 8, thickness: 8, color: AppColors.bg),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: const [
                Icon(Icons.visibility_outlined,
                    size: 18, color: AppColors.textMuted),
                SizedBox(width: 4),
                Text('최근 본 공고',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentViewed.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final j = Dummy.jobById(_recentViewed[i]);
                return SizedBox(
                  width: 240,
                  child: JobCard(
                    job: j,
                    onTap: () => context.push('/job/${j.id}'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 카테고리 진입
        const Divider(height: 8, thickness: 8, color: AppColors.bg),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text('카테고리로 둘러보기',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/categories'),
                child: const Text('전체 보기'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: JobCategory.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = JobCategory.values[i];
              return ActionChip(
                label: Text(c.label),
                onPressed: () => context.push('/categories/${c.name}'),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _suggestionView() {
    final filtered = _suggestions
        .where((s) => s.contains(_keyword))
        .take(5)
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      child: Column(
        children: filtered
            .map((s) => InkWell(
                  onTap: () => _runSearch(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            size: 16, color: AppColors.textFaint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.text),
                              children: _highlight(s, _keyword),
                            ),
                          ),
                        ),
                        const Icon(Icons.north_west,
                            size: 14, color: AppColors.textFaint),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  List<TextSpan> _highlight(String text, String kw) {
    if (kw.isEmpty) return [TextSpan(text: text)];
    final idx = text.indexOf(kw);
    if (idx < 0) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, idx)),
      TextSpan(
          text: text.substring(idx, idx + kw.length),
          style: const TextStyle(
              color: AppColors.brandDark, fontWeight: FontWeight.w800)),
      TextSpan(text: text.substring(idx + kw.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final showEmpty = _keyword.isEmpty;

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
          onSubmitted: _runSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: '이 검색 알림으로 저장',
            onPressed: () => context.push('/me/saved-searches/new'),
          ),
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
      body: showEmpty
          ? _emptyKeywordView()
          : Column(
              children: [
                // 자동완성 (검색 중)
                if (_keyword.isNotEmpty &&
                    !_recentSearches.contains(_keyword) &&
                    results.isEmpty)
                  _suggestionView(),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _FilterButton(
                        label: _filterCount > 0
                            ? '필터 $_filterCount'
                            : '필터',
                        active: _filterCount > 0,
                        onTap: _openFilter,
                        leading: Icons.tune,
                      ),
                      const SizedBox(width: 6),
                      _SortDropdown(
                        value: _sort,
                        onChanged: (v) => setState(() => _sort = v),
                      ),
                      const Spacer(),
                      Text('${results.length}건',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                _activeFiltersBar(),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off,
                                    size: 56, color: AppColors.textFaint),
                                const SizedBox(height: 12),
                                const Text('조건에 맞는 공고가 없어요',
                                    style: TextStyle(
                                        color: AppColors.textMuted)),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () =>
                                      context.push('/me/saved-searches/new'),
                                  icon: const Icon(
                                      Icons.notifications_active_outlined,
                                      size: 18),
                                  label: const Text('알림으로 저장'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final j = results[i];
                            return JobCard(
                              job: j,
                              onTap: () {
                                if (!_recentViewed.contains(j.id)) {
                                  setState(() {
                                    _recentViewed.insert(0, j.id);
                                    if (_recentViewed.length > 8) {
                                      _recentViewed.removeLast();
                                    }
                                  });
                                }
                                context.push('/job/${j.id}');
                              },
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
