import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

enum _Period { d7, d30, d90, custom }

extension _PeriodX on _Period {
  String get label => switch (this) {
        _Period.d7 => '최근 7일',
        _Period.d30 => '최근 30일',
        _Period.d90 => '최근 90일',
        _Period.custom => '직접 지정',
      };
}

class JobStatsScreen extends StatefulWidget {
  final int jobId;
  const JobStatsScreen({super.key, required this.jobId});

  @override
  State<JobStatsScreen> createState() => _JobStatsScreenState();
}

class _JobStatsScreenState extends State<JobStatsScreen> {
  _Period _period = _Period.d7;
  bool _compare = false;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    final s = Dummy.statsForJob(widget.jobId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('공고 통계'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _showExportSheet,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showMetricHelp(s),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(job.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: job.status == JobStatus.open
                            ? AppColors.success
                            : AppColors.textFaint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        job.status == JobStatus.open ? '모집중' : '마감',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${fmtDate(job.startAt)} · ${fmtTime(job.startAt)} ~ ${fmtTime(job.endAt)}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 기간 필터 + 비교 토글
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _showPeriodSheet,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range,
                            size: 18, color: AppColors.brandDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _period == _Period.custom && _customRange != null
                                ? _fmtRange(_customRange!)
                                : _period.label,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _compare = !_compare),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: _compare ? AppColors.brandSoft : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _compare ? AppColors.brandDark : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _compare
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                        color: _compare
                            ? AppColors.brandDark
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      const Text('전기간 비교',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4개 KPI
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              _KpiCard(
                label: '노출',
                value: '${s.impressions}',
                trailing: '회',
                icon: Icons.visibility_outlined,
                delta: _compare ? '+12%' : null,
                onTap: () => _showMetricDetail('노출', s.last7DaysImpressions),
              ),
              _KpiCard(
                label: '상세 진입',
                value: '${s.clicks}',
                trailing: '회 · ${(s.clickRate * 100).toStringAsFixed(1)}%',
                icon: Icons.touch_app_outlined,
                delta: _compare ? '+8%' : null,
                onTap: () => _showMetricDetail(
                    '상세 진입',
                    List.generate(
                        7, (i) => 30 + ((i + widget.jobId) * 5) % 40)),
              ),
              _KpiCard(
                label: '지원',
                value: '${s.applications}',
                trailing: '명 · ${(s.applyRate * 100).toStringAsFixed(1)}%',
                icon: Icons.send_outlined,
                highlight: true,
                delta: _compare ? '-3%' : null,
                onTap: () => _showMetricDetail(
                    '지원', List.generate(7, (i) => 2 + (i + widget.jobId) % 5)),
              ),
              _KpiCard(
                label: '채용 확정',
                value: '${s.hires}',
                trailing: '명 · ${(s.hireRate * 100).toStringAsFixed(0)}%',
                icon: Icons.celebration_outlined,
                highlight: true,
                delta: _compare ? '+1' : null,
                onTap: () => _showMetricDetail(
                    '채용', List.generate(7, (i) => i % 3 == 0 ? 1 : 0)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: '깔때기 (Funnel)',
            child: Column(
              children: [
                _FunnelStep(
                    label: '노출', value: s.impressions, max: s.impressions),
                _FunnelStep(
                    label: '상세 진입',
                    value: s.clicks,
                    max: s.impressions,
                    rate: s.clickRate),
                _FunnelStep(
                    label: '지원',
                    value: s.applications,
                    max: s.impressions,
                    rate: s.applyRate,
                    fromLabel: '진입'),
                _FunnelStep(
                    label: '채용',
                    value: s.hires,
                    max: s.impressions,
                    rate: s.hireRate,
                    fromLabel: '지원'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: '${_period.label} 노출 추이',
            trailing: TextButton.icon(
              onPressed: _showExportSheet,
              icon: const Icon(Icons.download_outlined, size: 14),
              label: const Text('내보내기'),
            ),
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
                const SizedBox(height: 8),
                _CompareRow(
                  label: '동일 시간대 상위 25%',
                  value: fmtMoney((s.avgPay * 1.18).round()),
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
                          style: const TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: '시간대별 활성도 (히트맵)',
            child: _Heatmap(seed: widget.jobId),
          ),
          const SizedBox(height: 16),
          if (s.applications < 5 || job.pay < s.avgPay)
            FilledButton.icon(
              onPressed: () => context.push('/giver/job/${widget.jobId}/boost'),
              icon: const Icon(Icons.rocket_launch),
              label: const Text('끌어올리기로 노출 늘리기'),
            ),
        ],
      ),
    );
  }

  String _fmtRange(DateTimeRange r) {
    String d(DateTime x) => '${x.month}.${x.day.toString().padLeft(2, '0')}';
    return '${d(r.start)} ~ ${d(r.end)}';
  }

  void _showPeriodSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('기간 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final p in _Period.values)
              RadioListTile<_Period>(
                title: Text(p.label),
                value: p,
                groupValue: _period,
                activeColor: AppColors.brandDark,
                onChanged: (v) async {
                  if (v == null) return;
                  Navigator.pop(sheetCtx);
                  if (v == _Period.custom) {
                    final r = await showDateRangePicker(
                      context: context,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (r != null) {
                      setState(() {
                        _period = v;
                        _customRange = r;
                      });
                    }
                  } else {
                    setState(() {
                      _period = v;
                      _customRange = null;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMetricDetail(String label, List<int> values) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('$label · 일자별 추이',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _BarChart(values: values),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _StatRow(
                        label: '합계',
                        value: '${values.fold<int>(0, (a, b) => a + b)}'),
                    _StatRow(
                        label: '일 평균',
                        value:
                            '${(values.fold<int>(0, (a, b) => a + b) / values.length).toStringAsFixed(1)}'),
                    _StatRow(
                        label: '최고',
                        value: '${values.reduce((a, b) => a > b ? a : b)}'),
                    _StatRow(
                        label: '최저',
                        value: '${values.reduce((a, b) => a < b ? a : b)}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('통계 내보내기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _shareTile(Icons.table_chart, 'CSV', AppColors.brandSoft,
                      AppColors.brandDark, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('통계_${'job'}.csv 다운로드 (목업)')),
                    );
                  }),
                  _shareTile(
                      Icons.image, '이미지', AppColors.chipBg, AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이미지로 저장 (목업)')),
                    );
                  }),
                  _shareTile(
                      Icons.link, '리포트 링크', AppColors.chipBg, AppColors.text,
                      () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('https://share.work/r/abc 복사됨 (목업)')),
                    );
                  }),
                  _shareTile(Icons.chat_bubble, '카카오톡', const Color(0xFFFEE500),
                      AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('카카오톡 공유 (목업)')),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareTile(
      IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: fg),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showMetricHelp(JobStats s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('지표 설명',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final h in const [
                ['노출', '검색 결과·홈 피드에 카드가 보여진 횟수', '업계 평균 1,200회/공고'],
                ['상세 진입', '카드를 누르고 공고 상세를 본 횟수', '업계 평균 진입율 18~25%'],
                ['지원', '실제로 지원 버튼을 눌러 신청한 횟수', '업계 평균 지원율 5~9%'],
                ['채용 확정', '지원자를 실제로 채용한 비율', '업계 평균 12~18%'],
              ])
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h[0],
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDark)),
                      const SizedBox(height: 4),
                      Text(h[1], style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(h[2],
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
            ],
          ),
        ),
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
  final String? delta;
  final VoidCallback? onTap;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.trailing,
    required this.icon,
    this.highlight = false,
    this.delta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = delta?.startsWith('+') ?? false;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                    color:
                        highlight ? AppColors.brandDark : AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ),
                if (delta != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? const Color(0xFFE8F8EE)
                          : const Color(0xFFFFE5E5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(delta!,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isPositive
                                ? const Color(0xFF1F8E48)
                                : const Color(0xFFB91C1C))),
                  ),
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
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textFaint)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

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
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
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
    final labels = values.length == 7
        ? const ['월', '화', '수', '목', '금', '토', '일']
        : List.generate(values.length, (i) => '${i + 1}일');
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
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
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
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

class _FunnelStep extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final double? rate;
  final String? fromLabel;
  const _FunnelStep({
    required this.label,
    required this.value,
    required this.max,
    this.rate,
    this.fromLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pct = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandDark)),
              if (rate != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${fromLabel ?? "노출"} → ${(rate! * 100).toStringAsFixed(1)}%',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.chipBg,
              valueColor: const AlwaysStoppedAnimation(AppColors.brandDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final int seed;
  const _Heatmap({required this.seed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 28),
            for (final h in const ['0', '6', '12', '18'])
              Expanded(
                child: Center(
                  child: Text('${h}시',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var d = 0; d < 7; d++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    ['월', '화', '수', '목', '금', '토', '일'][d],
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                for (var h = 0; h < 24; h++)
                  Expanded(
                    child: Container(
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: _heat(d, h),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('낮음',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(width: 4),
            for (final v in const [0.1, 0.3, 0.6, 0.9])
              Container(
                width: 12,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: AppColors.brandDark.withOpacity(v),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(width: 4),
            const Text('높음',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Color _heat(int d, int h) {
    // 출퇴근 시간대(7~9, 18~20)에 활성도 강함
    double v = 0.1;
    if ((h >= 7 && h <= 9) || (h >= 18 && h <= 20)) v = 0.7;
    if (h >= 12 && h <= 14) v = 0.4;
    if (d >= 5 && (h >= 11 && h <= 22)) v = (v + 0.2).clamp(0.1, 0.95);
    final wobble = ((d * 7 + h * 3 + seed) % 5) / 30;
    v = (v + wobble).clamp(0.05, 0.95);
    return AppColors.brandDark.withOpacity(v);
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
