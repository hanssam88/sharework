import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/job_repository.dart';
import '../../models/api_models/job.dart' as api;
import '../../theme/app_theme.dart';
import '../../widgets/api_job_card.dart';
import '../../widgets/shared.dart' show EmptyState;

enum _Sort { latest, wage }

class CategoryJobsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final JobRepository? jobRepository;
  const CategoryJobsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.jobRepository,
  });
  @override
  State<CategoryJobsScreen> createState() => _CategoryJobsScreenState();
}

class _CategoryJobsScreenState extends State<CategoryJobsScreen> {
  late final JobRepository _repo;
  late Future<({List<api.Job> items, int total})> _future;

  // Mockup default was '거리순'; dropped here because the API exposes no
  // distance data (policy (a)). Default falls back to 최신순.
  _Sort _sort = _Sort.latest;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? JobRepository.fromApi();
    _future = _repo.listJobs(category: widget.categoryId);
  }

  List<api.Job> _sorted(List<api.Job> items) {
    final list = [...items];
    switch (_sort) {
      case _Sort.latest:
        list.sort((a, b) =>
            DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
      case _Sort.wage:
        list.sort((a, b) => b.wageWon.compareTo(a.wageWon));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: '이 카테고리 알림 받기',
            onPressed: () => context.push('/me/saved-searches/new'),
          ),
        ],
      ),
      body: FutureBuilder<({List<api.Job> items, int total})>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('연결이 불안정합니다'));
          }
          final items = snap.data?.items ?? const <api.Job>[];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.work_off_outlined,
              message: '아직 이 카테고리에 공고가 없어요',
            );
          }
          final sorted = _sorted(items);
          return Column(
            children: [
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // listJobs is paginated (limit 20); show the count of jobs
                    // actually rendered, matching the mockup's `jobs.length`.
                    Text('${sorted.length}건',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    DropdownButton<_Sort>(
                      value: _sort,
                      underline: const SizedBox(),
                      iconSize: 18,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text,
                          fontWeight: FontWeight.w600),
                      onChanged: (v) {
                        if (v != null) setState(() => _sort = v);
                      },
                      items: const [
                        // '거리순' omitted — backend does not expose distance.
                        DropdownMenuItem(
                            value: _Sort.latest, child: Text('최신순')),
                        DropdownMenuItem(value: _Sort.wage, child: Text('시급순')),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final j = sorted[i];
                    return ApiJobCard(
                      job: j,
                      onTap: () => context.push('/job/${j.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
