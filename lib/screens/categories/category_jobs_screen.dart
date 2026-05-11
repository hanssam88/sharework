import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/job_repository.dart';
import '../../models/api_models/job.dart' as api;

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

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? JobRepository.fromApi();
    _future = _repo.listJobs(category: widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
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
            return const Center(child: Text('해당 카테고리에 공고가 없어요'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final j = items[i];
              return ListTile(
                title: Text(j.title),
                subtitle: Text(
                    '${j.giver?.name ?? "정보 없음"} · ${j.wageWon}원 · ${j.locationAddress}'),
                onTap: () => context.push('/job/${j.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
