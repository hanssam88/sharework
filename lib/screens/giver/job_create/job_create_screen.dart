import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';

class JobCreateScreen extends StatefulWidget {
  const JobCreateScreen({super.key});

  @override
  State<JobCreateScreen> createState() => _JobCreateScreenState();
}

class _JobCreateScreenState extends State<JobCreateScreen> {
  String _payType = '시급';
  bool _sameDayPay = true;
  bool _foodProvided = false;
  bool _extraPay = false;
  bool _recurring = false;
  final Set<int> _recurrenceWeekdays = {};
  final List<String> _tags = ['카페'];
  final List<String> _checklists = [];
  String? _appliedTemplate;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  void _openTemplateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('템플릿에서 불러오기',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...Dummy.jobTemplates.map((t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.dashboard_customize,
                          color: AppColors.brandDark, size: 18),
                    ),
                    title: Text(t.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${t.title} · ${t.payHourly}원/시간 · ${t.defaultPersonnel}명',
                        style: const TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _applyTemplate(t);
                    },
                  )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  context.push('/giver/job/templates');
                },
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: const Text('템플릿 관리'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyTemplate(JobTemplate t) {
    setState(() {
      _appliedTemplate = t.name;
      _sameDayPay = t.sameDayPayment;
      _foodProvided = t.foodProvided;
      _extraPay = t.extraPay;
      _tags
        ..clear()
        ..addAll(t.tags);
      _recurrenceWeekdays
        ..clear()
        ..addAll(t.recurrenceWeekdays);
      _recurring = _recurrenceWeekdays.isNotEmpty;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('템플릿 「${t.name}」 적용 완료')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공고 등록'),
        actions: [
          TextButton.icon(
            onPressed: _openTemplateSheet,
            icon: const Icon(Icons.dashboard_customize_outlined,
                size: 18),
            label: const Text('템플릿'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          if (_appliedTemplate != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.brandDark, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '템플릿 「$_appliedTemplate」 적용됨',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close,
                        color: AppColors.brandDark),
                    onPressed: () =>
                        setState(() => _appliedTemplate = null),
                  ),
                ],
              ),
            ),
          const _SectionTitle('기본 정보'),
          const _Label('공고 제목'),
          const TextField(
            decoration: InputDecoration(hintText: '예: 주말 카페 알바 구합니다'),
          ),
          const SizedBox(height: 16),
          const _Label('일할 장소'),
          Row(
            children: [
              const Expanded(
                child: TextField(decoration: InputDecoration(hintText: '주소를 검색해주세요')),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: OutlinedButton(onPressed: () {}, child: const Text('주소검색')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const TextField(
            decoration: InputDecoration(hintText: '상세 주소 (선택)'),
          ),
          const SizedBox(height: 16),
          const _Label('도움이 필요한 날짜'),
          const _DatePickerRow(),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _TimeBox(label: '시작시간', time: '오전 9:00')),
              SizedBox(width: 12),
              Expanded(child: _TimeBox(label: '종료시간', time: '오후 5:00')),
            ],
          ),
          const SizedBox(height: 16),
          const _Label('필요한 인원'),
          const TextField(
            decoration: InputDecoration(hintText: '예: 2', suffixText: '명'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const _Label('업무 태그'),
          const Text('업무와 관련된 키워드를 추가해주세요.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._tags.map((t) => Chip(
                    label: Text('#$t'),
                    onDeleted: () => setState(() => _tags.remove(t)),
                  )),
              ActionChip(
                label: const Text('+ 추가하기'),
                onPressed: () => setState(() => _tags.add('새태그')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _Label('임금'),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<String>(
                  value: _payType,
                  items: const [
                    DropdownMenuItem(value: '시급', child: Text('시급')),
                    DropdownMenuItem(value: '일급', child: Text('일급')),
                    DropdownMenuItem(value: '월급', child: Text('월급')),
                    DropdownMenuItem(value: '건당', child: Text('건당')),
                  ],
                  onChanged: (v) => setState(() => _payType = v ?? '시급'),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: '0', suffixText: '원'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _sameDayPay,
            onChanged: (v) => setState(() => _sameDayPay = v),
            title: const Text('당일지급', style: TextStyle(fontSize: 14)),
            activeColor: AppColors.brandDark,
          ),
          const SizedBox(height: 16),
          const _Label('상세설명'),
          const TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '업무 내용을 자세히 적어주시면 좋은 알바를 만날 확률이 올라가요.',
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('상세 정보 등록'),
          const Text('상세 정보를 입력해 주시면 큰 도움이 됩니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          const _Label('제공항목'),
          Row(
            children: [
              _Toggle(
                  label: '식사제공',
                  icon: Icons.restaurant_outlined,
                  selected: _foodProvided,
                  onTap: () => setState(() => _foodProvided = !_foodProvided)),
              const SizedBox(width: 12),
              _Toggle(
                  label: '교통비지원',
                  icon: Icons.directions_bus_outlined,
                  selected: _extraPay,
                  onTap: () => setState(() => _extraPay = !_extraPay)),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('반복 일정'),
          const Text('정기 반복 공고는 매주 같은 요일에 자동으로 재게시됩니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _recurring,
            onChanged: (v) {
              setState(() {
                _recurring = v;
                if (!v) _recurrenceWeekdays.clear();
              });
            },
            title: const Text('반복 공고로 등록',
                style: TextStyle(fontSize: 14)),
            activeColor: AppColors.brandDark,
          ),
          if (_recurring) ...[
            const SizedBox(height: 6),
            Row(
              children: List.generate(7, (i) {
                final d = i + 1;
                final on = _recurrenceWeekdays.contains(d);
                final isWeekend = i >= 5;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (on) {
                          _recurrenceWeekdays.remove(d);
                        } else {
                          _recurrenceWeekdays.add(d);
                        }
                      }),
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
                        child: Text(
                          _weekdayLabels[i],
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: on
                                ? Colors.white
                                : (isWeekend
                                    ? AppColors.danger
                                    : AppColors.text),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            if (_recurrenceWeekdays.isNotEmpty)
              Text(
                '매주 ${(_recurrenceWeekdays.toList()..sort()).map((d) => _weekdayLabels[d - 1]).join('·')} 자동 재게시',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w700),
              ),
          ],
          const SizedBox(height: 24),
          const _SectionTitle('체크리스트'),
          const Text('알바에게 궁금한 항목을 선택해주세요.\n알바가 지원할 때 체크하게 됩니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          ..._checklists.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_box_outline_blank,
                          color: AppColors.textFaint),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.value)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            setState(() => _checklists.removeAt(e.key)),
                      )
                    ],
                  ),
                ),
              ),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _checklists.add('새 체크리스트 항목')),
            icon: const Icon(Icons.add),
            label: const Text('체크리스트 등록'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: () => context.pop(),
            child: const Text('공고 등록'),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 8),
        child: Text(text,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      );
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 18, color: AppColors.textMuted),
          SizedBox(width: 8),
          Text('날짜 선택'),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String time;
  const _TimeBox({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time,
                  size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(time),
            ],
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _Toggle(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandSoft : AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.brandDark : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.brandDark : AppColors.textMuted,
                size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: selected ? AppColors.brandDark : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
