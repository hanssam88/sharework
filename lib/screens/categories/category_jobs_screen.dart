import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class CategoryJobsScreen extends StatefulWidget {
  final JobCategory category;
  const CategoryJobsScreen({super.key, required this.category});

  @override
  State<CategoryJobsScreen> createState() => _CategoryJobsScreenState();
}

class _CategoryJobsScreenState extends State<CategoryJobsScreen> {
  String _sort = '거리순';

  @override
  Widget build(BuildContext context) {
    final jobs = Dummy.jobs
        .where((j) =>
            j.category == widget.category && j.status == JobStatus.open)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: '이 카테고리 알림 받기',
            onPressed: () => context.push('/me/saved-searches/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('${jobs.length}건',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const Spacer(),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox(),
                  iconSize: 18,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.text,
                      fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(value: '거리순', child: Text('거리순')),
                    DropdownMenuItem(value: '시급순', child: Text('시급순')),
                    DropdownMenuItem(value: '최신순', child: Text('최신순')),
                  ],
                  onChanged: (v) => setState(() => _sort = v ?? _sort),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: jobs.isEmpty
                ? const EmptyState(
                    icon: Icons.work_off_outlined,
                    message: '아직 이 카테고리에 공고가 없어요',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => JobCard(
                      job: jobs[i],
                      distanceKm: 1.0 + i * 0.8,
                      onTap: () => context.push('/job/${jobs[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
