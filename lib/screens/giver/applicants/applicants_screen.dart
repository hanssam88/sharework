import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/api_errors.dart';
import '../../../data/repositories/application_repository.dart';
import '../../../models/api_models/application.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

/// Giver: 자기 공고 지원자 관리 화면.
/// BFF endpoints:
///   GET   /api/jobs/:id/applications        — list (cursor pagination, view 분기)
///   PATCH /api/jobs/:id/applications/:id    — Giver decision (hired | rejected)
class ApplicantsScreen extends StatefulWidget {
  final String jobId;
  final ApplicationRepository? repository; // for testing

  const ApplicantsScreen({
    super.key,
    required this.jobId,
    this.repository,
  });

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  late final ApplicationRepository _repo;
  _AggregatedView? _view;
  Object? _error;
  bool _loading = true;

  // Optimistic local override of status — replaced when hired list refreshes
  // with the contact view (phone) for that row.
  final Map<String, Application> _overrides = {};
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApplicationRepository.fromApi();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 두 view를 합쳐서 탭별로 표시. status 미지정 GET이 safe view.
      // hired만 contact view(phone 포함)로 받기 위해 별도 호출.
      final all = await _repo.listForJob(widget.jobId, limit: 50);
      ApplicationListPage hired;
      try {
        hired =
            await _repo.listForJob(widget.jobId, status: 'hired', limit: 50);
      } catch (_) {
        // hired 실패해도 일반 목록은 표시. counts는 all에서 보강.
        hired = ApplicationListPage(
          items: const [],
          hasMore: false,
          nextCursor: null,
          counts: all.counts,
        );
      }
      if (!mounted) return;
      setState(() {
        _view = _AggregatedView(all: all, hired: hired);
        _overrides.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _refresh() => _load();

  Application _resolved(Application a) => _overrides[a.id] ?? a;

  /// Refetch hired (contact) view after a successful 'hired' decision so the
  /// just-hired row exposes worker.phone instead of the safe-view stub.
  Future<void> _refreshHired() async {
    try {
      final fresh =
          await _repo.listForJob(widget.jobId, status: 'hired', limit: 50);
      if (!mounted || _view == null) return;
      setState(() {
        _view = _AggregatedView(all: _view!.all, hired: fresh);
        // Drop overrides for ids now present in the fresh contact view —
        // the server row supersedes the optimistic stub.
        final freshIds = fresh.items.map((a) => a.id).toSet();
        _overrides.removeWhere((id, _) => freshIds.contains(id));
      });
    } catch (_) {
      // Soft-fail: keep optimistic override; user can hit refresh button.
    }
  }

  Future<void> _decide(Application app, String status) async {
    if (_busy.contains(app.id)) return;
    setState(() => _busy.add(app.id));
    try {
      final newStatus = await _repo.decide(
        widget.jobId,
        app.id,
        status: status,
      );
      // Optimistic local update for instant tab move.
      setState(() {
        _overrides[app.id] = app.copyWith(status: newStatus);
      });
      // Hired needs contact-view phone — fire-and-forget refetch.
      if (newStatus == 'hired') {
        unawaited(_refreshHired());
      }
      _snack(status == 'hired' ? '채용 확정' : '거절 처리됨');
    } on DioException catch (e) {
      final err = e.error;
      if (err is ApiError) {
        _snack(_friendlyError(err));
      } else {
        _snack('네트워크 오류가 발생했어요');
      }
    } finally {
      if (mounted) setState(() => _busy.remove(app.id));
    }
  }

  String _friendlyError(ApiError err) {
    switch (err.code) {
      case ApiErrorCode.authRequired:
      case ApiErrorCode.authInvalid:
        return '로그인이 만료되었어요. 다시 로그인 해주세요';
      case ApiErrorCode.rateLimited:
        return '요청이 너무 많아요. 잠시 후 다시 시도해주세요';
      case ApiErrorCode.forbidden:
        return '권한이 없습니다';
      case ApiErrorCode.notFound:
        return '지원 내역을 찾을 수 없어요';
      default:
        return '문제가 발생했어요 (${err.message})';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 거절 사유 시트. BFF는 reason을 무시(server-set='giver_rejected')하지만
  /// 사용자가 사유를 확인·선택하는 UX는 유지. 향후 client reason 수집은
  /// BFF 확장 또는 별도 분석 endpoint 작업.
  void _showRejectReasonSheet(Application app) {
    String? selected;
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
                const Text(
                  '거절 사유',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  '선택한 사유는 워커에게 공개되지 않습니다.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                ...const [
                  '일정이 맞지 않음',
                  '거리가 멀음',
                  '경험·자격 부족',
                  '이미 인원이 다 찼음',
                  '단순 변심',
                  '기타',
                ].map(
                  (r) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: r,
                    groupValue: selected,
                    activeColor: AppColors.brandDark,
                    title: Text(r),
                    onChanged: (v) => setSheet(() => selected = v),
                  ),
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
                          backgroundColor: AppColors.danger,
                        ),
                        onPressed: selected == null
                            ? null
                            : () {
                                Navigator.pop(sheetCtx);
                                _decide(app, 'rejected');
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _scaffoldShell(
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      final err = _error;
      final msg = err is DioException && err.error is ApiError
          ? _friendlyError(err.error as ApiError)
          : '지원자 목록을 불러올 수 없었어요';
      return _scaffoldShell(child: _errorView(msg));
    }
    final view = _view!;

    // hired view는 contact(phone) 포함 — 우선 사용. 동일 id가 all에도 있으면 hired 우선.
    final hiredFromContact = view.hired.items.map(_resolved).toList();
    final hiredIds = hiredFromContact.map((a) => a.id).toSet();
    final allOverridden = view.all.items.map(_resolved).toList();

    final pending = allOverridden.where((a) => a.status == 'applied').toList();
    final hired = [
      ...hiredFromContact,
      ...allOverridden.where(
        (a) => a.status == 'hired' && !hiredIds.contains(a.id),
      ),
    ];
    final rejected = allOverridden.where((a) => a.status == 'rejected').toList();

    // BFF authoritative counts (rejected는 counts에 없으니 length로 fallback).
    final pendingCount = view.all.counts.applied;
    final hiredCount = view.hired.counts.hired;
    final hasMore = view.all.hasMore || view.hired.hasMore;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('지원자 관리'),
          actions: [
            IconButton(
              tooltip: '새로고침',
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.brandDark,
            labelColor: AppColors.brandDark,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: '대기 $pendingCount'),
              Tab(text: '채용 $hiredCount'),
              Tab(text: '거절 ${rejected.length}'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (hasMore)
              Container(
                width: double.infinity,
                color: AppColors.bg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        '일부 지원자만 표시되고 있어요. 새로고침을 눌러 최신 상태를 확인하세요.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _refresh,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('새로고침'),
                    ),
                  ],
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
      ),
    );
  }

  Widget _scaffoldShell({required Widget child}) => Scaffold(
        appBar: AppBar(title: const Text('지원자 관리')),
        body: child,
      );

  Widget _errorView(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: AppColors.textFaint,
              ),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );

  Widget _list(
    List<Application> apps, {
    required bool showActions,
    String? statusLabel,
  }) {
    if (apps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: AppColors.textFaint),
              SizedBox(height: 12),
              Text(
                '해당 상태의 지원자가 없어요',
                style: TextStyle(color: AppColors.textMuted),
              ),
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
        final isBusy = _busy.contains(a.id);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.brandSoft,
                      child: Icon(Icons.person, color: AppColors.brandDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.worker.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          if (a.worker.phone != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 12,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  a.worker.phone!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (statusLabel != null) TagChip(statusLabel),
                  ],
                ),
                if ((a.coverNote ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a.coverNote!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  _appliedAtLabel(a.appliedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textFaint,
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isBusy
                              ? null
                              : () => _showRejectReasonSheet(a),
                          child: const Text('거절'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: isBusy
                              ? null
                              : () => _decide(a, 'hired'),
                          child: isBusy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('채용 확정'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

String _appliedAtLabel(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '지원';
  return '지원 ${fmtRelative(dt)}';
}

class _AggregatedView {
  final ApplicationListPage all;
  final ApplicationListPage hired;
  _AggregatedView({required this.all, required this.hired});
}
