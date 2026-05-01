import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class ApplicantsScreen extends StatefulWidget {
  final int jobId;
  const ApplicantsScreen({super.key, required this.jobId});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  late List<JobApplication> _items;

  @override
  void initState() {
    super.initState();
    _items = Dummy.applicantsForJob(widget.jobId);
  }

  void _hire(JobApplication app) {
    setState(() {
      final idx = _items.indexWhere((a) => a.id == app.id);
      _items[idx] = JobApplication(
        id: app.id,
        jobId: app.jobId,
        workerId: app.workerId,
        status: ApplicationStatus.hired,
        appliedAt: app.appliedAt,
        distanceKm: app.distanceKm,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('채용 확정 (목업)')),
    );
  }

  void _reject(JobApplication app) {
    setState(() {
      final idx = _items.indexWhere((a) => a.id == app.id);
      _items[idx] = JobApplication(
        id: app.id,
        jobId: app.jobId,
        workerId: app.workerId,
        status: ApplicationStatus.rejected,
        appliedAt: app.appliedAt,
        distanceKm: app.distanceKm,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    final pending = _items
        .where((a) => a.status == ApplicationStatus.applied)
        .toList();
    final hired =
        _items.where((a) => a.status == ApplicationStatus.hired).toList();
    final rejected =
        _items.where((a) => a.status == ApplicationStatus.rejected).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('지원자 관리'),
          bottom: TabBar(
            indicatorColor: AppColors.brandDark,
            labelColor: AppColors.brandDark,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: '대기 ${pending.length}'),
              Tab(text: '채용 ${hired.length}/${job.personnel}'),
              Tab(text: '거절 ${rejected.length}'),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TagChip(
                      '${fmtDate(job.startAt)} · ${fmtTime(job.startAt)}'),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
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

  Widget _list(List<JobApplication> apps,
      {required bool showActions, String? statusLabel}) {
    if (apps.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        message: '해당 상태의 지원자가 없어요',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final a = apps[i];
        final w = Dummy.userById(a.workerId);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => context.push('/profile/${w.id}'),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.brandSoft,
                        child: Icon(Icons.person,
                            color: AppColors.brandDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFFFC400), size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  '${w.rating} · 리뷰 ${w.reviewCount}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '· ${a.distanceKm.toStringAsFixed(1)}km',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textFaint),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (statusLabel != null) TagChip(statusLabel),
                    ],
                  ),
                ),
                if (w.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: w.tags.map((t) => TagChip('#$t')).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '지원 ${fmtRelative(a.appliedAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textFaint),
                ),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {},
                          child: const Icon(Icons.chat_bubble_outline,
                              size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reject(a),
                          child: const Text('거절'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () => _hire(a),
                          child: const Text('채용 확정'),
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
