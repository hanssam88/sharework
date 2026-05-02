import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class PaymentDetailScreen extends StatelessWidget {
  final int paymentId;
  const PaymentDetailScreen({super.key, required this.paymentId});

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openShareSheet(BuildContext context, dynamic p) {
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
                child: Text('명세서 공유',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.danger),
              title: const Text('PDF 다운로드'),
              subtitle: const Text('연말정산 신고용',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack(context, 'PDF 다운로드 시작 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined,
                  color: AppColors.brandDark),
              title: const Text('이메일로 받기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack(context, 'PDF가 이메일로 발송되었어요 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble,
                  color: Color(0xFFFEE500)),
              title: const Text('카카오톡으로 보내기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack(context, '카카오톡 공유 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('인쇄'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack(context, '인쇄 다이얼로그 (목업)');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openMore(BuildContext context, dynamic p) {
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
            ListTile(
              leading: const Icon(Icons.gavel_outlined,
                  color: AppColors.warning),
              title: const Text('이의 제기'),
              subtitle: const Text(
                  '정산 금액·근무 시간·세금이 잘못되었나요?',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/support/dispute/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('변경 이력 보기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack(context, '변경 이력 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('정산 계좌 변경'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/me/bank-account');
              },
            ),
            ListTile(
              leading: const Icon(Icons.headset_mic_outlined),
              title: const Text('정산 관련 문의'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/support/inquiry/new');
              },
            ),
          ],
        ),
      ),
    );
  }

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
            onPressed: () => _openShareSheet(context, p),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _openMore(context, p),
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
          // 정산 타임라인
          _SectionCard(
            title: '정산 진행 상황',
            children: [
              _Timeline(p: p),
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
          const SizedBox(height: 16),
          // 빠른 액션
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _snack(context, 'PDF 다운로드 시작 (목업)'),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('PDF 받기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/support/dispute/new'),
                  icon: const Icon(Icons.gavel_outlined, size: 18),
                  label: const Text('이의 제기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final dynamic p;
  const _Timeline({required this.p});

  @override
  Widget build(BuildContext context) {
    final stages = [
      ('근무 완료', p.workedAt as DateTime, true),
      ('정산 처리', p.workedAt.add(const Duration(hours: 2)) as DateTime,
          (p.paid ?? false) as bool),
      ('입금 완료', p.paidAt ?? p.workedAt as DateTime,
          (p.paid ?? false) as bool),
    ];
    return Column(
      children: List.generate(stages.length, (i) {
        final s = stages[i];
        final done = s.$3;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: done ? AppColors.brandDark : AppColors.chipBg,
                      shape: BoxShape.circle,
                    ),
                    child: done
                        ? const Icon(Icons.check,
                            size: 12, color: Colors.white)
                        : null,
                  ),
                  if (i < stages.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: done
                            ? AppColors.brandDark
                            : AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$1,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: done
                                  ? AppColors.text
                                  : AppColors.textFaint)),
                      Text(
                        '${fmtDate(s.$2)} ${fmtTime(s.$2)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
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
