import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

enum _MethodPhase { active, pending1Won, suspended }

class _MethodMeta {
  final _MethodPhase phase;
  final bool autoCharge;
  final int? autoChargeAmount;
  final int? autoChargeThreshold;
  const _MethodMeta({
    this.phase = _MethodPhase.active,
    this.autoCharge = false,
    this.autoChargeAmount,
    this.autoChargeThreshold,
  });

  _MethodMeta copyWith({
    _MethodPhase? phase,
    bool? autoCharge,
    int? autoChargeAmount,
    int? autoChargeThreshold,
  }) =>
      _MethodMeta(
        phase: phase ?? this.phase,
        autoCharge: autoCharge ?? this.autoCharge,
        autoChargeAmount: autoChargeAmount ?? this.autoChargeAmount,
        autoChargeThreshold: autoChargeThreshold ?? this.autoChargeThreshold,
      );
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late List<PaymentMethod> _items;
  final Map<int, _MethodMeta> _meta = {};

  // Limits
  int _dailyLimit = 1000000;
  int _monthlyLimit = 5000000;

  static const _cardBrands = [
    ['신한카드', Icons.credit_card, Color(0xFF0046FF)],
    ['삼성카드', Icons.credit_card, Color(0xFF1428A0)],
    ['현대카드', Icons.credit_card, Color(0xFF000000)],
    ['국민카드', Icons.credit_card, Color(0xFFFFB800)],
    ['우리카드', Icons.credit_card, Color(0xFF008CD7)],
    ['카카오뱅크', Icons.credit_card, Color(0xFFFEE500)],
    ['BC카드', Icons.credit_card, Color(0xFFE60012)],
    ['NH농협', Icons.credit_card, Color(0xFF00833D)],
  ];

  static const _banks = [
    '카카오뱅크',
    '토스뱅크',
    '신한은행',
    '국민은행',
    '우리은행',
    '하나은행',
    '농협은행',
    '기업은행',
    '새마을금고',
  ];

  @override
  void initState() {
    super.initState();
    _items = List.of(Dummy.paymentMethods);
    for (final m in _items) {
      _meta[m.id] = const _MethodMeta();
    }
  }

  int get _nextId => _items.isEmpty
      ? 1
      : _items.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;

  void _setDefault(int id) {
    setState(() {
      _items = _items
          .map((m) => PaymentMethod(
                id: m.id,
                kind: m.kind,
                label: m.label,
                maskedNumber: m.maskedNumber,
                isDefault: m.id == id,
              ))
          .toList();
    });
  }

  void _remove(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('결제수단 삭제'),
        content: const Text('이 결제수단을 삭제하시겠어요?\n자동충전이 설정되어 있다면 함께 해제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _items.removeWhere((m) => m.id == id);
                _meta.remove(id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('삭제되었어요')),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _addNew() {
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
              const Text('결제수단 추가',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _addTile(Icons.credit_card, '카드', () {
                    Navigator.pop(sheetCtx);
                    _showCardForm();
                  }),
                  _addTile(Icons.account_balance, '계좌이체', () {
                    Navigator.pop(sheetCtx);
                    _showBankForm();
                  }),
                  _addTile(Icons.account_balance_wallet, '간편결제', () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('카카오페이·네이버페이 (목업)')),
                    );
                  }),
                  _addTile(Icons.business_center, '법인', () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('법인카드 등록은 별도 인증이 필요해요 (목업)')),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security, size: 16, color: AppColors.brandDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '카드 정보는 PG사(토스페이먼츠)를 통해 안전하게 보관돼요. 우리 서버에는 저장되지 않아요.',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.brandDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addTile(IconData icon, String label, VoidCallback onTap) {
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
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.brandDark),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showCardForm() {
    int brandIdx = 0;
    final numCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final cvcCtrl = TextEditingController();
    final aliasCtrl = TextEditingController();
    bool agreeRecurring = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (innerCtx, innerSet) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('카드 등록',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Text('카드사 선택',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: _cardBrands.length,
                  itemBuilder: (_, i) {
                    final on = brandIdx == i;
                    final brand = _cardBrands[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => innerSet(() => brandIdx = i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: on
                              ? (brand[2] as Color).withOpacity(0.15)
                              : AppColors.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: on ? (brand[2] as Color) : AppColors.divider,
                            width: on ? 1.5 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(4),
                        child: Text(brand[0] as String,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color:
                                    on ? (brand[2] as Color) : AppColors.text)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: numCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  decoration: const InputDecoration(
                    labelText: '카드번호',
                    hintText: '1234-5678-9012-3456',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expCtrl,
                        maxLength: 5,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: '유효기간',
                          hintText: 'MM/YY',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: cvcCtrl,
                        maxLength: 3,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CVC',
                          hintText: '뒷면 3자리',
                        ),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: aliasCtrl,
                  maxLength: 12,
                  decoration: const InputDecoration(
                    labelText: '별칭 (선택)',
                    hintText: '예) 사업용 카드',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('(필수) 자동결제·정기결제 동의',
                      style: TextStyle(fontSize: 13)),
                  value: agreeRecurring,
                  activeColor: AppColors.brandDark,
                  onChanged: (v) => innerSet(() => agreeRecurring = v ?? false),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: !agreeRecurring || numCtrl.text.length < 12
                      ? null
                      : () {
                          final brand = _cardBrands[brandIdx];
                          final last4 = numCtrl.text.length >= 4
                              ? numCtrl.text.substring(numCtrl.text.length - 4)
                              : '0000';
                          final id = _nextId;
                          setState(() {
                            _items.add(PaymentMethod(
                              id: id,
                              kind: PaymentMethodKind.card,
                              label: aliasCtrl.text.trim().isEmpty
                                  ? (brand[0] as String)
                                  : aliasCtrl.text.trim(),
                              maskedNumber: '****-****-****-$last4',
                            ));
                            _meta[id] = const _MethodMeta();
                          });
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('카드가 등록되었어요')),
                          );
                        },
                  child: const Text('등록'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBankForm() {
    String bank = _banks.first;
    final accCtrl = TextEditingController();
    final holderCtrl = TextEditingController();
    bool fetched = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (innerCtx, innerSet) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('계좌 등록',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (bs) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            const Text('은행 선택',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            for (final b in _banks)
                              ListTile(
                                title: Text(b),
                                trailing: bank == b
                                    ? const Icon(Icons.check,
                                        color: AppColors.brandDark)
                                    : null,
                                onTap: () {
                                  innerSet(() => bank = b);
                                  Navigator.pop(bs);
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance,
                            color: AppColors.brandDark),
                        const SizedBox(width: 10),
                        Text(bank,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down,
                            color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '계좌번호',
                    hintText: '숫자만 입력',
                    suffixIcon: TextButton(
                      onPressed: accCtrl.text.length < 6
                          ? null
                          : () {
                              innerSet(() {
                                holderCtrl.text = '김알바';
                                fetched = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('예금주 자동 조회 완료')),
                              );
                            },
                      child: const Text('예금주 조회'),
                    ),
                  ),
                  onChanged: (_) => innerSet(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: holderCtrl,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: '예금주',
                    hintText: fetched ? '' : '계좌번호 조회 후 자동 입력',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1원 인증 안내',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDark)),
                      SizedBox(height: 4),
                      Text(
                        '등록 후 1원이 입금되며, 입금자명에 포함된 4자리 숫자를 다음 화면에서 입력해주세요.',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.brandDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: !fetched
                      ? null
                      : () {
                          final last4 = accCtrl.text.length >= 4
                              ? accCtrl.text.substring(accCtrl.text.length - 4)
                              : '0000';
                          final id = _nextId;
                          setState(() {
                            _items.add(PaymentMethod(
                              id: id,
                              kind: PaymentMethodKind.bank,
                              label: bank,
                              maskedNumber:
                                  '${accCtrl.text.substring(0, 4)}-**-$last4',
                            ));
                            _meta[id] = const _MethodMeta(
                                phase: _MethodPhase.pending1Won);
                          });
                          Navigator.pop(sheetCtx);
                          _show1WonSheet(id);
                        },
                  child: const Text('등록 → 1원 인증으로'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _show1WonSheet(int id) {
    final codeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1원 입금자명 인증',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              '계좌에 1원이 입금되었어요. 입금자명에 표시된 4자리 숫자를 입력해주세요.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            _StepperRow(active: 1),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: '입금자명 4자리 숫자',
                hintText: '예) 1234',
                prefixText: 'Sharework ',
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    codeCtrl.text = '7892';
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('데모용 코드를 채웠어요 (목업)')),
                    );
                  },
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('데모 자동입력'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('1원이 다시 입금됐어요 (목업)')),
                    );
                  },
                  child: const Text('재발송'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('나중에 마이페이지에서 인증할 수 있어요')),
                      );
                    },
                    child: const Text('나중에'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: codeCtrl.text.length != 4
                        ? null
                        : () {
                            setState(() {
                              _meta[id] = (_meta[id] ?? const _MethodMeta())
                                  .copyWith(phase: _MethodPhase.active);
                            });
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('계좌가 활성화 되었어요')),
                            );
                          },
                    child: const Text('인증 완료'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoChargeSheet(PaymentMethod m) {
    final meta = _meta[m.id] ?? const _MethodMeta();
    bool on = meta.autoCharge;
    int amount = meta.autoChargeAmount ?? 100000;
    int threshold = meta.autoChargeThreshold ?? 30000;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (innerCtx, innerSet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('에스크로 자동충전',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                '${m.label} (${m.maskedNumber}) 사용',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: on,
                activeColor: AppColors.brandDark,
                title: const Text('자동충전 사용',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                onChanged: (v) => innerSet(() => on = v),
              ),
              if (on) ...[
                const SizedBox(height: 8),
                const Text('충전 금액',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [50000, 100000, 200000, 500000]
                      .map((v) => ChoiceChip(
                            label: Text(fmtMoney(v)),
                            selected: amount == v,
                            onSelected: (_) => innerSet(() => amount = v),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text('잔액 임계치',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [10000, 30000, 50000, 100000]
                      .map((v) => ChoiceChip(
                            label: Text('${fmtMoney(v)} 이하'),
                            selected: threshold == v,
                            onSelected: (_) => innerSet(() => threshold = v),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt,
                          size: 18, color: AppColors.brandDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '잔액이 ${fmtMoney(threshold)} 미만이면 자동으로 ${fmtMoney(amount)}을 충전합니다.',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.brandDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _meta[m.id] = (_meta[m.id] ?? const _MethodMeta()).copyWith(
                      autoCharge: on,
                      autoChargeAmount: amount,
                      autoChargeThreshold: threshold,
                    );
                  });
                  Navigator.pop(sheetCtx);
                },
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLimitSheet() {
    int d = _dailyLimit;
    int mo = _monthlyLimit;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (innerCtx, innerSet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('결제 한도',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('과도한 결제를 막기 위한 보호 한도예요',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Text('일 한도 — ${fmtMoney(d)}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              Slider(
                min: 100000,
                max: 5000000,
                divisions: 49,
                value: d.toDouble(),
                activeColor: AppColors.brandDark,
                onChanged: (v) => innerSet(() => d = (v ~/ 100000) * 100000),
              ),
              const SizedBox(height: 8),
              Text('월 한도 — ${fmtMoney(mo)}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              Slider(
                min: 500000,
                max: 30000000,
                divisions: 59,
                value: mo.toDouble(),
                activeColor: AppColors.brandDark,
                onChanged: (v) => innerSet(() => mo = (v ~/ 500000) * 500000),
              ),
              const SizedBox(height: 8),
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
                        '한도 변경은 본인인증 후 즉시 적용됩니다. 카드사 한도와 별개예요.',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _dailyLimit = d;
                    _monthlyLimit = mo;
                  });
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('한도가 변경되었어요')),
                  );
                },
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemActions(PaymentMethod m) {
    final meta = _meta[m.id] ?? const _MethodMeta();
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
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.bolt, color: AppColors.brandDark),
              title: Text(meta.autoCharge ? '자동충전 변경' : '자동충전 설정'),
              subtitle: meta.autoCharge
                  ? Text(
                      '${fmtMoney(meta.autoChargeThreshold ?? 0)} 이하 시 ${fmtMoney(meta.autoChargeAmount ?? 0)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    )
                  : null,
              onTap: () {
                Navigator.pop(sheetCtx);
                _showAutoChargeSheet(m);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: AppColors.brandDark),
              title: const Text('별칭 변경'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showAliasDialog(m);
              },
            ),
            if (!m.isDefault)
              ListTile(
                leading:
                    const Icon(Icons.star_outline, color: AppColors.brandDark),
                title: const Text('기본 결제수단으로 설정'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _setDefault(m.id);
                },
              ),
            ListTile(
              leading: Icon(
                meta.phase == _MethodPhase.suspended
                    ? Icons.play_circle_outline
                    : Icons.pause_circle_outline,
                color: AppColors.brandDark,
              ),
              title: Text(
                  meta.phase == _MethodPhase.suspended ? '사용 재개' : '일시 정지'),
              onTap: () {
                setState(() {
                  _meta[m.id] = meta.copyWith(
                    phase: meta.phase == _MethodPhase.suspended
                        ? _MethodPhase.active
                        : _MethodPhase.suspended,
                  );
                });
                Navigator.pop(sheetCtx);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title:
                  const Text('삭제', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _remove(m.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAliasDialog(PaymentMethod m) {
    final ctrl = TextEditingController(text: m.label);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('별칭 변경'),
        content: TextField(
          controller: ctrl,
          maxLength: 12,
          decoration: const InputDecoration(hintText: '예) 사업용'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              setState(() {
                final idx = _items.indexWhere((x) => x.id == m.id);
                if (idx >= 0) {
                  _items[idx] = PaymentMethod(
                    id: m.id,
                    kind: m.kind,
                    label: v,
                    maskedNumber: m.maskedNumber,
                    isDefault: m.isDefault,
                  );
                }
              });
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Color _phaseColor(_MethodPhase p) => switch (p) {
        _MethodPhase.active => AppColors.success,
        _MethodPhase.pending1Won => AppColors.warning,
        _MethodPhase.suspended => AppColors.textFaint,
      };

  String _phaseLabel(_MethodPhase p) => switch (p) {
        _MethodPhase.active => '사용 가능',
        _MethodPhase.pending1Won => '1원 인증 대기',
        _MethodPhase.suspended => '일시 정지',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제수단 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: '한도 설정',
            onPressed: _showLimitSheet,
          ),
        ],
      ),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.credit_card_off,
              message: '등록된 결제수단이 없어요',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final m in _items) _buildCard(m),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('한도 설정',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                          '일 ${fmtMoney(_dailyLimit)} · 월 ${fmtMoney(_monthlyLimit)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _showLimitSheet,
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('변경'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNew,
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('결제수단 추가'),
      ),
    );
  }

  Widget _buildCard(PaymentMethod m) {
    final meta = _meta[m.id] ?? const _MethodMeta();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: m.isDefault ? AppColors.brandDark : AppColors.divider,
          width: m.isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  m.kind == PaymentMethodKind.card
                      ? Icons.credit_card
                      : Icons.account_balance,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(m.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        if (m.isDefault) ...[
                          const SizedBox(width: 6),
                          const TagChip('기본', primary: true),
                        ],
                        if (meta.autoCharge) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7DA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt,
                                    size: 11, color: Color(0xFFB45309)),
                                SizedBox(width: 2),
                                Text('자동',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFB45309))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(m.maskedNumber,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showItemActions(m),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _phaseColor(meta.phase),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(_phaseLabel(meta.phase),
                  style: TextStyle(
                      fontSize: 12,
                      color: _phaseColor(meta.phase),
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (meta.phase == _MethodPhase.pending1Won)
                TextButton(
                  onPressed: () => _show1WonSheet(m.id),
                  child: const Text('인증 진행'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final int active;
  const _StepperRow({required this.active});

  @override
  Widget build(BuildContext context) {
    final steps = const ['등록', '1원 인증', '활성'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepBefore = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color:
                  stepBefore < active ? AppColors.brandDark : AppColors.divider,
            ),
          );
        }
        final idx = i ~/ 2;
        final on = idx <= active;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: idx < active
                    ? AppColors.success
                    : (on ? AppColors.brandDark : AppColors.chipBg),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: idx < active
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text('${idx + 1}',
                      style: TextStyle(
                          color: on ? Colors.white : AppColors.textFaint,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
            ),
            const SizedBox(height: 4),
            Text(steps[idx],
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: on ? AppColors.text : AppColors.textFaint)),
          ],
        );
      }),
    );
  }
}
