import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class GiverHomeScreen extends StatelessWidget {
  const GiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('내 공고'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/giver/job/create'),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.brandDark,
            labelColor: AppColors.brandDark,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: '진행중'),
              Tab(text: '완료'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _JobList(status: JobStatus.open),
            _JobList(status: JobStatus.done),
          ],
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  final JobStatus status;
  const _JobList({required this.status});

  @override
  Widget build(BuildContext context) {
    final jobs = Dummy.jobs.where((j) => j.status == status).toList();
    if (jobs.isEmpty) {
      return const EmptyState(
        icon: Icons.work_outline,
        message: '공고가 없어요',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final job = jobs[i];
        return Stack(
          children: [
            JobCard(
              job: job,
              onTap: status == JobStatus.open
                  ? () => context.push('/giver/job/${job.id}/applicants')
                  : () => context.push('/job/${job.id}'),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == JobStatus.open
                          ? AppColors.brandSoft
                          : AppColors.chipBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status == JobStatus.open
                          ? '지원자 ${job.hiredCount + 2}명'
                          : '완료',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: status == JobStatus.open
                            ? AppColors.brandDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (status == JobStatus.open)
                    PopupMenuButton<String>(
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      onSelected: (v) {
                        switch (v) {
                          case 'applicants':
                            context.push('/giver/job/${job.id}/applicants');
                            break;
                          case 'stats':
                            context.push('/giver/job/${job.id}/stats');
                            break;
                          case 'boost':
                            context.push('/giver/job/${job.id}/boost');
                            break;
                          case 'edit':
                            context.push('/giver/job/${job.id}/edit');
                            break;
                          case 'duplicate':
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('공고가 복제되었어요 (목업)')),
                            );
                            context.push('/giver/job/create');
                            break;
                          case 'view':
                            context.push('/job/${job.id}');
                            break;
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'applicants', child: Text('지원자 보기')),
                        PopupMenuItem(value: 'stats', child: Text('통계 보기')),
                        PopupMenuItem(
                            value: 'boost', child: Text('끌어올리기/광고')),
                        PopupMenuItem(value: 'edit', child: Text('수정/마감')),
                        PopupMenuItem(
                            value: 'duplicate', child: Text('공고 복제')),
                        PopupMenuItem(value: 'view', child: Text('공고 상세')),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
