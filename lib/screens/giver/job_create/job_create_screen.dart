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
  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _addressDetailCtrl = TextEditingController();
  final _personnelCtrl = TextEditingController(text: '1');
  final _payCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _payType = '시급';
  bool _sameDayPay = true;
  bool _foodProvided = false;
  bool _extraPay = false;
  bool _recurring = false;
  final Set<int> _recurrenceWeekdays = {};
  final List<String> _tags = ['카페'];
  final List<String> _checklists = [];
  String? _appliedTemplate;

  DateTime? _date;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);

  bool _draftSaved = false;
  String _publishMode = '즉시 게시'; // 즉시 / 예약 / 비공개

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  // 시장가 데이터 (목업: 카테고리·시간대별)
  int get _marketAverage {
    if (_payType != '시급') return 12000;
    if (_tags.contains('카페')) return 12000;
    if (_tags.contains('마트')) return 11500;
    if (_tags.contains('행사')) return 13500;
    return 12500;
  }

  int get _enteredPay => int.tryParse(_payCtrl.text.replaceAll(',', '')) ?? 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _addressDetailCtrl.dispose();
    _personnelCtrl.dispose();
    _payCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _saveDraft() {
    setState(() => _draftSaved = true);
    _snack('임시저장되었어요. 마이페이지 > 공고 임시저장에서 이어 쓸 수 있어요 (목업)');
  }

  Future<bool> _confirmExit() async {
    if (_titleCtrl.text.isEmpty &&
        _payCtrl.text.isEmpty &&
        _descCtrl.text.isEmpty) {
      return true;
    }
    final r = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('작성 중인 공고가 있어요'),
        content: const Text('임시저장하면 나중에 이어 쓸 수 있어요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child:
                  const Text('나가기', style: TextStyle(color: AppColors.danger))),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('계속 쓰기')),
          FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size(80, 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('임시저장')),
        ],
      ),
    );
    if (r == 'save') {
      _saveDraft();
      return true;
    }
    return r == 'discard';
  }

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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
      _titleCtrl.text = t.title;
      _addressCtrl.text = t.address;
      _personnelCtrl.text = t.defaultPersonnel.toString();
      _payCtrl.text = t.payHourly.toString();
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
    _snack('템플릿 「${t.name}」 적용 완료');
  }

  void _openAddressSearch() {
    final ctrl = TextEditingController(text: _addressCtrl.text);
    final mockResults = const [
      _AddressItem('서울 강남구 역삼동 123-45', '역삼역 도보 5분', '06236'),
      _AddressItem('서울 강남구 테헤란로 152', '강남파이낸스센터 인근', '06236'),
      _AddressItem('서울 강남구 논현로 508', '학동역 1번 출구', '06090'),
      _AddressItem('서울 송파구 잠실동 올림픽로 25', '잠실종합운동장 앞', '05540'),
      _AddressItem('서울 마포구 합정동 30-12', '합정역 4번 출구 도보 3분', '04079'),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetCtx).size.height * 0.7,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('주소 검색',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: '도로명·지번·건물명 검색',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _snack('현재 위치로 자동 입력 (목업)');
                          setState(() {
                            _addressCtrl.text = '서울 강남구 테헤란로 123';
                          });
                        },
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('현재 위치'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _snack('지도에서 핀 찍기 (목업)');
                        },
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('지도에서 선택'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: mockResults.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) {
                        final a = mockResults[i];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined,
                              color: AppColors.brandDark),
                          title: Text(a.full,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          subtitle: Text('${a.landmark} · 우편번호 ${a.zip}',
                              style: const TextStyle(fontSize: 11)),
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            setState(() => _addressCtrl.text = a.full);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  void _openTagAdd() {
    final ctrl = TextEditingController();
    final suggestions = const [
      '카페',
      '주말',
      '단기',
      '오픈',
      '마감',
      '마트',
      '진열',
      '계산',
      '행사',
      '스태프',
      '바리스타',
      '서빙',
      '청소',
      '물류',
      '배달',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('태그 추가',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.tag),
                    hintText: '직접 입력 (10자 이내)',
                  ),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      setState(() => _tags.add(v.trim()));
                      Navigator.pop(sheetCtx);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('추천 태그',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: suggestions
                      .where((s) => !_tags.contains(s))
                      .map((s) => ActionChip(
                            label: Text('#$s'),
                            onPressed: () {
                              setState(() => _tags.add(s));
                              Navigator.pop(sheetCtx);
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openChecklistAdd() {
    final ctrl = TextEditingController();
    final presets = const [
      '카페 알바 경험 있으신가요?',
      '바리스타 자격증 보유?',
      '주말 8시간 근무 가능?',
      '장시간 서서 근무 가능?',
      '복장 단정 가능?',
      '4시간 연속 근무 가능?',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('체크리스트 추가',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText: '예) 야간 근무 가능하신가요?',
                  ),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      setState(() => _checklists.add(v.trim()));
                      Navigator.pop(sheetCtx);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('추천',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                ...presets.map((p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(p, style: const TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.add, size: 18),
                      onTap: () {
                        setState(() => _checklists.add(p));
                        Navigator.pop(sheetCtx);
                      },
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickPublishMode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('게시 방식',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ...['즉시 게시', '예약 게시', '비공개 (링크 공유만)'].map((m) {
              final on = _publishMode == m;
              return RadioListTile<String>(
                value: m,
                groupValue: _publishMode,
                activeColor: AppColors.brandDark,
                title: Text(m),
                selected: on,
                onChanged: (v) {
                  setState(() => _publishMode = v ?? m);
                  Navigator.pop(sheetCtx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour;
    final period = h < 12 ? '오전' : '오후';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final m = t.minute.toString().padLeft(2, '0');
    return '$period $h12:$m';
  }

  String _fmtDate(DateTime d) => '${d.year}년 ${d.month}월 ${d.day}일 (${[
        '월',
        '화',
        '수',
        '목',
        '금',
        '토',
        '일'
      ][d.weekday - 1]})';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit()) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('공고 등록'),
          actions: [
            TextButton.icon(
              onPressed: _saveDraft,
              icon: Icon(
                  _draftSaved ? Icons.cloud_done : Icons.cloud_upload_outlined,
                  size: 16),
              label: Text(_draftSaved ? '저장됨' : '임시저장'),
            ),
            TextButton.icon(
              onPressed: _openTemplateSheet,
              icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      icon: const Icon(Icons.close, color: AppColors.brandDark),
                      onPressed: () => setState(() => _appliedTemplate = null),
                    ),
                  ],
                ),
              ),
            const _SectionTitle('기본 정보'),
            const _Label('공고 제목'),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: '예: 주말 카페 알바 구합니다'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            const _Label('일할 장소'),
            InkWell(
              onTap: _openAddressSearch,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _addressCtrl.text.isEmpty
                            ? '주소를 검색해주세요'
                            : _addressCtrl.text,
                        style: TextStyle(
                          color: _addressCtrl.text.isEmpty
                              ? AppColors.textFaint
                              : AppColors.text,
                          fontWeight: _addressCtrl.text.isEmpty
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressDetailCtrl,
              decoration: const InputDecoration(hintText: '상세 주소 (선택)'),
            ),
            const SizedBox(height: 16),
            const _Label('도움이 필요한 날짜'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      _date == null ? '날짜 선택' : _fmtDate(_date!),
                      style: TextStyle(
                        color: _date == null
                            ? AppColors.textFaint
                            : AppColors.text,
                        fontWeight:
                            _date == null ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeBox(
                    label: '시작시간',
                    time: _fmtTime(_start),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeBox(
                    label: '종료시간',
                    time: _fmtTime(_end),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _Label('필요한 인원'),
            TextField(
              controller: _personnelCtrl,
              decoration:
                  const InputDecoration(hintText: '예: 2', suffixText: '명'),
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
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('추가'),
                  onPressed: _openTagAdd,
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
                Expanded(
                  child: TextField(
                    controller: _payCtrl,
                    decoration:
                        const InputDecoration(hintText: '0', suffixText: '원'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            // 시급 시장가
            const SizedBox(height: 8),
            _MarketPriceCard(
              entered: _enteredPay,
              market: _marketAverage,
              payType: _payType,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sameDayPay,
              onChanged: (v) => setState(() => _sameDayPay = v),
              title: const Text('당일지급', style: TextStyle(fontSize: 14)),
              subtitle: const Text('근무 종료 즉시 자동 송금 (워커가 매우 선호해요)',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              activeColor: AppColors.brandDark,
            ),
            const SizedBox(height: 16),
            const _Label('상세설명'),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '업무 내용을 자세히 적어주시면 좋은 알바를 만날 확률이 올라가요.',
              ),
              onChanged: (_) => setState(() {}),
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
                    onTap: () =>
                        setState(() => _foodProvided = !_foodProvided)),
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
              title: const Text('반복 공고로 등록', style: TextStyle(fontSize: 14)),
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
                            color: on ? AppColors.brandDark : AppColors.chipBg,
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
              onPressed: _openChecklistAdd,
              icon: const Icon(Icons.add),
              label: const Text('체크리스트 등록'),
            ),

            const SizedBox(height: 24),
            const _SectionTitle('게시 방식'),
            InkWell(
              onTap: _pickPublishMode,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.send_outlined,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_publishMode,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const Icon(Icons.expand_more,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/giver/job/preview'),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('미리보기'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      _snack('공고가 등록되었습니다 ($_publishMode · 목업)');
                      context.pop();
                    },
                    child: Text(_publishMode == '예약 게시' ? '예약 등록' : '공고 등록'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressItem {
  final String full;
  final String landmark;
  final String zip;
  const _AddressItem(this.full, this.landmark, this.zip);
}

class _MarketPriceCard extends StatelessWidget {
  final int entered;
  final int market;
  final String payType;
  const _MarketPriceCard({
    required this.entered,
    required this.market,
    required this.payType,
  });

  @override
  Widget build(BuildContext context) {
    if (payType != '시급') {
      return const SizedBox.shrink();
    }
    String label;
    Color color;
    IconData icon;
    if (entered == 0) {
      label = '이 동네 평균 시급 ${(market / 1000).toStringAsFixed(0)}천원';
      color = AppColors.textMuted;
      icon = Icons.info_outline;
    } else if (entered < market * 0.95) {
      label =
          '평균보다 낮음 (평균 ${(market / 1000).toStringAsFixed(0)}천원). 지원율이 떨어질 수 있어요';
      color = AppColors.danger;
      icon = Icons.trending_down;
    } else if (entered > market * 1.1) {
      label =
          '평균보다 높음 (평균 ${(market / 1000).toStringAsFixed(0)}천원). 지원율이 평균 +35%';
      color = AppColors.brandDark;
      icon = Icons.trending_up;
    } else {
      label = '평균 시급과 비슷해요 (평균 ${(market / 1000).toStringAsFixed(0)}천원)';
      color = const Color(0xFFB45309);
      icon = Icons.trending_flat;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          ),
        ],
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
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      );
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimeBox(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                Text(time, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
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
