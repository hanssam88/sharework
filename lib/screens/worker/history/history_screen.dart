import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('지원내역'),
          bottom: const TabBar(
            indicatorColor: AppColors.brandDark,
            labelColor: AppColors.brandDark,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: '지원중'),
              Tab(text: '채용됨'),
              Tab(text: '완료'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HistoryList(status: ApplicationStatus.applied),
            _HistoryList(status: ApplicationStatus.hired),
            _HistoryList(status: ApplicationStatus.completed),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final ApplicationStatus status;
  const _HistoryList({required this.status});

  @override
  Widget build(BuildContext context) {
    final items = Dummy.applications.where((a) => a.status == status).toList();
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        message: '아직 내역이 없어요',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final app = items[i];
        final job = Dummy.jobById(app.jobId);
        return Stack(
          children: [
            JobCard(
              job: job,
              distanceKm: app.distanceKm,
              onTap: () => context.push('/job/${job.id}'),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _StatusBadge(status: status),
            ),
          ],
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ApplicationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late String text;
    late Color bg;
    late Color fg;
    switch (status) {
      case ApplicationStatus.applied:
        text = '지원중';
        bg = const Color(0xFFEEF4FF);
        fg = const Color(0xFF2F66E2);
        break;
      case ApplicationStatus.hired:
        text = '채용됨';
        bg = AppColors.brandSoft;
        fg = AppColors.brandDark;
        break;
      case ApplicationStatus.completed:
        text = '완료';
        bg = const Color(0xFFE8F8EE);
        fg = const Color(0xFF1F8E48);
        break;
      case ApplicationStatus.rejected:
        text = '미선정';
        bg = const Color(0xFFFDECEC);
        fg = const Color(0xFFC53030);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
