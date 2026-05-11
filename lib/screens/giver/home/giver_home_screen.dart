import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/job_repository.dart';
import '../../../models/api_models/job.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/job_status_toggle.dart' show JobStatus;
import '../../../widgets/shared.dart';

class GiverHomeScreen extends StatefulWidget {
  final JobRepository? jobRepository;
  const GiverHomeScreen({super.key, this.jobRepository});

  @override
  State<GiverHomeScreen> createState() => _GiverHomeScreenState();
}

class _GiverHomeScreenState extends State<GiverHomeScreen>
    with SingleTickerProviderStateMixin {
  late final JobRepository _repo;
  late final TabController _tab;
  late Future<List<Job>> _future;

  // index 0 = 전체 (no filter), 1 = active, 2 = paused, 3 = closed
  static const List<String?> _statusByIndex = [
    null,
    JobStatus.active,
    JobStatus.paused,
    JobStatus.closed,
  ];

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? JobRepository.fromApi();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(_onTabChange);
    _future = _repo.listMine();
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChange);
    _tab.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tab.indexIsChanging) return;
    final status = _statusByIndex[_tab.index];
    final newFuture = _repo.listMine(status: status);
    if (!mounted) return;
    setState(() {
      _future = newFuture;
    });
  }

  /// F R6 CR-M1: 현재 탭 기준 listMine 재요청. RefreshIndicator의 spinner는
  /// 반환 Future가 완료될 때까지 유지되므로 catchError로 끝까지 끌어 errors
  /// 발생 시에도 spinner를 닫는다. snap.hasError 분기는 _future를 통해 다시
  /// 그려진다.
  Future<void> _refresh() async {
    final status = _statusByIndex[_tab.index];
    final future = _repo.listMine(status: status);
    if (!mounted) return;
    setState(() {
      _future = future;
    });
    await future.catchError((_) => <Job>[]);
  }

  /// F R6 CR-M1: push().then(refresh) 헬퍼 — FAB / Card tap / PopupMenu edit
  /// 공통. context.push는 stack에 push되어 pop 시 then() 후속이 동작 (go는
  /// stack replace라 then() 불가).
  Future<void> _pushAndRefresh(String route) async {
    await context.push(route);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 공고'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.brandDark,
          labelColor: AppColors.brandDark,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '모집중'),
            Tab(text: '일시중지'),
            Tab(text: '마감'),
          ],
        ),
      ),
      body: FutureBuilder<List<Job>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            // F R6 UX-S2: raw snap.error 노출 제거 → 한글 안전 fallback.
            // F R6 CR-M1: 에러 화면도 RefreshIndicator로 wrap — 사용자가 pull
            // 하여 재시도 가능.
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      '연결이 불안정합니다. 잠시 후 다시 시도해주세요',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
          final jobs = snap.data ?? const <Job>[];
          if (jobs.isEmpty) {
            // F R6 CR-M1: empty state도 pull 가능 — ListView로 wrap.
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.work_outline,
                    message: '공고가 없어요',
                  ),
                ],
              ),
            );
          }
          // F R6 CR-M1: 정상 list도 RefreshIndicator로 wrap. _GiverJobCard에
          // onReturn 콜백 전달 — Card/PopupMenu tap 후 자동 refresh.
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final j = jobs[i];
                final coverUrl =
                    j.photos.isNotEmpty ? j.photos[0].signedUrl : null;
                return _GiverJobCard(
                  job: j,
                  coverUrl: coverUrl,
                  onReturn: _refresh,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        // F R6 CR-M1: push().then(refresh) — JobCreate가 등록 후 context.pop()
        // 으로 복귀 시 자동 refresh로 stale data 회피.
        onPressed: () => _pushAndRefresh('/giver/job/create'),
        icon: const Icon(Icons.add),
        label: const Text('공고 등록'),
      ),
    );
  }
}

class _GiverJobCard extends StatelessWidget {
  final Job job;
  final String? coverUrl;
  // F R6 CR-M1: 부모(GiverHome) refresh 콜백 — push 후 복귀 시 stale data 회피.
  final VoidCallback? onReturn;
  const _GiverJobCard({
    required this.job,
    required this.coverUrl,
    this.onReturn,
  });

  Future<void> _pushAndReturn(BuildContext context, String route) async {
    await context.push(route);
    onReturn?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _pushAndReturn(context, '/giver/job/${job.id}/edit'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            const Icon(Icons.image_outlined, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.wageWon}원 · ${job.locationAddress}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _StatusBadge(status: job.status),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                iconSize: 20,
                padding: EdgeInsets.zero,
                onSelected: (v) {
                  switch (v) {
                    case 'applicants':
                      _pushAndReturn(
                          context, '/giver/job/${job.id}/applicants');
                      break;
                    case 'edit':
                      _pushAndReturn(context, '/giver/job/${job.id}/edit');
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'applicants', child: Text('지원자')),
                  PopupMenuItem(value: 'edit', child: Text('수정')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (status) {
      case JobStatus.active:
        label = '모집중';
        bg = AppColors.brandSoft;
        fg = AppColors.brandDark;
        break;
      case JobStatus.paused:
        label = '일시중지';
        bg = AppColors.chipBg;
        fg = AppColors.textMuted;
        break;
      case JobStatus.closed:
        label = '마감';
        bg = AppColors.chipBg;
        fg = AppColors.textMuted;
        break;
      default:
        label = status;
        bg = AppColors.chipBg;
        fg = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
