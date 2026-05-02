import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class JobBoostScreen extends StatefulWidget {
  final int jobId;
  const JobBoostScreen({super.key, required this.jobId});

  @override
  State<JobBoostScreen> createState() => _JobBoostScreenState();
}

class _JobBoostScreenState extends State<JobBoostScreen> {
  BoostKind? _selected = BoostKind.topPin;

  void _purchase() {
    final p = Dummy.boostProducts.firstWhere((b) => b.kind == _selected);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('결제 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(p.desc,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('결제 금액',
                    style: TextStyle(color: AppColors.textMuted)),
                const Spacer(),
                Text(fmtMoney(p.price),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDark)),
              ],
            ),
          ],
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
                SnackBar(content: Text('${p.name} 적용 완료 (목업)')),
              );
              context.pop();
            },
            child: const Text('결제하기'),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(BoostKind k) {
    switch (k) {
      case BoostKind.topPin:
        return Icons.push_pin;
      case BoostKind.brandColor:
        return Icons.palette_outlined;
      case BoostKind.push:
        return Icons.notifications_active_outlined;
      case BoostKind.premium:
        return Icons.workspace_premium;
    }
  }

  String _durationLabel(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}일';
    return '${d.inHours}시간';
  }

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    final products = Dummy.boostProducts;
    return Scaffold(
      appBar: AppBar(title: const Text('끌어올리기 / 광고')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
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
                    const Icon(Icons.rocket_launch,
                        color: AppColors.brandDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '노출을 빠르게 끌어올려 매칭 시간을 단축할 수 있어요.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...products.map((p) {
            final on = _selected == p.kind;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selected = p.kind),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: on ? AppColors.brandDark : AppColors.divider,
                      width: on ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_iconFor(p.kind),
                            color: AppColors.brandDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.chipBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(_durationLabel(p.duration),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMuted)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(p.desc,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(fmtMoney(p.price),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDark,
                              fontSize: 14)),
                      const SizedBox(width: 6),
                      Icon(
                        on
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: on
                            ? AppColors.brandDark
                            : AppColors.textFaint,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
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
                    '결제는 등록된 결제수단(또는 에스크로 잔액)에서 차감됩니다. 환불은 적용 전 24시간 이내 가능해요.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: _selected == null ? null : _purchase,
            icon: const Icon(Icons.bolt),
            label: const Text('결제하고 적용'),
          ),
        ),
      ),
    );
  }
}
