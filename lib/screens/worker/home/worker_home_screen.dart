import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/job_repository.dart';
import '../../../models/api_models/job.dart' as api;
import '../../../theme/app_theme.dart';

class WorkerHomeScreen extends StatefulWidget {
  final JobRepository? jobRepository;
  const WorkerHomeScreen({super.key, this.jobRepository});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  late final JobRepository _repo;
  late Future<({List<api.Job> items, int total})> _future;

  // M1: applications API 미존재, M3 연결 (U3)
  static const int _appliedCount = 0;
  static const int _hiredCount = 0;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? JobRepository.fromApi();
    _future = _repo.listJobs();
  }

  void _retry() {
    setState(() => _future = _repo.listJobs());
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          const _MapPlaceholder(),
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: const _SearchBar(),
            ),
          ),
          Positioned(
            top: topPad + 70,
            left: 16,
            right: 16,
            child: Row(
              children: const [
                _StatusPill(
                  key: Key('status-pill-applied'),
                  label: '지원중',
                  count: _appliedCount,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                _StatusPill(
                  key: Key('status-pill-hired'),
                  label: '채용됨',
                  count: _hiredCount,
                  color: Colors.green,
                ),
              ],
            ),
          ),
          Positioned(
            top: topPad + 130,
            left: 0,
            right: 0,
            bottom: 0,
            child: FutureBuilder<({List<api.Job> items, int total})>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('연결이 불안정합니다'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                            onPressed: _retry, child: const Text('다시 시도')),
                      ],
                    ),
                  );
                }
                final items = snap.data?.items ?? const <api.Job>[];
                if (items.isEmpty) {
                  return const Center(child: Text('근처 공고가 없어요'));
                }
                return ListView.builder(
                  itemCount: items.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '주변 일자리 ${items.length}건',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      );
                    }
                    final job = items[i - 1];
                    final coverUrl =
                        job.photos.isNotEmpty ? job.photos[0].signedUrl : null;
                    return _JobTile(
                      job: job,
                      coverUrl: coverUrl,
                      onTap: () => context.push('/job/${job.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final api.Job job;
  final String? coverUrl;
  final VoidCallback onTap;
  const _JobTile(
      {required this.job, required this.coverUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: ListTile(
        leading: SizedBox(
          width: 56,
          height: 56,
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
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
        ),
        title: Text(job.title),
        subtitle: Text(
            '${job.giver?.name ?? "정보 없음"} · ${job.wageWon}원 · ${job.locationAddress}'),
        onTap: onTap,
      ),
    );
  }
}

// ── Preserved private widgets ──────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3F2F5), Color(0xFFD2EFEC)],
        ),
      ),
      child: Stack(
        children: [
          // grid
          ...List.generate(
              20,
              (i) => Positioned(
                    left: 0,
                    right: 0,
                    top: i * 50.0,
                    child: Container(
                        height: 1, color: Colors.white.withOpacity(0.5)),
                  )),
          ...List.generate(
              20,
              (i) => Positioned(
                    top: 0,
                    bottom: 0,
                    left: i * 50.0,
                    child: Container(
                        width: 1, color: Colors.white.withOpacity(0.5)),
                  )),
          // fake markers
          const Positioned(
            top: 200,
            left: 80,
            child: _Marker(label: '1.2만'),
          ),
          const Positioned(
            top: 280,
            left: 200,
            child: _Marker(label: '5건'),
          ),
          const Positioned(
            top: 350,
            right: 60,
            child: _Marker(label: '10만'),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: AppColors.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '지역·키워드로 검색',
              style: TextStyle(color: AppColors.textFaint),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final String label;
  const _Marker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusPill(
      {super.key,
      required this.label,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(width: 4),
          Text('$count건',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
