import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<int> _cancelledIds = {};

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('지원내역'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.brandDark,
            labelColor: AppColors.brandDark,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: '지원중'),
              Tab(text: '채용됨'),
              Tab(text: '완료'),
              Tab(text: '취소'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(ApplicationStatus.applied),
            _list(ApplicationStatus.hired),
            _list(ApplicationStatus.completed),
            _list(ApplicationStatus.cancelled),
          ],
        ),
      ),
    );
  }

  Widget _list(ApplicationStatus status) {
    final items = Dummy.applications.where((a) {
      if (status == ApplicationStatus.cancelled) {
        return _cancelledIds.contains(a.id);
      }
      if (_cancelledIds.contains(a.id)) return false;
      return a.status == status;
    }).toList();
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
              child: Row(
                children: [
                  _StatusBadge(status: status),
                  if (status == ApplicationStatus.applied)
                    IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showCancel(app.id),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCancel(int appId) {
    final reasons = const [
      '일정이 변경되었어요',
      '거리가 멀어요',
      '다른 공고에 지원했어요',
      '단순 변심',
      '기타',
    ];
    String? selected;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('지원 취소 사유',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  '잦은 취소는 신뢰 점수에 반영될 수 있어요.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                ...reasons.map((r) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(r),
                      value: r,
                      groupValue: selected,
                      activeColor: AppColors.brandDark,
                      onChanged: (v) => setSheet(() => selected = v),
                    )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('돌아가기'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger),
                        onPressed: selected == null
                            ? null
                            : () {
                                Navigator.pop(sheetCtx);
                                setState(() => _cancelledIds.add(appId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('지원이 취소되었습니다 (목업)')),
                                );
                              },
                        child: const Text('취소하기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
      case ApplicationStatus.cancelled:
        text = '취소';
        bg = AppColors.chipBg;
        fg = AppColors.textMuted;
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
