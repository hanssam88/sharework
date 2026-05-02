import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  final List<String> _tags = ['카페'];
  final List<String> _checklists = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공고 등록')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
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
