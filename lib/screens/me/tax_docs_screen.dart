import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class TaxDocsScreen extends StatefulWidget {
  const TaxDocsScreen({super.key});

  @override
  State<TaxDocsScreen> createState() => _TaxDocsScreenState();
}

class _TaxDocsScreenState extends State<TaxDocsScreen> {
  int _year = 2026;

  @override
  Widget build(BuildContext context) {
    final payments = Dummy.payments;
    final totalGross =
        payments.fold<int>(0, (a, p) => a + p.amount);
    final totalTax = payments.fold<int>(0, (a, p) => a + p.tax);
    final totalNet = payments.fold<int>(0, (a, p) => a + p.netAmount);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('세금·소득 명세'),
          bottom: const TabBar(
            indicatorColor: AppColors.brandDark,
            labelColor: AppColors.brandDark,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: '월별'),
              Tab(text: '연말정산'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MonthlyTab(year: _year, onYearChanged: (y) => setState(() => _year = y)),
            _AnnualTab(
              year: _year,
              gross: totalGross,
              tax: totalTax,
              net: totalNet,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyTab extends StatelessWidget {
  final int year;
  final ValueChanged<int> onYearChanged;
  const _MonthlyTab({required this.year, required this.onYearChanged});

  @override
  Widget build(BuildContext context) {
    final months = List.generate(5, (i) {
      final m = 5 - i;
      final base = m * 73000;
      return _MonthlyRow(
        year: year,
        month: m,
        gross: base,
        tax: (base * 0.033).toInt(),
        count: m,
      );
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: year,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 2026, child: Text('2026년')),
                  DropdownMenuItem(value: 2025, child: Text('2025년')),
                  DropdownMenuItem(value: 2024, child: Text('2024년')),
                ],
                onChanged: (v) {
                  if (v != null) onYearChanged(v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...months,
      ],
    );
  }
}

class _MonthlyRow extends StatelessWidget {
  final int year;
  final int month;
  final int gross;
  final int tax;
  final int count;
  const _MonthlyRow({
    required this.year,
    required this.month,
    required this.gross,
    required this.tax,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              Text('$year년 $month월',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              const TagChip('인적용역', primary: true),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.file_download_outlined, size: 20),
                onPressed: () =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$year-$month 명세서 PDF 다운로드 (목업)')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _kv('근무 횟수', '$count건'),
          _kv('총 지급액', fmtMoney(gross)),
          _kv('원천징수 (3.3%)', '- ${fmtMoney(tax)}', muted: true),
          const Divider(height: 16, color: AppColors.divider),
          _kv('실수령액', fmtMoney(gross - tax), highlight: true),
        ],
      ),
    );
  }

  Widget _kv(String k, String v,
      {bool muted = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(k,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          const Spacer(),
          Text(v,
              style: TextStyle(
                fontSize: highlight ? 15 : 13,
                fontWeight: FontWeight.w800,
                color: highlight
                    ? AppColors.brandDark
                    : muted
                        ? AppColors.textMuted
                        : AppColors.text,
              )),
        ],
      ),
    );
  }
}

class _AnnualTab extends StatelessWidget {
  final int year;
  final int gross;
  final int tax;
  final int net;
  const _AnnualTab({
    required this.year,
    required this.gross,
    required this.tax,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$year년 누적 소득',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Text(fmtMoney(gross),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandDark)),
              const SizedBox(height: 4),
              Text('실수령 ${fmtMoney(net)} · 원천징수 ${fmtMoney(tax)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: '소득 구분'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _DistRow(label: '인적용역 (3.3%)', amount: gross, percent: 100),
              const Divider(height: 16, color: AppColors.divider),
              _DistRow(label: '기타소득 (8.8%)', amount: 0, percent: 0),
              const Divider(height: 16, color: AppColors.divider),
              _DistRow(label: '근로소득', amount: 0, percent: 0),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$year년 종합 명세서 PDF 다운로드 (목업)')),
          ),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text('$year년 종합 명세서 (PDF)'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('국세청 홈택스 자동 신고 안내 (목업)')),
          ),
          icon: const Icon(Icons.account_balance_outlined, size: 18),
          label: const Text('홈택스 신고 안내'),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.chipBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '※ 인적용역 사업소득은 매년 5월 종합소득세 신고 대상입니다. 연소득 합계가 큰 경우 별도 신고가 필요할 수 있어요.',
            style: TextStyle(
                fontSize: 11, color: AppColors.textMuted, height: 1.6),
          ),
        ),
      ],
    );
  }
}

class _DistRow extends StatelessWidget {
  final String label;
  final int amount;
  final int percent;
  const _DistRow({
    required this.label,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.chipBg,
                  valueColor: const AlwaysStoppedAnimation(
                      AppColors.brandDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(fmtMoney(amount),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
