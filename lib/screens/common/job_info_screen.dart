import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class JobInfoScreen extends StatelessWidget {
  final int jobId;
  const JobInfoScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(jobId);
    final isHired = Dummy.applications.any((a) =>
        a.jobId == jobId &&
        a.workerId == Dummy.me.id &&
        a.status == ApplicationStatus.hired);
    return Scaffold(
      appBar: AppBar(
        title: const Text('공고 상세'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.bookmark_border), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    if (job.sameDayPayment)
                      const TagChip('당일지급', primary: true),
                    if (job.foodProvided) const TagChip('식사제공'),
                    if (job.extraPay) const TagChip('교통비지원'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(job.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                _InfoRow(
                    icon: Icons.location_on_outlined, text: job.address),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.access_time,
                  text:
                      '${fmtDate(job.startAt)} · ${fmtTime(job.startAt)} ~ ${fmtTime(job.endAt)}',
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  text: '${job.payType} ${fmtMoney(job.pay)}',
                  highlight: true,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                    icon: Icons.people_outline,
                    text: '${job.hiredCount}/${job.personnel}명 모집중'),
              ],
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          // giver
          InkWell(
            onTap: () => context.push('/profile/${job.giverId}'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.brandSoft,
                    child: Icon(Icons.business, color: AppColors.brandDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.giverName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        const Row(
                          children: [
                            Icon(Icons.star,
                                color: Color(0xFFFFC400), size: 14),
                            SizedBox(width: 2),
                            Text('4.9 · 리뷰 128',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textFaint),
                ],
              ),
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '상세 설명'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(job.description,
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
          if (job.tags.isNotEmpty) ...[
            const Divider(thickness: 8, color: AppColors.bg),
            const SectionHeader(title: '태그'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: job.tags.map((t) => TagChip('#$t')).toList(),
              ),
            ),
          ],
          if (job.checklists.isNotEmpty) ...[
            const Divider(thickness: 8, color: AppColors.bg),
            const SectionHeader(title: '지원 전 체크리스트'),
            ...job.checklists.map((c) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_box_outline_blank,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '근무 위치'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 160,
                color: const Color(0xFFE3F2F5),
                alignment: Alignment.center,
                child: const Icon(Icons.location_pin,
                    size: 36, color: AppColors.brandDark),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHired && job.status != JobStatus.done) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/job/${job.id}/contract'),
                        icon: const Icon(Icons.description_outlined,
                            size: 18),
                        label: Text(
                          job.contractStatus == ContractStatus.signed
                              ? '계약서 보기'
                              : '계약서 서명',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/job/${job.id}/checkin'),
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('출퇴근 체크'),
                      ),
                    ),
                  ],
                ),
              ] else
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {},
                        child: const Icon(Icons.chat_bubble_outline,
                            color: AppColors.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: job.status == JobStatus.done
                          ? FilledButton.icon(
                              onPressed: () => context
                                  .push('/job/${job.id}/review/write'),
                              icon:
                                  const Icon(Icons.rate_review_outlined),
                              label: const Text('리뷰 작성'),
                            )
                          : FilledButton(
                              onPressed: () => _showApplyDialog(
                                  context, job.checklists),
                              child: const Text('지원하기'),
                            ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplyDialog(BuildContext context, List<String> items) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('지원 전 확인',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (items.isEmpty)
                const Text('정말 이 공고에 지원하시겠어요?')
              else ...items.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.brandDark, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(c)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('지원이 접수되었습니다 (목업)')),
              );
            },
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: const Text('지원하기'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;
  const _InfoRow(
      {required this.icon, required this.text, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: highlight ? AppColors.brandDark : AppColors.text,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
