import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _redeem() {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('쿠폰 코드를 입력해주세요')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('쿠폰이 등록되었습니다 (목업)')),
    );
    _codeCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final available =
        Dummy.coupons.where((c) => c.status == CouponStatus.available).toList();
    final expired =
        Dummy.coupons.where((c) => c.status != CouponStatus.available).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('쿠폰함'),
          bottom: TabBar(
            indicatorColor: AppColors.brandDark,
            labelColor: AppColors.brandDark,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: '사용가능 ${available.length}'),
              Tab(text: '사용/만료 ${expired.length}'),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(
                        hintText: '쿠폰 코드 입력',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _redeem,
                      child: const Text('등록'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: TabBarView(
                children: [
                  _list(available),
                  _list(expired),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Coupon> items) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.confirmation_number_outlined,
        message: '해당 쿠폰이 없어요',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _CouponCard(c: items[i]),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon c;
  const _CouponCard({required this.c});

  String get _amountLabel {
    if (c.discountPercent > 0) return '${c.discountPercent}% 할인';
    return '${fmtMoney(c.discountAmount)} 할인';
  }

  bool get _isAvailable => c.status == CouponStatus.available;

  @override
  Widget build(BuildContext context) {
    final disabled = !_isAvailable;
    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isAvailable ? AppColors.brandDark : AppColors.divider,
            width: _isAvailable ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 96,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _isAvailable
                    ? AppColors.brandSoft
                    : AppColors.chipBg,
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(_amountLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _isAvailable
                            ? AppColors.brandDark
                            : AppColors.textMuted,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    c.minOrder == 0
                        ? '최소 주문 없음'
                        : '${fmtMoney(c.minOrder)} 이상',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(c.desc,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: AppColors.textFaint),
                        const SizedBox(width: 4),
                        Text(
                          c.status == CouponStatus.expired
                              ? '만료'
                              : c.status == CouponStatus.used
                                  ? '사용완료'
                                  : '${fmtDate(c.expiresAt)}까지',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textFaint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
