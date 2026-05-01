import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class EscrowScreen extends StatelessWidget {
  const EscrowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = [...Dummy.escrow]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final balance = entries.fold<int>(0, (acc, e) => acc + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('에스크로')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('현재 예치 잔액',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Text(fmtMoney(balance),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDark)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          color: AppColors.brandDark, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '예치된 금액은 근무 완료 확인 시 워커에게 자동 송금됩니다.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('충전 화면 (목업)')),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('충전'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('출금 화면 (목업)')),
                          );
                        },
                        icon: const Icon(Icons.north_east, size: 18),
                        label: const Text('출금'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg, height: 8),
          Expanded(
            child: entries.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: '예치 내역이 없어요',
                  )
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final positive = e.amount > 0;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _bgFor(e.kind),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_iconFor(e.kind),
                              size: 18, color: _fgFor(e.kind)),
                        ),
                        title: Text(e.description,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        subtitle: Text(
                          '${fmtDate(e.createdAt)} · ${_labelFor(e.kind)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                        trailing: Text(
                          '${positive ? '+' : '-'} ${fmtMoney(e.amount.abs())}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: positive
                                ? AppColors.brandDark
                                : AppColors.danger,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(EscrowKind k) {
    switch (k) {
      case EscrowKind.deposit:
        return Icons.south_west;
      case EscrowKind.payout:
        return Icons.north_east;
      case EscrowKind.refund:
        return Icons.replay;
    }
  }

  Color _bgFor(EscrowKind k) {
    switch (k) {
      case EscrowKind.deposit:
        return AppColors.brandSoft;
      case EscrowKind.payout:
        return const Color(0xFFFFF6E5);
      case EscrowKind.refund:
        return AppColors.chipBg;
    }
  }

  Color _fgFor(EscrowKind k) {
    switch (k) {
      case EscrowKind.deposit:
        return AppColors.brandDark;
      case EscrowKind.payout:
        return const Color(0xFFB45309);
      case EscrowKind.refund:
        return AppColors.textMuted;
    }
  }

  String _labelFor(EscrowKind k) {
    switch (k) {
      case EscrowKind.deposit:
        return '예치';
      case EscrowKind.payout:
        return '정산';
      case EscrowKind.refund:
        return '환불';
    }
  }
}
