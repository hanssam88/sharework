import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class ScoutDetailScreen extends StatefulWidget {
  final int scoutId;
  const ScoutDetailScreen({super.key, required this.scoutId});

  @override
  State<ScoutDetailScreen> createState() => _ScoutDetailScreenState();
}

class _ScoutDetailScreenState extends State<ScoutDetailScreen> {
  late Scout _scout;

  @override
  void initState() {
    super.initState();
    _scout = Dummy.scouts.firstWhere(
      (s) => s.id == widget.scoutId,
      orElse: () => Dummy.scouts.first,
    );
  }

  void _accept() {
    setState(() {
      _scout = Scout(
        id: _scout.id,
        fromGiverId: _scout.fromGiverId,
        fromGiverName: _scout.fromGiverName,
        toWorkerId: _scout.toWorkerId,
        toWorkerName: _scout.toWorkerName,
        jobId: _scout.jobId,
        jobTitle: _scout.jobTitle,
        message: _scout.message,
        status: ScoutStatus.accepted,
        createdAt: _scout.createdAt,
        offerHourly: _scout.offerHourly,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('수락했어요. 채팅방에서 세부 일정을 조율해보세요 (목업)')),
    );
  }

  void _decline() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('거절 사유',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...['일정이 안 맞아요', '거리가 멀어요', '조건이 맞지 않아요', '기타']
                  .map((r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(r),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          setState(() {
                            _scout = Scout(
                              id: _scout.id,
                              fromGiverId: _scout.fromGiverId,
                              fromGiverName: _scout.fromGiverName,
                              toWorkerId: _scout.toWorkerId,
                              toWorkerName: _scout.toWorkerName,
                              jobId: _scout.jobId,
                              jobTitle: _scout.jobTitle,
                              message: _scout.message,
                              status: ScoutStatus.declined,
                              createdAt: _scout.createdAt,
                              offerHourly: _scout.offerHourly,
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('거절되었습니다 · 사유: $r')),
                          );
                        },
                      )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _scout.status == ScoutStatus.sent;
    return Scaffold(
      appBar: AppBar(
        title: const Text('스카우트 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: '신고',
            onPressed: () =>
                context.push('/report/scout/${_scout.id}'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.brandSoft,
                      child: Icon(Icons.business,
                          color: AppColors.brandDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_scout.fromGiverName,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          Text(fmtRelative(_scout.createdAt),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textFaint)),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/profile/${_scout.fromGiverId}'),
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: const Text('프로필'),
                    ),
                  ],
                ),
                if (_scout.jobId != null) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => context.push('/job/${_scout.jobId}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.work_outline,
                              color: AppColors.brandDark),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _scout.jobTitle ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_scout.offerHourly != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          color: AppColors.brandDark),
                      const SizedBox(width: 6),
                      Text(
                        '제안 시급 ${fmtMoney(_scout.offerHourly!)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '메시지'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Text(
              _scout.message,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: isPending
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _decline,
                        child: const Text('거절'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _accept,
                        child: const Text('수락하기'),
                      ),
                    ),
                  ],
                )
              : OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(
                    _scout.status == ScoutStatus.accepted
                        ? '대화 이어가기'
                        : '닫기',
                  ),
                ),
        ),
      ),
    );
  }
}
