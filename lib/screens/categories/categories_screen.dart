import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/category_repository.dart';
import '../../models/api_models/job_category.dart' as api;

class CategoriesScreen extends StatefulWidget {
  final CategoryRepository? categoryRepository;
  const CategoriesScreen({super.key, this.categoryRepository});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final CategoryRepository _repo;
  late Future<List<api.JobCategory>> _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.categoryRepository ?? CategoryRepository.fromApi();
    _future = _repo.list();
  }

  void _retry() {
    final future = _repo.list();
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('카테고리')),
      body: FutureBuilder<List<api.JobCategory>>(
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
          final items = snap.data ?? const <api.JobCategory>[];
          if (items.isEmpty) {
            return const Center(child: Text('카테고리가 비어 있어요'));
          }
          return GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: items
                .map((c) => InkWell(
                      onTap: () =>
                          context.push('/categories/${c.id}', extra: c.name),
                      child: Card(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (c.emoji != null)
                                  Text(c.emoji!,
                                      style: const TextStyle(fontSize: 28)),
                                const SizedBox(height: 6),
                                Text(c.name, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}
