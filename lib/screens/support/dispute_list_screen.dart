import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class DisputeListScreen extends StatelessWidget {
  const DisputeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = [...Dummy.disputes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(
        title: const Text('분쟁 조정'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/support/dispute/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('새 신청'),
          ),
        ],
      ),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.gavel_outlined,
              message: '진행 중인 분쟁 조정이 없어요',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final d = list[i];
                return _DisputeCard(
                  dispute: d,
                  onTap: () => context.push('/support/dispute/${d.id}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/support/dispute/new'),
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('분쟁 조정 신청'),
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final Dispute dispute;
  final VoidCallback onTap;
  const _DisputeCard({required this.dispute, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(dispute.jobTitle,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                  StageBadge(stage: dispute.stage),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '상대방 ${dispute.otherPartyName} · ${dispute.reason.label}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                dispute.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 6),
              Text('신청일 ${fmtRelative(dispute.createdAt)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textFaint)),
            ],
          ),
        ),
      ),
    );
  }
}

class StageBadge extends StatelessWidget {
  final DisputeStage stage;
  const StageBadge({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    late String text;
    late Color bg;
    late Color fg;
    switch (stage) {
      case DisputeStage.received:
        text = '접수';
        bg = const Color(0xFFEEF4FF);
        fg = const Color(0xFF2F66E2);
        break;
      case DisputeStage.reviewing:
        text = '검토중';
        bg = const Color(0xFFFFF6E5);
        fg = const Color(0xFFB45309);
        break;
      case DisputeStage.mediation:
        text = '조정중';
        bg = AppColors.brandSoft;
        fg = AppColors.brandDark;
        break;
      case DisputeStage.resolved:
        text = '종결';
        bg = const Color(0xFFE8F8EE);
        fg = const Color(0xFF1F8E48);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
