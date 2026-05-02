import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  late List<BankAccount> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(Dummy.bankAccounts);
  }

  void _setDefault(int id) {
    setState(() {
      _items = _items
          .map((a) => BankAccount(
                id: a.id,
                bank: a.bank,
                holder: a.holder,
                maskedNumber: a.maskedNumber,
                status: a.status,
                isDefault: a.id == id,
              ))
          .toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('기본 정산 계좌로 설정되었어요 (목업)')),
    );
  }

  void _remove(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('계좌 삭제'),
        content: const Text('이 계좌를 삭제하시겠어요? 정산 진행 중인 건은 영향을 받지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _items.removeWhere((a) => a.id == id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('삭제되었습니다 (목업)')),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _openAddSheet() {
    final bankCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final holderCtrl = TextEditingController(text: Dummy.me.name);
    String? selectedBank;
    final banks = const [
      '카카오뱅크',
      '토스뱅크',
      '신한은행',
      '국민은행',
      '우리은행',
      '농협은행',
      '하나은행',
      '기업은행',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (_, setSheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('정산 계좌 등록',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                    '본인 명의 계좌만 등록할 수 있어요. 등록 후 1원 송금으로 인증돼요.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    isExpanded: true,
                    decoration: const InputDecoration(hintText: '은행 선택'),
                    items: banks
                        .map((b) =>
                            DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) {
                      setSheet(() => selectedBank = v);
                      bankCtrl.text = v ?? '';
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: numberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '계좌번호 (- 없이 숫자만)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: holderCtrl,
                    decoration: const InputDecoration(
                      hintText: '예금주명',
                    ),
                  ),
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
                            size: 18, color: AppColors.brandDark),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '입력하신 계좌로 1원이 송금되며 입금자명에 표시된 4자리 인증코드를 다음 단계에서 입력합니다.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (selectedBank == null ||
                          numberCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('은행과 계좌번호를 입력해 주세요')),
                        );
                        return;
                      }
                      Navigator.pop(sheetCtx);
                      final num = numberCtrl.text.trim();
                      final masked = num.length >= 4
                          ? '${'*' * (num.length - 4)}${num.substring(num.length - 4)}'
                          : num;
                      setState(() {
                        _items.add(BankAccount(
                          id: DateTime.now().millisecondsSinceEpoch,
                          bank: selectedBank!,
                          holder: holderCtrl.text.trim(),
                          maskedNumber: masked,
                          status: BankAccountStatus.pending,
                        ));
                      });
                      _showVerifySheet();
                    },
                    child: const Text('1원 송금 인증'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showVerifySheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('인증코드 입력',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  '입금자명에 표시된 4자리 코드를 입력해 주세요. (목업: 아무 4자리)',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    hintText: '4자리 코드',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    if (ctrl.text.trim().length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('4자리를 입력해 주세요')),
                      );
                      return;
                    }
                    Navigator.pop(sheetCtx);
                    setState(() {
                      final last = _items.last;
                      _items[_items.length - 1] = BankAccount(
                        id: last.id,
                        bank: last.bank,
                        holder: last.holder,
                        maskedNumber: last.maskedNumber,
                        status: BankAccountStatus.verified,
                        isDefault: !_items.any((a) => a.isDefault),
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('계좌 인증이 완료되었어요 (목업)')),
                    );
                  },
                  child: const Text('인증 완료'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정산 계좌 관리')),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.account_balance_outlined,
              message: '등록된 계좌가 없어요',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final a = _items[i];
                return _AccountCard(
                  account: a,
                  onSetDefault: () => _setDefault(a.id),
                  onRemove: () => _remove(a.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('계좌 추가'),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final BankAccount account;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;
  const _AccountCard({
    required this.account,
    required this.onSetDefault,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: account.isDefault
              ? AppColors.brandDark
              : AppColors.divider,
          width: account.isDefault ? 1.5 : 1,
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
                child: const Icon(Icons.account_balance,
                    color: AppColors.brandDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(account.bank,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        if (account.isDefault) ...[
                          const SizedBox(width: 6),
                          const TagChip('기본', primary: true),
                        ],
                        const SizedBox(width: 6),
                        _StatusBadge(status: account.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${account.holder} · ${account.maskedNumber}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'default') onSetDefault();
                  if (v == 'remove') onRemove();
                },
                itemBuilder: (_) => [
                  if (!account.isDefault &&
                      account.status == BankAccountStatus.verified)
                    const PopupMenuItem(
                        value: 'default', child: Text('기본으로 설정')),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('삭제',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BankAccountStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late String text;
    late Color bg;
    late Color fg;
    switch (status) {
      case BankAccountStatus.verified:
        text = '인증완료';
        bg = const Color(0xFFE8F8EE);
        fg = const Color(0xFF1F8E48);
        break;
      case BankAccountStatus.pending:
        text = '인증중';
        bg = const Color(0xFFFFF6E5);
        fg = const Color(0xFFB45309);
        break;
      case BankAccountStatus.unverified:
        text = '미인증';
        bg = AppColors.chipBg;
        fg = AppColors.textMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: TextStyle(
              color: fg, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
