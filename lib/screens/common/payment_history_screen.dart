import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = Dummy.payments;
    final total = items.fold<int>(0, (acc, p) => acc + p.amount);
    return Scaffold(
      appBar: AppBar(title: const Text('정산 내역')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('이번 달 정산 합계',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Text(fmtMoney(total),
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark)),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: const Text('기간선택'),
                ),
              ],
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg, height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = items[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  onTap: () => context.push('/me/payments/${p.id}'),
                  title: Text(p.jobTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(fmtDate(p.workedAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(fmtMoney(p.amount),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.paid
                              ? const Color(0xFFE8F8EE)
                              : const Color(0xFFFFF6E5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.paid ? '지급완료' : '지급예정',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: p.paid
                                ? const Color(0xFF1F8E48)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
