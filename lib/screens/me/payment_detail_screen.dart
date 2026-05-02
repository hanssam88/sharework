import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class PaymentDetailScreen extends StatelessWidget {
  final int paymentId;
  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    final p = Dummy.payments.firstWhere(
      (x) => x.id == paymentId,
      orElse: () => Dummy.payments.first,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 명세서'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.paid
                        ? const Color(0xFFE8F8EE)
                        : const Color(0xFFFFF6E5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.paid ? '지급 완료' : '지급 예정',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: p.paid
                          ? const Color(0xFF1F8E48)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(p.jobTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '${p.giverName} · ${fmtDate(p.workedAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                const Text('실수령액',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                Text(fmtMoney(p.netAmount),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDark)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '정산 내역',
            children: [
              _Row(label: '근무 임금', value: fmtMoney(p.amount)),
              if (p.fee > 0)
                _Row(
                    label: '플랫폼 수수료',
                    value: '- ${fmtMoney(p.fee)}',
                    isDeduction: true),
              if (p.tax > 0)
                _Row(
                    label: '원천징수 (3.3%)',
                    value: '- ${fmtMoney(p.tax)}',
                    isDeduction: true),
              const Divider(height: 24),
              _Row(
                label: '실수령액',
                value: fmtMoney(p.netAmount),
                emphasize: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '입금 정보',
            children: [
              _Row(label: '입금 계좌', value: p.bankAccount ?? '미등록'),
              _Row(
                label: '입금 일시',
                value: p.paid && p.paidAt != null
                    ? '${fmtDate(p.paidAt!)} ${fmtTime(p.paidAt!)}'
                    : '입금 대기',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: AppColors.textMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '원천징수는 일용직 소득세(3.3%) 기준입니다. 실 정산 시 변동될 수 있어요.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

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
                  fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isDeduction;
  final bool emphasize;
  const _Row({
    required this.label,
    required this.value,
    this.isDeduction = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasize ? 15 : 13,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
                color: isDeduction
                    ? AppColors.danger
                    : (emphasize ? AppColors.text : AppColors.textMuted),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 18 : 14,
              fontWeight: FontWeight.w800,
              color: isDeduction
                  ? AppColors.danger
                  : (emphasize ? AppColors.brandDark : AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
