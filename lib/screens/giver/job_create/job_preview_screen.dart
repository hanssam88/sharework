import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class JobPreviewScreen extends StatelessWidget {
  const JobPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobs.firstWhere((j) => j.status == JobStatus.open,
        orElse: () => Dummy.jobs.first);
    return Scaffold(
      appBar: AppBar(
        title: const Text('공고 미리보기'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('편집으로 돌아가기'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFFF6E5),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                Icon(Icons.visibility_outlined,
                    size: 18, color: Color(0xFFB45309)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '워커에게 보일 화면 미리보기예요. 등록 전에는 지원·문의가 진행되지 않아요.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
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
                      _row(Icons.location_on_outlined, job.address),
                      const SizedBox(height: 6),
                      _row(Icons.access_time,
                          '${fmtDate(job.startAt)} · ${fmtTime(job.startAt)} ~ ${fmtTime(job.endAt)}'),
                      const SizedBox(height: 6),
                      _row(Icons.payments_outlined,
                          '${job.payType} ${fmtMoney(job.pay)}',
                          highlight: true),
                      const SizedBox(height: 6),
                      _row(Icons.people_outline,
                          '${job.hiredCount}/${job.personnel}명 모집중'),
                    ],
                  ),
                ),
                const Divider(thickness: 8, color: AppColors.bg),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.brandSoft,
                        child: Icon(Icons.business,
                            color: AppColors.brandDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.giverName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
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
                    ],
                  ),
                ),
                const Divider(thickness: 8, color: AppColors.bg),
                const SectionHeader(title: '상세 설명'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(job.description,
                      style:
                          const TextStyle(fontSize: 14, height: 1.5)),
                ),
                if (job.tags.isNotEmpty) ...[
                  const Divider(thickness: 8, color: AppColors.bg),
                  const SectionHeader(title: '태그'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          job.tags.map((t) => TagChip('#$t')).toList(),
                    ),
                  ),
                ],
                if (job.checklists.isNotEmpty) ...[
                  const Divider(thickness: 8, color: AppColors.bg),
                  const SectionHeader(title: '지원 전 체크리스트'),
                  ...job.checklists.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
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
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('수정하기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('공고가 등록되었습니다 (목업)')),
                    );
                    context.go('/giver');
                  },
                  child: const Text('이대로 등록하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text, {bool highlight = false}) {
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
