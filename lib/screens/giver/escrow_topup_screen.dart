import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class EscrowTopupScreen extends StatefulWidget {
  const EscrowTopupScreen({super.key});

  @override
  State<EscrowTopupScreen> createState() => _EscrowTopupScreenState();
}

class _EscrowTopupScreenState extends State<EscrowTopupScreen> {
  static const _presets = [100000, 300000, 500000, 1000000, 3000000];
  int? _selected;
  final _customCtrl = TextEditingController();
  PaymentMethod? _method;

  @override
  void initState() {
    super.initState();
    _method = Dummy.paymentMethods.firstWhere(
      (m) => m.isDefault,
      orElse: () => Dummy.paymentMethods.first,
    );
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  int? get _amount {
    if (_selected != null) return _selected;
    final raw = _customCtrl.text.replaceAll(',', '').trim();
    return int.tryParse(raw);
  }

  void _pickMethod() {
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('결제수단 선택',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ...Dummy.paymentMethods.map((m) => RadioListTile<int>(
                  value: m.id,
                  groupValue: _method?.id,
                  activeColor: AppColors.brandDark,
                  title: Text(m.label),
                  subtitle: Text(m.maskedNumber),
                  onChanged: (v) {
                    setState(() => _method = m);
                    Navigator.pop(sheetCtx);
                  },
                )),
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.brandDark),
              title: const Text('새 결제수단 추가'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/giver/payment-methods');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    final amount = _amount;
    if (amount == null || amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 충전 금액은 10,000원이에요')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('충전 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('충전 금액', fmtMoney(amount), highlight: true),
            const SizedBox(height: 6),
            _kv('결제수단', _method?.label ?? '-'),
            const SizedBox(height: 6),
            _kv('수수료', '면제'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${fmtMoney(amount)} 충전 완료 (목업)')),
              );
              context.pop();
            },
            child: const Text('충전하기'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool highlight = false}) {
    return Row(
      children: [
        Text(k,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const Spacer(),
        Text(v,
            style: TextStyle(
              fontSize: highlight ? 16 : 13,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.brandDark : AppColors.text,
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = Dummy.escrow.fold<int>(0, (a, e) => a + e.amount);
    return Scaffold(
      appBar: AppBar(title: const Text('에스크로 충전')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.brandDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('현재 예치 잔액',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                      Text(fmtMoney(balance),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('충전 금액',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((p) {
              final on = _selected == p;
              return ChoiceChip(
                label: Text(fmtMoney(p)),
                selected: on,
                showCheckmark: false,
                selectedColor: AppColors.brandDark,
                labelStyle: TextStyle(
                  color: on ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) {
                  setState(() {
                    _selected = p;
                    _customCtrl.clear();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '직접 입력 (10,000원 이상)',
              suffixText: '원',
            ),
            onChanged: (_) => setState(() => _selected = null),
          ),
          const SizedBox(height: 24),
          const Text('결제수단',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickMethod,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _method?.kind == PaymentMethodKind.card
                          ? Icons.credit_card
                          : Icons.account_balance,
                      color: AppColors.brandDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_method?.label ?? '결제수단 선택',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        if (_method != null)
                          Text(_method!.maskedNumber,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textFaint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '• 충전 금액은 공고 등록 시 자동으로 사용돼요\n'
              '• 미사용 금액은 언제든 환불할 수 있어요\n'
              '• 결제 영수증은 마이페이지 > 지급 내역에서 확인할 수 있어요',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textMuted, height: 1.6),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _amount == null ? null : _confirm,
            child: Text(
              _amount == null ? '충전하기' : '${fmtMoney(_amount!)} 충전하기',
            ),
          ),
        ),
      ),
    );
  }
}
