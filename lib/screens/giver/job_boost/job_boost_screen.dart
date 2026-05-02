import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

enum _BoostStep { product, duration, payment, done }

class JobBoostScreen extends StatefulWidget {
  final int jobId;
  const JobBoostScreen({super.key, required this.jobId});

  @override
  State<JobBoostScreen> createState() => _JobBoostScreenState();
}

class _JobBoostScreenState extends State<JobBoostScreen> {
  BoostKind? _selected = BoostKind.topPin;
  int _durationMultiplier = 1; // 1, 2, 3, 7
  PaymentMethod? _payMethod;
  bool _abTest = false;
  BoostKind? _abVariant;
  bool _useEscrow = false;
  _BoostStep _step = _BoostStep.product;

  static const _durationChoices = [1, 2, 3, 7];

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

  void _showPreviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('적용 전·후 미리보기',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              const Text('일반 노출',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (var i = 0; i < 4; i++)
                _MockJobCard(
                  pinned: false,
                  highlighted: false,
                  isOurs: i == 3,
                  rank: '${i + 1}위',
                ),
              const SizedBox(height: 20),
              const Text('부스트 적용 후',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.brandDark,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _MockJobCard(
                pinned: _selected == BoostKind.topPin ||
                    _selected == BoostKind.premium,
                highlighted: _selected == BoostKind.brandColor ||
                    _selected == BoostKind.premium,
                isOurs: true,
                rank: '상단 고정',
              ),
              for (var i = 0; i < 3; i++)
                _MockJobCard(
                  pinned: false,
                  highlighted: false,
                  isOurs: false,
                  rank: '${i + 2}위',
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
                    Icon(Icons.trending_up,
                        size: 18, color: AppColors.brandDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '예상 노출 +320% · 매칭 시간 평균 38분 단축',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.w700),
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

  void _showCompareSheet() {
    final products = Dummy.boostProducts;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('상품 비교',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          _CompareTableRow(
                            cells: const ['상품', '효과', '예상 노출', '가격'],
                            isHeader: true,
                          ),
                          for (final p in products)
                            _CompareTableRow(
                              cells: [
                                p.name,
                                _expectedEffect(p.kind),
                                _expectedImpressions(p.kind),
                                fmtMoney(p.price),
                              ],
                              icon: _iconFor(p.kind),
                              highlighted: _selected == p.kind,
                              onTap: () {
                                setState(() => _selected = p.kind);
                                Navigator.pop(sheetCtx);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '예상 효과는 동일 카테고리·시간대 평균 데이터를 바탕으로 산정한 추정치입니다.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
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

  String _expectedEffect(BoostKind k) => switch (k) {
        BoostKind.topPin => '상단 #1',
        BoostKind.brandColor => '카드 강조',
        BoostKind.push => '직접 푸시',
        BoostKind.premium => '전체 패키지',
      };

  String _expectedImpressions(BoostKind k) => switch (k) {
        BoostKind.topPin => '+220%',
        BoostKind.brandColor => '+180%',
        BoostKind.push => '+90%',
        BoostKind.premium => '+450%',
      };

  void _showAbSheet() {
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
              const Text('A/B 테스트',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('두 상품을 동시에 진행해 더 효과적인 쪽에 자동으로 예산을 몰아드려요',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _abTest,
                activeColor: AppColors.brandDark,
                title: const Text('A/B 테스트 사용',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                onChanged: (v) {
                  innerSet(() => _abTest = v);
                  setState(() => _abTest = v);
                },
              ),
              if (_abTest) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A안: ${_kindLabel(_selected ?? BoostKind.topPin)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('B안 선택',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: BoostKind.values
                            .where((k) => k != _selected)
                            .map((k) => ChoiceChip(
                                  label: Text(_kindLabel(k)),
                                  selected: _abVariant == k,
                                  onSelected: (_) {
                                    innerSet(() => _abVariant = k);
                                    setState(() => _abVariant = k);
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 14, color: AppColors.brandDark),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '24시간 후 자동으로 우승안에 잔여 예산이 집중됩니다.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheetCtx),
                child: const Text('완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _kindLabel(BoostKind k) =>
      Dummy.boostProducts.firstWhere((p) => p.kind == k).name;

  void _showCancelPolicy() {
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
              const Text('환불·취소 정책',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final p in const [
                ['적용 전', '결제 후 24시간 이내 적용 전이라면 100% 환불'],
                ['일부 적용', '적용 시작 후 사용한 시간만큼 차감 후 환불'],
                ['전액 사용', '효과 적용 완료 후에는 환불 불가'],
                ['공고 취소', '공고가 마감·삭제되면 잔여 시간 자동 환불'],
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(p[0],
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandDark)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(p[1],
                            style: const TextStyle(
                                fontSize: 13, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  context.push('/support/inquiry/new');
                },
                icon: const Icon(Icons.support_agent, size: 16),
                label: const Text('환불 문의하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet() {
    final methods = Dummy.paymentMethods;
    if (_payMethod == null && methods.isNotEmpty) {
      _payMethod = methods.firstWhere((m) => m.isDefault,
          orElse: () => methods.first);
    }
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
              const Text('결제수단 선택',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _useEscrow,
                activeColor: AppColors.brandDark,
                title: const Text('에스크로 잔액 사용',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: const Text('현재 잔액 320,000원',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                onChanged: (v) {
                  innerSet(() => _useEscrow = v);
                  setState(() => _useEscrow = v);
                },
              ),
              if (!_useEscrow) ...[
                const Divider(height: 24),
                const Text('등록된 결제수단',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final m in methods)
                  RadioListTile<PaymentMethod>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(m.label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: Text(m.maskedNumber,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    value: m,
                    groupValue: _payMethod,
                    activeColor: AppColors.brandDark,
                    onChanged: (v) {
                      innerSet(() => _payMethod = v);
                      setState(() => _payMethod = v);
                    },
                  ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    context.push('/giver/payment-methods');
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('결제수단 추가'),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(sheetCtx),
                child: const Text('완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _purchase() {
    final p = Dummy.boostProducts.firstWhere((b) => b.kind == _selected);
    final total = p.price * _durationMultiplier *
        (_abTest && _abVariant != null ? 2 : 1);
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
            _PayRow(label: '단가', value: fmtMoney(p.price)),
            _PayRow(label: '회차', value: '× $_durationMultiplier'),
            if (_abTest && _abVariant != null)
              _PayRow(label: 'A/B', value: '× 2 (B안 동시)'),
            const Divider(),
            _PayRow(label: '결제 금액', value: fmtMoney(total), big: true),
            const SizedBox(height: 8),
            Text(
              _useEscrow ? '에스크로 잔액에서 차감' :
              _payMethod != null ? '${_payMethod!.label} (${_payMethod!.maskedNumber})' :
              '결제수단 미선택',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
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
              setState(() => _step = _BoostStep.done);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${p.name} 적용 완료 (목업)')),
              );
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) context.pop();
              });
            },
            child: const Text('결제하기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    final products = Dummy.boostProducts;
    final selectedProduct = _selected != null
        ? products.firstWhere((p) => p.kind == _selected)
        : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('끌어올리기 / 광고'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: '상품 비교',
            onPressed: _showCompareSheet,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '환불 정책',
            onPressed: _showCancelPolicy,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          _StepIndicator(active: _step.index),
          const SizedBox(height: 16),
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
                    TextButton.icon(
                      onPressed: _showPreviewSheet,
                      icon: const Icon(Icons.preview, size: 16),
                      label: const Text('미리보기'),
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
          const SizedBox(height: 16),
          const Text('1. 상품 선택',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...products.map((p) {
            final on = _selected == p.kind;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _selected = p.kind;
                  _step = _BoostStep.duration;
                }),
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
                        width: 44, height: 44,
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
                            const SizedBox(height: 4),
                            Text(
                              '예상 노출 ${_expectedImpressions(p.kind)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700),
                            ),
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
          const Text('2. 회차 (반복)',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: _durationChoices
                .map((m) => ChoiceChip(
                      label: Text('× $m'),
                      selected: _durationMultiplier == m,
                      onSelected: (_) => setState(() {
                        _durationMultiplier = m;
                        if (_step.index < _BoostStep.payment.index) {
                          _step = _BoostStep.payment;
                        }
                      }),
                    ))
                .toList(),
          ),
          if (selectedProduct != null) ...[
            const SizedBox(height: 6),
            Text(
              '총 ${_durationLabel(selectedProduct.duration * _durationMultiplier)} 동안 적용',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          // A/B
          InkWell(
            onTap: _showAbSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _abTest ? AppColors.brandSoft : AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _abTest
                      ? AppColors.brandDark
                      : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.science_outlined,
                      color: _abTest
                          ? AppColors.brandDark
                          : AppColors.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_abTest ? 'A/B 테스트 ON' : 'A/B 테스트 (선택)',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                        Text(
                          _abTest && _abVariant != null
                              ? 'A: ${_kindLabel(_selected ?? BoostKind.topPin)} vs B: ${_kindLabel(_abVariant!)}'
                              : '두 상품을 동시에 진행해 효과 비교',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 결제수단
          InkWell(
            onTap: _showPaymentSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment,
                      color: AppColors.brandDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('결제수단',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                        Text(
                          _useEscrow
                              ? '에스크로 잔액 (320,000원)'
                              : _payMethod != null
                                  ? '${_payMethod!.label} (${_payMethod!.maskedNumber})'
                                  : '선택 안 됨',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '결제는 등록된 결제수단(또는 에스크로 잔액)에서 차감됩니다.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: _showCancelPolicy,
                  child: const Text('환불정책'),
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
            label: Text(selectedProduct == null
                ? '상품을 선택해주세요'
                : '결제하고 적용 — ${fmtMoney(selectedProduct.price * _durationMultiplier * (_abTest && _abVariant != null ? 2 : 1))}'),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int active;
  const _StepIndicator({required this.active});

  @override
  Widget build(BuildContext context) {
    final steps = const ['상품', '회차', '결제', '완료'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: i ~/ 2 < active
                  ? AppColors.brandDark
                  : AppColors.divider,
            ),
          );
        }
        final idx = i ~/ 2;
        final on = idx <= active;
        return Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: idx < active
                    ? AppColors.success
                    : (on ? AppColors.brandDark : AppColors.chipBg),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: idx < active
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 14)
                  : Text('${idx + 1}',
                      style: TextStyle(
                          color: on ? Colors.white : AppColors.textFaint,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
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

class _CompareTableRow extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;
  final IconData? icon;
  final bool highlighted;
  final VoidCallback? onTap;
  const _CompareTableRow({
    required this.cells,
    this.isHeader = false,
    this.icon,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isHeader ? 12 : 13,
      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w700,
      color: isHeader
          ? AppColors.textMuted
          : (highlighted ? AppColors.brandDark : AppColors.text),
    );
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isHeader
              ? AppColors.bg
              : (highlighted ? AppColors.brandSoft : Colors.white),
          border: Border(
            bottom: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon,
                        size: 14, color: AppColors.brandDark),
                    const SizedBox(width: 4),
                  ],
                  Expanded(child: Text(cells[0], style: style)),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(cells[1], style: style)),
            Expanded(flex: 2, child: Text(cells[2], style: style)),
            Expanded(
              flex: 2,
              child: Text(cells[3],
                  style: style.copyWith(
                      color: isHeader
                          ? AppColors.textMuted
                          : AppColors.brandDark)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockJobCard extends StatelessWidget {
  final bool pinned;
  final bool highlighted;
  final bool isOurs;
  final String rank;
  const _MockJobCard({
    required this.pinned,
    required this.highlighted,
    required this.isOurs,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pinned ? AppColors.brandSoft : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted || pinned
              ? AppColors.brandDark
              : AppColors.divider,
          width: highlighted || pinned ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          if (pinned)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.push_pin,
                  size: 14, color: AppColors.brandDark),
            ),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.work_outline,
                size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOurs ? '내 공고 — 카페 모카 강남점' : '주변의 다른 공고',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isOurs ? AppColors.brandDark : AppColors.text),
                ),
                Text(rank,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (highlighted)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandDark,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('강조',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final bool big;
  const _PayRow({required this.label, required this.value, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: big ? 14 : 12,
                    color: big ? AppColors.text : AppColors.textMuted,
                    fontWeight: big ? FontWeight.w800 : FontWeight.w500)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: big ? 16 : 13,
                  fontWeight: FontWeight.w800,
                  color: big ? AppColors.brandDark : AppColors.text)),
        ],
      ),
    );
  }
}
