import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';
import 'dispute_list_screen.dart';

class DisputeDetailScreen extends StatelessWidget {
  final int disputeId;
  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  Widget build(BuildContext context) {
    final d = Dummy.disputes.firstWhere(
      (x) => x.id == disputeId,
      orElse: () => Dummy.disputes.first,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('분쟁 조정 상세')),
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
                    Expanded(
                      child: Text(d.jobTitle,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    StageBadge(stage: d.stage),
                  ],
                ),
                const SizedBox(height: 6),
                Text('상대방 ${d.otherPartyName}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: [
                    TagChip(d.reason.label, primary: true),
                    TagChip('신청일 ${fmtRelative(d.createdAt)}'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '신청 내용'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(d.description,
                style: const TextStyle(fontSize: 14, height: 1.6)),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '진행 상황'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: _Timeline(events: d.timeline, currentStage: d.stage),
          ),
          if (d.stage == DisputeStage.mediation) ...[
            const Divider(thickness: 8, color: AppColors.bg),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('제시된 조정안',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text(
                      '구인자가 차액 6,000원을 추가 정산하는 것으로 종결합니다.',
                      style: TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: d.stage == DisputeStage.mediation
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이의 제기 접수 (목업)')),
                        ),
                        child: const Text('이의 제기'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('조정안에 동의했어요 (목업)')),
                        ),
                        child: const Text('동의'),
                      ),
                    ),
                  ],
                )
              : OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.headset_mic_outlined),
                  label: const Text('담당자 문의'),
                ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<DisputeEvent> events;
  final DisputeStage currentStage;
  const _Timeline({required this.events, required this.currentStage});

  static const _stages = [
    DisputeStage.received,
    DisputeStage.reviewing,
    DisputeStage.mediation,
    DisputeStage.resolved,
  ];

  static String _label(DisputeStage s) {
    switch (s) {
      case DisputeStage.received:
        return '접수';
      case DisputeStage.reviewing:
        return '검토';
      case DisputeStage.mediation:
        return '조정';
      case DisputeStage.resolved:
        return '종결';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = _stages.indexOf(currentStage);
    return Column(
      children: List.generate(_stages.length, (i) {
        final stage = _stages[i];
        final done = i <= currentIdx;
        final ev = events.where((e) => e.stage == stage).toList();
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: done ? AppColors.brandDark : AppColors.chipBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.circle_outlined,
                      size: 14,
                      color:
                          done ? Colors.white : AppColors.textFaint,
                    ),
                  ),
                  if (i < _stages.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: done
                            ? AppColors.brandDark
                            : AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_label(stage),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: done
                                ? AppColors.text
                                : AppColors.textFaint,
                          )),
                      if (ev.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(ev.first.description,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                height: 1.5)),
                        const SizedBox(height: 2),
                        Text(fmtRelative(ev.first.at),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textFaint)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
