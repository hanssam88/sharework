import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/job_repository.dart';
import '../../models/api_models/job.dart' as api;

class SearchScreen extends StatefulWidget {
  final JobRepository? jobRepository;
  const SearchScreen({super.key, this.jobRepository});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctl = TextEditingController();
  late final JobRepository _repo;
  Future<({List<api.Job> items, int total})>? _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? JobRepository.fromApi();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _runSearch() {
    final q = _ctl.text.trim();
    if (q.isEmpty) return;
    final future = _repo.listJobs(q: q);
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('search-field'),
          controller: _ctl,
          decoration: const InputDecoration(hintText: '검색어'),
          onSubmitted: (_) => _runSearch(),
        ),
        actions: [
          IconButton(
            key: const Key('search-submit'),
            icon: const Icon(Icons.search),
            onPressed: _runSearch,
          ),
        ],
      ),
      body: _future == null
          ? const Center(child: Text('검색어를 입력하세요'))
          : FutureBuilder<({List<api.Job> items, int total})>(
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
                  return const Center(child: Text('검색 결과가 없어요'));
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
