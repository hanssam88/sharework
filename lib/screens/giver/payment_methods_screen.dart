import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late List<PaymentMethod> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(Dummy.paymentMethods);
  }

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
        content: const Text('이 결제수단을 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _items.removeWhere((m) => m.id == id));
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

  void _addNew() {
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('결제수단 추가',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card,
                  color: AppColors.brandDark),
              title: const Text('카드 등록'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('카드 등록 화면 (목업)')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance,
                  color: AppColors.brandDark),
              title: const Text('계좌이체 등록'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('계좌 등록 화면 (목업)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('결제수단 관리')),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.credit_card_off,
              message: '등록된 결제수단이 없어요',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = _items[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: m.isDefault
                          ? AppColors.brandDark
                          : AppColors.divider,
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
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15)),
                                    if (m.isDefault) ...[
                                      const SizedBox(width: 6),
                                      const TagChip('기본', primary: true),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(m.maskedNumber,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'default') _setDefault(m.id);
                              if (v == 'remove') _remove(m.id);
                            },
                            itemBuilder: (_) => [
                              if (!m.isDefault)
                                const PopupMenuItem(
                                    value: 'default',
                                    child: Text('기본으로 설정')),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text('삭제',
                                    style:
                                        TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
}
