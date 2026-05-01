import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class JobStatsScreen extends StatelessWidget {
  final int jobId;
  const JobStatsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(jobId);
    final s = Dummy.statsForJob(jobId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('공고 통계'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 공고 헤더
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  '${fmtDate(job.startAt)} · ${fmtTime(job.startAt)} ~ ${fmtTime(job.endAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 4개 KPI
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _KpiCard(
                label: '노출',
                value: '${s.impressions}',
                trailing: '회',
                icon: Icons.visibility_outlined,
              ),
              _KpiCard(
                label: '상세 진입',
                value: '${s.clicks}',
                trailing:
                    '회 · ${(s.clickRate * 100).toStringAsFixed(1)}%',
                icon: Icons.touch_app_outlined,
              ),
              _KpiCard(
                label: '지원',
                value: '${s.applications}',
                trailing:
                    '명 · ${(s.applyRate * 100).toStringAsFixed(1)}%',
                icon: Icons.send_outlined,
                highlight: true,
              ),
              _KpiCard(
                label: '채용 확정',
                value: '${s.hires}',
                trailing:
                    '명 · ${(s.hireRate * 100).toStringAsFixed(0)}%',
                icon: Icons.celebration_outlined,
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: '최근 7일 노출 추이',
            child: _BarChart(values: s.last7DaysImpressions),
          ),
          const SizedBox(height: 12),
          _Section(
            title: '단가 비교',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompareRow(
                  label: '내 공고 시급',
                  value: fmtMoney(job.pay),
                  highlight: true,
                ),
                const SizedBox(height: 8),
                _CompareRow(
                  label: '${job.category.label} 평균 시급',
                  value: fmtMoney(s.avgPay),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: job.pay >= s.avgPay
                        ? const Color(0xFFE8F8EE)
                        : const Color(0xFFFFF6E5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        job.pay >= s.avgPay
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 18,
                        color: job.pay >= s.avgPay
                            ? const Color(0xFF1F8E48)
                            : const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job.pay >= s.avgPay
                              ? '평균보다 ${fmtMoney(job.pay - s.avgPay)} 높아요. 매칭이 빨라질 가능성이 큽니다.'
                              : '평균보다 ${fmtMoney(s.avgPay - job.pay)} 낮아요. 시급 인상 또는 끌어올리기 추천.',
                          style: const TextStyle(
                              fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (s.applications < 5 || job.pay < s.avgPay)
            FilledButton.icon(
              onPressed: () => context.push('/giver/job/$jobId/boost'),
              icon: const Icon(Icons.rocket_launch),
              label: const Text('끌어올리기로 노출 늘리기'),
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String trailing;
  final IconData icon;
  final bool highlight;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.trailing,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.brandDark : AppColors.divider,
          width: highlight ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: highlight
                      ? AppColors.brandDark
                      : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: highlight ? AppColors.brandDark : AppColors.text,
              )),
          const SizedBox(height: 2),
          Text(trailing,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<int> values;
  const _BarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxV = values.fold<int>(1, (a, b) => a > b ? a : b);
    final labels = const ['월', '화', '수', '목', '금', '토', '일'];
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final h = 110 * (values[i] / maxV);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${values[i]}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brandDark, AppColors.brand],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[i],
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _CompareRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                color: highlight ? AppColors.text : AppColors.textMuted,
                fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.w500,
              )),
        ),
        Text(value,
            style: TextStyle(
              fontSize: highlight ? 16 : 14,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.brandDark : AppColors.text,
            )),
      ],
    );
  }
}
