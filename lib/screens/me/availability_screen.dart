import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  // weekday(1~7) → set of hour blocks (0~23)
  late Map<int, Set<int>> _grid;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  // 4시간 블록: 0=새벽(0-6), 1=오전(6-12), 2=오후(12-18), 3=저녁(18-24)
  static const _blockLabels = ['00-06', '06-12', '12-18', '18-24'];
  static const _blockRanges = [
    [0, 6],
    [6, 12],
    [12, 18],
    [18, 24],
  ];

  @override
  void initState() {
    super.initState();
    _grid = {for (var i = 1; i <= 7; i++) i: <int>{}};
    for (final s in Dummy.availability) {
      for (var b = 0; b < _blockRanges.length; b++) {
        final r = _blockRanges[b];
        if (s.startHour <= r[0] && s.endHour >= r[1]) {
          _grid[s.weekday]!.add(b);
        }
      }
    }
  }

  bool _isOn(int weekday, int block) => _grid[weekday]!.contains(block);

  void _toggle(int weekday, int block) {
    setState(() {
      if (_isOn(weekday, block)) {
        _grid[weekday]!.remove(block);
      } else {
        _grid[weekday]!.add(block);
      }
    });
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('가용 시간이 저장되었습니다 (목업)')),
    );
    context.pop();
  }

  int get _totalBlocks =>
      _grid.values.fold<int>(0, (acc, s) => acc + s.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가용 시간')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_view_week,
                    color: AppColors.brandDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('일하실 수 있는 시간대를 선택해주세요',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        '선택된 블록: $_totalBlocks개 (각 6시간)',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // header row
          Row(
            children: [
              const SizedBox(width: 36),
              ...List.generate(7, (i) {
                final isWeekend = i >= 5;
                return Expanded(
                  child: Center(
                    child: Text(
                      _weekdayLabels[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isWeekend
                            ? AppColors.danger
                            : AppColors.text,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_blockLabels.length, (b) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      _blockLabels[b],
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                  ),
                  ...List.generate(7, (w) {
                    final weekday = w + 1;
                    final on = _isOn(weekday, b);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GestureDetector(
                          onTap: () => _toggle(weekday, b),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            height: 44,
                            decoration: BoxDecoration(
                              color: on
                                  ? AppColors.brandDark
                                  : AppColors.chipBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: on
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var i = 1; i <= 5; i++) {
                        _grid[i]!
                          ..clear()
                          ..addAll([1, 2]); // 평일 06-18
                      }
                      _grid[6]!.clear();
                      _grid[7]!.clear();
                    });
                  },
                  icon: const Icon(Icons.work_history_outlined, size: 16),
                  label: const Text('평일 낮'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var i = 1; i <= 5; i++) {
                        _grid[i]!.clear();
                      }
                      _grid[6]!
                        ..clear()
                        ..addAll([1, 2, 3]);
                      _grid[7]!
                        ..clear()
                        ..addAll([1, 2, 3]);
                    });
                  },
                  icon: const Icon(Icons.weekend_outlined, size: 16),
                  label: const Text('주말'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _grid.forEach((_, s) => s.clear())),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('전체 해제'),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ),
      ),
    );
  }
}
