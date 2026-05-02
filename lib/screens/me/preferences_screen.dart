import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late WorkerPreferences _prefs;
  late Set<JobCategory> _categories;
  late Set<WorkType> _workTypes;
  late int _hourly;
  late int _radius;

  @override
  void initState() {
    super.initState();
    _prefs = Dummy.preferences;
    _categories = {..._prefs.preferredCategories};
    _workTypes = {..._prefs.preferredWorkTypes};
    _hourly = _prefs.preferredHourly;
    _radius = _prefs.preferredRadiusKm;
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('희망 조건이 저장되었습니다 (목업)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('희망 조건')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune, color: AppColors.brandDark, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '설정한 조건에 맞는 공고가 알림으로 추천됩니다.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: '희망 시급',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fmtMoney(_hourly),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDark,
                  ),
                ),
                Slider(
                  value: _hourly.toDouble(),
                  min: 10000,
                  max: 30000,
                  divisions: 40,
                  activeColor: AppColors.brandDark,
                  label: fmtMoney(_hourly),
                  onChanged: (v) => setState(() => _hourly = v.round()),
                ),
                Row(
                  children: const [
                    Text('1만원',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textFaint)),
                    Spacer(),
                    Text('3만원',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textFaint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '근무 반경',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '반경 ${_radius}km 이내',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDark,
                  ),
                ),
                Slider(
                  value: _radius.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: AppColors.brandDark,
                  label: '${_radius}km',
                  onChanged: (v) => setState(() => _radius = v.round()),
                ),
                Row(
                  children: const [
                    Text('1km',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textFaint)),
                    Spacer(),
                    Text('30km',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textFaint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '관심 카테고리',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: JobCategory.values.map((c) {
                final on = _categories.contains(c);
                return FilterChip(
                  label: Text(c.label),
                  selected: on,
                  onSelected: (v) {
                    setState(() {
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
          ),
          const SizedBox(height: 16),
          _Section(
            title: '근무 유형',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WorkType.values.map((w) {
                final on = _workTypes.contains(w);
                return FilterChip(
                  label: Text(w.label),
                  selected: on,
                  onSelected: (v) {
                    setState(() {
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
          ),
          const SizedBox(height: 16),
          _Section(
            title: '기타',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _prefs.allowSameDay,
                  onChanged: (v) => setState(
                      () => _prefs = _prefs.copyWith(allowSameDay: v)),
                  title: const Text('당일 매칭 알림 받기'),
                  subtitle: const Text(
                    '오늘/내일 시작하는 공고도 알림',
                    style: TextStyle(fontSize: 11),
                  ),
                  activeColor: AppColors.brandDark,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _prefs.allowNight,
                  onChanged: (v) => setState(
                      () => _prefs = _prefs.copyWith(allowNight: v)),
                  title: const Text('야간 근무 가능 (22시~06시)'),
                  activeColor: AppColors.brandDark,
                ),
              ],
            ),
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

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
