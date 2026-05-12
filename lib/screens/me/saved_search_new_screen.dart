import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

class SavedSearchNewScreen extends StatefulWidget {
  const SavedSearchNewScreen({super.key});

  @override
  State<SavedSearchNewScreen> createState() => _SavedSearchNewScreenState();
}

class _SavedSearchNewScreenState extends State<SavedSearchNewScreen> {
  final _labelCtrl = TextEditingController();
  final _keywordCtrl = TextEditingController();
  final Set<JobCategory> _categories = {};
  int? _minHourly;
  double _radius = 5;
  bool _sameDayOnly = false;
  bool _nightOk = false;
  bool _pushEnabled = true;

  static const _hourlyOptions = [0, 11000, 12000, 13000, 15000, 20000];

  @override
  void dispose() {
    _labelCtrl.dispose();
    _keywordCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_labelCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 이름을 입력해주세요')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장된 검색이 추가되었어요 (목업)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 조건 만들기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          const _Label('알림 이름'),
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              hintText: '예) 강남 카페 시급 1.3만↑',
            ),
          ),
          const SizedBox(height: 16),
          const _Label('키워드 (선택)'),
          TextField(
            controller: _keywordCtrl,
            decoration: const InputDecoration(
              hintText: '예) 카페, 행사, 마트',
            ),
          ),
          const SizedBox(height: 16),
          const _Label('카테고리'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: JobCategory.values.map((c) {
              final on = _categories.contains(c);
              return FilterChip(
                label: Text(c.label),
                selected: on,
                showCheckmark: false,
                selectedColor: AppColors.brandDark,
                labelStyle: TextStyle(
                  color: on ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _categories.add(c);
                    } else {
                      _categories.remove(c);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _Label('최저 시급 (선택)'),
          Wrap(
            spacing: 8,
            children: _hourlyOptions.map((h) {
              final on = _minHourly == h || (_minHourly == null && h == 0);
              return ChoiceChip(
                label: Text(h == 0 ? '제한 없음' : '${h ~/ 1000}천원↑'),
                selected: on,
                showCheckmark: false,
                selectedColor: AppColors.brandDark,
                labelStyle: TextStyle(
                  color: on ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) =>
                    setState(() => _minHourly = h == 0 ? null : h),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _Label('반경 ${_radius.toStringAsFixed(0)}km'),
          Slider(
            value: _radius,
            min: 1,
            max: 20,
            divisions: 19,
            label: '${_radius.toStringAsFixed(0)}km',
            activeColor: AppColors.brandDark,
            onChanged: (v) => setState(() => _radius = v),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _sameDayOnly,
            activeColor: AppColors.brandDark,
            contentPadding: EdgeInsets.zero,
            title: const Text('당일지급만'),
            subtitle: const Text('근무 즉시 자동 송금되는 공고만',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onChanged: (v) => setState(() => _sameDayOnly = v),
          ),
          SwitchListTile(
            value: _nightOk,
            activeColor: AppColors.brandDark,
            contentPadding: EdgeInsets.zero,
            title: const Text('야간 근무 포함'),
            subtitle: const Text('22시 이후 시작 공고도 받기',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onChanged: (v) => setState(() => _nightOk = v),
          ),
          const Divider(height: 32, color: AppColors.divider),
          SwitchListTile(
            value: _pushEnabled,
            activeColor: AppColors.brandDark,
            contentPadding: EdgeInsets.zero,
            title: const Text('푸시 알림 받기',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('조건에 맞는 새 공고가 등록되면 즉시 알려드려요',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _save,
            child: const Text('저장하기'),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      );
}
