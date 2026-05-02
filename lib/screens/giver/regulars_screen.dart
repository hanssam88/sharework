import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

enum _SortMode { recent, hire, rating, name }

extension _SortModeX on _SortMode {
  String get label => switch (this) {
        _SortMode.recent => '최근 근무순',
        _SortMode.hire => '고용 횟수순',
        _SortMode.rating => '별점순',
        _SortMode.name => '이름 가나다순',
      };
}

class RegularsScreen extends StatefulWidget {
  const RegularsScreen({super.key});

  @override
  State<RegularsScreen> createState() => _RegularsScreenState();
}

class _RegularsScreenState extends State<RegularsScreen> {
  late List<RegularWorker> _items;
  final Map<int, String> _groups = {}; // workerId -> group name
  final Map<int, String> _memos = {};
  _SortMode _sort = _SortMode.recent;
  String? _filterGroup; // null=all
  bool _selectMode = false;
  final Set<int> _selected = {};

  static const _groupNames = ['A급', 'B급', '카페', '서빙', '행사'];

  static const _scoutTemplates = [
    ['일반 인사', '안녕하세요! 새 공고가 올라왔는데 시간이 되시면 함께 일해보고 싶어 연락드려요.'],
    ['시급 인상 제안', '지난번 근무가 좋아서 시급을 +1,000원 올려서 다시 모시고 싶어요.'],
    ['긴급 (오늘)', '오늘 갑자기 인원이 비어서 급하게 연락드려요. 가능하실까요?'],
    ['새 정기 공고', '매주 같은 요일 정기 근무 가능한 공고가 열렸어요. 안내드릴게요.'],
  ];

  @override
  void initState() {
    super.initState();
    _items = List.of(Dummy.regulars);
    if (_items.isNotEmpty) _groups[_items.first.workerId] = 'A급';
    if (_items.length > 1) _groups[_items[1].workerId] = '카페';
  }

  List<RegularWorker> get _visible {
    var list = _filterGroup == null
        ? List.of(_items)
        : _items
            .where((r) => _groups[r.workerId] == _filterGroup)
            .toList();
    switch (_sort) {
      case _SortMode.recent:
        list.sort((a, b) => b.lastWorkedAt.compareTo(a.lastWorkedAt));
        break;
      case _SortMode.hire:
        list.sort((a, b) => b.hireCount.compareTo(a.hireCount));
        break;
      case _SortMode.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return list;
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  void _toggleSelected(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _scoutSheet(List<RegularWorker> targets) {
    final activeJobs =
        Dummy.jobs.where((j) => j.status == JobStatus.open).toList();
    Job? selectedJob = activeJobs.isNotEmpty ? activeJobs.first : null;
    String chosenTemplate = _scoutTemplates.first[1];
    final msgCtrl = TextEditingController(text: chosenTemplate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (innerCtx, innerSet) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.send, color: AppColors.brandDark),
                    const SizedBox(width: 8),
                    Text(
                      targets.length == 1
                          ? '${targets.first.name}님께 스카웃'
                          : '${targets.length}명에게 일괄 스카웃',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (activeJobs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: AppColors.textMuted),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '진행 중인 공고가 없어요. 공고 없이 안부 메시지만 보낼 수 있어요.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  const Text('연결할 공고',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<Job>(
                      value: selectedJob,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: activeJobs
                          .map((j) => DropdownMenuItem(
                                value: j,
                                child: Text(
                                  '${j.title} · ${fmtMoney(j.pay)}/${j.payType}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          innerSet(() => selectedJob = v ?? selectedJob),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('메시지 템플릿',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _scoutTemplates
                      .map((t) => ChoiceChip(
                            label: Text(t[0]),
                            selected: chosenTemplate == t[1],
                            onSelected: (_) {
                              innerSet(() {
                                chosenTemplate = t[1];
                                msgCtrl.text = t[1];
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgCtrl,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: '메시지',
                    hintText: '직접 수정할 수 있어요',
                  ),
                ),
                const SizedBox(height: 12),
                if (targets.length > 1)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.groups,
                            size: 16, color: AppColors.brandDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${targets.map((t) => t.name).take(3).join(', ')}'
                            '${targets.length > 3 ? ' 외 ${targets.length - 3}명' : ''}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.brandDark,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    if (_selectMode) _exitSelectMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(targets.length == 1
                              ? '${targets.first.name}님께 스카웃이 발송됐어요'
                              : '${targets.length}명에게 스카웃을 보냈어요')),
                    );
                  },
                  child: Text(targets.length == 1 ? '발송' : '일괄 발송'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _memoSheet(RegularWorker r) {
    final ctrl = TextEditingController(text: _memos[r.workerId] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.name}님 메모',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('워커에게는 보이지 않는 비공개 메모예요',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 5,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '예) 강한 체력, 카페 메뉴 잘 알고 있음',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if ((_memos[r.workerId] ?? '').isNotEmpty) ...[
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _memos.remove(r.workerId));
                      Navigator.pop(sheetCtx);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('삭제'),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        if (ctrl.text.trim().isEmpty) {
                          _memos.remove(r.workerId);
                        } else {
                          _memos[r.workerId] = ctrl.text.trim();
                        }
                      });
                      Navigator.pop(sheetCtx);
                    },
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _groupSheet(RegularWorker r) {
    final current = _groups[r.workerId];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('그룹 할당',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('단골을 그룹별로 분류해 빠르게 찾을 수 있어요',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('해제'),
                    selected: current == null,
                    onSelected: (_) {
                      setState(() => _groups.remove(r.workerId));
                      Navigator.pop(sheetCtx);
                    },
                  ),
                  ..._groupNames.map((g) => ChoiceChip(
                        label: Text(g),
                        selected: current == g,
                        onSelected: (_) {
                          setState(() => _groups[r.workerId] = g);
                          Navigator.pop(sheetCtx);
                        },
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _quickActions(RegularWorker r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.brandSoft,
                    child: Text(r.name.substring(0, 1),
                        style: const TextStyle(
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Text(r.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _quickTile(Icons.send, '스카웃', AppColors.brandDark, () {
                    Navigator.pop(sheetCtx);
                    _scoutSheet([r]);
                  }),
                  _quickTile(Icons.chat_bubble, '메시지',
                      AppColors.brandDark, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${r.name}님과의 채팅 (목업)')),
                    );
                  }),
                  _quickTile(Icons.label_outline, '그룹',
                      AppColors.brandDark, () {
                    Navigator.pop(sheetCtx);
                    _groupSheet(r);
                  }),
                  _quickTile(Icons.sticky_note_2_outlined, '메모',
                      AppColors.brandDark, () {
                    Navigator.pop(sheetCtx);
                    _memoSheet(r);
                  }),
                  _quickTile(Icons.history, '근무 이력',
                      AppColors.brandDark, () {
                    Navigator.pop(sheetCtx);
                    _historySheet(r);
                  }),
                  _quickTile(Icons.star_border, '리뷰', AppColors.brandDark,
                      () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${r.name}님 리뷰 보기 (목업)')),
                    );
                  }),
                  _quickTile(Icons.person_remove, '단골 해제',
                      AppColors.danger, () {
                    Navigator.pop(sheetCtx);
                    _confirmRemove(r);
                  }),
                  _quickTile(Icons.flag_outlined, '신고',
                      AppColors.danger, () {
                    Navigator.pop(sheetCtx);
                    context.push('/report/user/${r.workerId}');
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickTile(IconData icon, String label, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color == AppColors.danger
                  ? const Color(0xFFFFE5E5)
                  : AppColors.brandSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _historySheet(RegularWorker r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${r.name}님과의 근무 이력 (총 ${r.hireCount}회)',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (var i = 0; i < (r.hireCount > 4 ? 4 : r.hireCount); i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.brandSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.coffee_outlined,
                            color: AppColors.brandDark, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [
                                '카페 모카 강남점 · 오후 근무',
                                '주말 행사 보조',
                                '시즌 이벤트 운영',
                                '평일 오픈 근무',
                              ][i % 4],
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              fmtRelative(r.lastWorkedAt
                                  .subtract(Duration(days: i * 14))),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7DA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 11, color: Color(0xFFFFC400)),
                            const SizedBox(width: 2),
                            Text((r.rating - i * 0.05).toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (r.hireCount > 4)
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('전체 이력 보기 (목업)')),
                    );
                  },
                  child: Text('나머지 ${r.hireCount - 4}건 더 보기'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemove(RegularWorker r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('단골 해제'),
        content: Text('${r.name}님을 단골에서 해제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _items.removeWhere((x) => x.workerId == r.workerId);
                _groups.remove(r.workerId);
                _memos.remove(r.workerId);
              });
            },
            child: const Text('해제'),
          ),
        ],
      ),
    );
  }

  void _showSortFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (innerCtx, innerSet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('정렬·필터',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Text('정렬',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _SortMode.values
                      .map((s) => ChoiceChip(
                            label: Text(s.label),
                            selected: _sort == s,
                            onSelected: (_) {
                              innerSet(() => _sort = s);
                              setState(() => _sort = s);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text('그룹 필터',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('전체'),
                      selected: _filterGroup == null,
                      onSelected: (_) {
                        innerSet(() => _filterGroup = null);
                        setState(() => _filterGroup = null);
                      },
                    ),
                    ..._groupNames.map((g) => ChoiceChip(
                          label: Text(g),
                          selected: _filterGroup == g,
                          onSelected: (_) {
                            innerSet(() => _filterGroup = g);
                            setState(() => _filterGroup = g);
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Text('적용'),
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
    final visible = _visible;
    final selected =
        _items.where((r) => _selected.contains(r.workerId)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode
            ? '${_selected.length}명 선택됨'
            : '단골 워커'),
        leading: _selectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectMode,
              )
            : null,
        actions: _selectMode
            ? [
                IconButton(
                  icon: const Icon(Icons.send),
                  tooltip: '일괄 스카웃',
                  onPressed: _selected.isEmpty
                      ? null
                      : () => _scoutSheet(selected),
                ),
                IconButton(
                  icon: const Icon(Icons.chat),
                  tooltip: '일괄 메시지',
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${selected.length}명에게 메시지 발송 (목업)')),
                          );
                          _exitSelectMode();
                        },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: '정렬·필터',
                  onPressed: _showSortFilterSheet,
                ),
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: '일괄 선택',
                  onPressed: () =>
                      setState(() => _selectMode = true),
                ),
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
                      if (_filterGroup != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_filterGroup!,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandDark)),
                        ),
                      ],
                      const Spacer(),
                      Text('정렬: ${_sort.label}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: visible.isEmpty
                      ? const EmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          message: '필터에 해당하는 워커가 없어요',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final r = visible[i];
                            final group = _groups[r.workerId];
                            final memo = _memos[r.workerId];
                            final sel = _selected.contains(r.workerId);
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (_selectMode) {
                                  _toggleSelected(r.workerId);
                                } else {
                                  _quickActions(r);
                                }
                              },
                              onLongPress: () {
                                setState(() {
                                  _selectMode = true;
                                  _selected.add(r.workerId);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.brandDark
                                        : AppColors.divider,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (_selectMode)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8),
                                            child: Icon(
                                              sel
                                                  ? Icons.check_circle
                                                  : Icons
                                                      .radio_button_unchecked,
                                              color: sel
                                                  ? AppColors.brandDark
                                                  : AppColors.textFaint,
                                            ),
                                          ),
                                        InkWell(
                                          onTap: _selectMode
                                              ? null
                                              : () => context.push(
                                                  '/giver/workers/${r.workerId}'),
                                          child: const CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                                AppColors.brandSoft,
                                            child: Icon(Icons.person,
                                                color:
                                                    AppColors.brandDark),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(r.name,
                                                      style:
                                                          const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              fontSize:
                                                                  15)),
                                                  if (group != null) ...[
                                                    const SizedBox(
                                                        width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 6,
                                                              vertical: 2),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: AppColors
                                                            .brandDark,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Text(group,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color: Colors
                                                                      .white)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star,
                                                      color: Color(
                                                          0xFFFFC400),
                                                      size: 14),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${r.rating} · ${r.reviewCount}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textMuted),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: AppColors
                                                          .brandSoft,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(6),
                                                    ),
                                                    child: Text(
                                                      '${r.hireCount}회 채용',
                                                      style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w800,
                                                          color: AppColors
                                                              .brandDark),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!_selectMode)
                                          IconButton(
                                            icon:
                                                const Icon(Icons.more_vert),
                                            onPressed: () =>
                                                _quickActions(r),
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
                                    if (memo != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF8E1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                                Icons
                                                    .sticky_note_2_outlined,
                                                size: 14,
                                                color: Color(0xFFB45309)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(memo,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(
                                                          0xFF7C5300))),
                                            ),
                                          ],
                                        ),
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
                                        if (!_selectMode)
                                          FilledButton.icon(
                                            onPressed: () =>
                                                _scoutSheet([r]),
                                            icon: const Icon(Icons.send,
                                                size: 16),
                                            label: const Text('스카웃'),
                                            style: FilledButton.styleFrom(
                                              minimumSize:
                                                  const Size(0, 36),
                                              padding: const EdgeInsets
                                                  .symmetric(horizontal: 14),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
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
