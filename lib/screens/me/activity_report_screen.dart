import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class ActivityReportScreen extends StatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  State<ActivityReportScreen> createState() => _ActivityReportScreenState();
}

class _ActivityReportScreenState extends State<ActivityReportScreen> {
  String _range = '이번 달';

  @override
  Widget build(BuildContext context) {
    final completed = Dummy.applications
        .where((a) => a.status == ApplicationStatus.completed)
        .length;
    final hired = Dummy.applications
        .where((a) => a.status == ApplicationStatus.hired)
        .length;
    final cancelled = Dummy.applications
        .where((a) => a.status == ApplicationStatus.cancelled)
        .length;
    final earned = Dummy.payments.fold<int>(0, (a, p) => a + p.netAmount);
    final hours = completed * 6;
    final monthly = const [4, 6, 5, 8, 7, 9];

    return Scaffold(
      appBar: AppBar(title: const Text('내 활동 리포트')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _range,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: '이번 주', child: Text('이번 주')),
                    DropdownMenuItem(value: '이번 달', child: Text('이번 달')),
                    DropdownMenuItem(value: '최근 3개월', child: Text('최근 3개월')),
                    DropdownMenuItem(value: '올해', child: Text('올해')),
                  ],
                  onChanged: (v) => setState(() => _range = v ?? _range),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV 내보내기 (목업)')),
                  );
                },
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('내보내기'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '총 수입',
                  value: fmtMoney(earned),
                  icon: Icons.payments_outlined,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: '근무 시간',
                  value: '${hours}h',
                  icon: Icons.access_time,
                  color: const Color(0xFF2F66E2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '완료한 알바',
                  value: '$completed건',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF1F8E48),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: '평균 평점',
                  value: Dummy.me.rating.toStringAsFixed(1),
                  icon: Icons.star_outline,
                  color: const Color(0xFFFFC400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('월별 근무 횟수',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _BarChart(values: monthly),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('지원 추이',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _MetricRow(
                  label: '진행 중',
                  value: hired + Dummy.applications
                      .where((a) => a.status == ApplicationStatus.applied)
                      .length,
                  color: const Color(0xFF2F66E2),
                ),
                _MetricRow(
                  label: '완료',
                  value: completed,
                  color: AppColors.brandDark,
                ),
                _MetricRow(
                  label: '취소',
                  value: cancelled,
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium,
                    color: AppColors.brandDark, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('상위 12% 워커예요!',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text(
                        '같은 지역 워커 대비 평점·완료율이 우수해요',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13)),
          ),
          Text('$value건',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
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
    final months = const ['12월', '1월', '2월', '3월', '4월', '5월'];
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.brandDark, AppColors.brand],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(months[i],
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
