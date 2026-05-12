import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class ApplicantsScreen extends StatefulWidget {
  final int jobId;
  const ApplicantsScreen({super.key, required this.jobId});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  late List<JobApplication> _items;
  bool _selectMode = false;
  final Set<int> _selected = {};
  bool _autoHire = false;

  @override
  void initState() {
    super.initState();
    _items = Dummy.applicantsForJob(widget.jobId);
  }

  // 매칭 점수: 평점·거리·태그를 합산 (목업 결정적 함수)
  int _matchScore(JobApplication app) {
    final w = Dummy.userById(app.workerId);
    final job = Dummy.jobById(widget.jobId);
    final ratingPart = ((w.rating - 3.0) / 2.0 * 40).clamp(0, 40).toInt();
    final distancePart = (40 - app.distanceKm * 4).clamp(0, 40).toInt();
    final tagOverlap =
        w.tags.where((t) => job.tags.any((jt) => jt.contains(t))).length;
    final tagPart = (tagOverlap * 10).clamp(0, 20);
    return (ratingPart + distancePart + tagPart).clamp(0, 100);
  }

  Color _scoreColor(int s) {
    if (s >= 85) return AppColors.brandDark;
    if (s >= 65) return const Color(0xFFB45309);
    return AppColors.textMuted;
  }

  String _scoreLabel(int s) {
    if (s >= 85) return '매우 적합';
    if (s >= 65) return '적합';
    return '검토';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _setStatus(JobApplication app, ApplicationStatus status) {
    setState(() {
      final idx = _items.indexWhere((a) => a.id == app.id);
      _items[idx] = JobApplication(
        id: app.id,
        jobId: app.jobId,
        workerId: app.workerId,
        status: status,
        appliedAt: app.appliedAt,
        distanceKm: app.distanceKm,
      );
    });
  }

  void _hire(JobApplication app) {
    _setStatus(app, ApplicationStatus.hired);
    _snack('${Dummy.userById(app.workerId).name} 채용 확정 (목업)');
  }

  void _reject(JobApplication app) {
    _showRejectReasonSheet(onPick: (reason, sendMessage) {
      _setStatus(app, ApplicationStatus.rejected);
      if (sendMessage) {
        _snack('거절 메시지 자동 발송: $reason');
      } else {
        _snack('${Dummy.userById(app.workerId).name} 거절 처리');
      }
    });
  }

  void _showRejectReasonSheet(
      {required void Function(String reason, bool sendMessage) onPick}) {
    String? selected;
    bool send = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('거절 사유',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  '선택한 사유는 워커에게 공개되지 않으며 통계에만 사용돼요.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                ...[
                  '일정이 맞지 않음',
                  '거리가 멀음',
                  '경험·자격 부족',
                  '이미 인원이 다 찼음',
                  '단순 변심',
                  '기타',
                ].map((r) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: r,
                      groupValue: selected,
                      activeColor: AppColors.brandDark,
                      title: Text(r),
                      onChanged: (v) => setSheet(() => selected = v),
                    )),
                const Divider(),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: send,
                  activeColor: AppColors.brandDark,
                  title: const Text('정중한 거절 메시지 자동 전송',
                      style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                      '"이번에는 다른 분과 함께하게 되었습니다. 다음 기회에 또 만나요." (자동 작성)',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  onChanged: (v) => setSheet(() => send = v ?? true),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger),
                        onPressed: selected == null
                            ? null
                            : () {
                                Navigator.pop(sheetCtx);
                                onPick(selected!, send);
                              },
                        child: const Text('거절'),
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

  void _openTemplateSheet(JobApplication app) {
    final w = Dummy.userById(app.workerId);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${w.name}님께 빠른 답장',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ..._templates.map((t) => ListTile(
                  leading: Icon(t.icon, color: AppColors.brandDark),
                  title: Text(t.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(t.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _snack('"${t.title}" 메시지 발송 (목업)');
                  },
                )),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('직접 작성'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('채팅방 진입 (목업)');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.phone_outlined, color: AppColors.brandDark),
              title: const Text('안심번호 통화'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('050-xxxx-xxxx 연결 (목업)');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openCompareDialog() {
    final selectedApps = _items.where((a) => _selected.contains(a.id)).toList();
    if (selectedApps.length < 2) {
      _snack('비교할 지원자를 2명 이상 선택해주세요');
      return;
    }
    if (selectedApps.length > 3) {
      _snack('한 번에 최대 3명까지 비교할 수 있어요');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('지원자 비교',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedApps.map((a) {
                    final w = Dummy.userById(a.workerId);
                    final score = _matchScore(a);
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          _kv('매칭', '$score점', color: _scoreColor(score)),
                          _kv('평점', '${w.rating} (${w.reviewCount})'),
                          _kv('거리', '${a.distanceKm.toStringAsFixed(1)}km'),
                          _kv('지원', fmtRelative(a.appliedAt)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children:
                                w.tags.take(3).map((t) => TagChip(t)).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 36,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted))),
          Expanded(
            child: Text(v,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color ?? AppColors.text)),
          ),
        ],
      ),
    );
  }

  void _bulkHire() {
    final apps = _items.where((a) => _selected.contains(a.id)).toList();
    for (final a in apps) {
      _setStatus(a, ApplicationStatus.hired);
    }
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
    _snack('${apps.length}명 일괄 채용 확정 (목업)');
  }

  void _bulkReject() {
    _showRejectReasonSheet(onPick: (reason, send) {
      final apps = _items.where((a) => _selected.contains(a.id)).toList();
      for (final a in apps) {
        _setStatus(a, ApplicationStatus.rejected);
      }
      setState(() {
        _selected.clear();
        _selectMode = false;
      });
      _snack('${apps.length}명 일괄 거절 (사유: $reason)');
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    final pending = _items
        .where((a) => a.status == ApplicationStatus.applied)
        .toList()
      ..sort((a, b) => _matchScore(b).compareTo(_matchScore(a)));
    final hired =
        _items.where((a) => a.status == ApplicationStatus.hired).toList();
    final rejected =
        _items.where((a) => a.status == ApplicationStatus.rejected).toList();

    final avgRating = _items.isEmpty
        ? 0.0
        : _items
                .map((a) => Dummy.userById(a.workerId).rating)
                .reduce((a, b) => a + b) /
            _items.length;
    final avgDistance = _items.isEmpty
        ? 0.0
        : _items.map((a) => a.distanceKm).reduce((a, b) => a + b) /
            _items.length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('지원자 관리'),
          actions: [
            IconButton(
              tooltip: _selectMode ? '선택 취소' : '선택 모드',
              icon: Icon(
                  _selectMode ? Icons.close : Icons.checklist_rtl_outlined),
              onPressed: () {
                setState(() {
                  _selectMode = !_selectMode;
                  _selected.clear();
                });
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.brandDark,
            labelColor: AppColors.brandDark,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: '대기 ${pending.length}'),
              Tab(text: '채용 ${hired.length}/${job.personnel}'),
              Tab(text: '거절 ${rejected.length}'),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TagChip(
                          '${fmtDate(job.startAt)} · ${fmtTime(job.startAt)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      TagChip('평균 평점 ${avgRating.toStringAsFixed(1)}'),
                      TagChip('평균 거리 ${avgDistance.toStringAsFixed(1)}km'),
                      TagChip(
                          '매우 적합 ${pending.where((a) => _matchScore(a) >= 85).length}명',
                          primary: true),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // 자동 채용 자동화 카드 (대기 탭에서만 의미 있음)
            Container(
              color: AppColors.bg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _autoHire ? AppColors.brandDark : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 18,
                        color: _autoHire
                            ? AppColors.brandDark
                            : AppColors.textMuted),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('자동 채용',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800)),
                          Text('매칭 85점↑ · 거리 5km↓ · 평점 4.5↑ 인 지원자 자동 채용',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _autoHire,
                      activeColor: AppColors.brandDark,
                      onChanged: (v) {
                        setState(() => _autoHire = v);
                        _snack(v ? '자동 채용 ON (목업)' : '자동 채용 OFF');
                      },
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _list(pending, showActions: true),
                  _list(hired, showActions: false, statusLabel: '채용됨'),
                  _list(rejected, showActions: false, statusLabel: '거절됨'),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _selectMode && _selected.isNotEmpty
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${_selected.length}명 선택',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _openCompareDialog,
                        icon: const Icon(Icons.compare_arrows, size: 16),
                        label: const Text('비교'),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: _bulkReject,
                        child: const Text('일괄 거절'),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: _bulkHire,
                        child: const Text('일괄 채용'),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _list(List<JobApplication> apps,
      {required bool showActions, String? statusLabel}) {
    if (apps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 56, color: AppColors.textFaint),
              const SizedBox(height: 12),
              const Text('해당 상태의 지원자가 없어요',
                  style: TextStyle(color: AppColors.textMuted)),
              if (showActions) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/giver/job/${widget.jobId}/boost'),
                  icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                  label: const Text('홍보로 끌어올리기'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final a = apps[i];
        final w = Dummy.userById(a.workerId);
        final score = _matchScore(a);
        final isSelected = _selected.contains(a.id);
        return Card(
          child: InkWell(
            onTap: _selectMode && showActions
                ? () => setState(() {
                      if (isSelected) {
                        _selected.remove(a.id);
                      } else {
                        _selected.add(a.id);
                      }
                    })
                : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(color: AppColors.brandDark, width: 1.5)
                    : null,
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_selectMode && showActions)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppColors.brandDark
                                : AppColors.textFaint,
                          ),
                        ),
                      InkWell(
                        onTap: () => context.push('/profile/${w.id}'),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.brandSoft,
                          child: Icon(Icons.person, color: AppColors.brandDark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(w.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15)),
                                const SizedBox(width: 6),
                                if (showActions)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          _scoreColor(score).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$score · ${_scoreLabel(score)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _scoreColor(score),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFFFC400), size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  '${w.rating} · 리뷰 ${w.reviewCount}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textMuted),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '· ${a.distanceKm.toStringAsFixed(1)}km',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textFaint),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (statusLabel != null) TagChip(statusLabel),
                    ],
                  ),
                  if (w.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: w.tags.map((t) => TagChip('#$t')).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '지원 ${fmtRelative(a.appliedAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textFaint),
                  ),
                  if (showActions && !_selectMode) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _openTemplateSheet(a),
                            child:
                                const Icon(Icons.chat_bubble_outline, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _reject(a),
                            child: const Text('거절'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => _hire(a),
                            child: const Text('채용 확정'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Template {
  final String title;
  final String body;
  final IconData icon;
  const _Template(
      {required this.title, required this.body, required this.icon});
}

const _templates = <_Template>[
  _Template(
    title: '시간 변경 가능?',
    body: '안녕하세요! 시작 시간을 한 시간 늦출 수 있을지 여쭤봅니다.',
    icon: Icons.schedule,
  ),
  _Template(
    title: '주차 가능 여부',
    body: '근무지에 차량 주차가 가능할까요?',
    icon: Icons.local_parking,
  ),
  _Template(
    title: '면접 일정 조율',
    body: '간단한 면접을 진행하려고 합니다. 가능한 시간 알려주세요.',
    icon: Icons.event_available,
  ),
  _Template(
    title: '복장 안내',
    body: '근무 시 복장은 단정한 검정 상하의 부탁드려요.',
    icon: Icons.checkroom,
  ),
  _Template(
    title: '환영 메시지',
    body: '채용 확정 축하드려요! 첫 출근 시 도착하시면 매니저에게 인사 부탁드립니다.',
    icon: Icons.celebration_outlined,
  ),
];
