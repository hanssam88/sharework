import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class ContractScreen extends StatelessWidget {
  final int jobId;
  const ContractScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(jobId);
    final me = Dummy.me;
    final signed = job.contractStatus == ContractStatus.signed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('전자근로계약서'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (signed)
            _StatusBadge(
              icon: Icons.verified,
              text: '서명 완료',
              color: AppColors.success,
            )
          else
            _StatusBadge(
              icon: Icons.edit_note,
              text: '서명 대기',
              color: AppColors.warning,
            ),
          const SizedBox(height: 16),
          _Card(
            title: '근로계약서 (표준)',
            children: [
              _Row(label: '근로자', value: me.name),
              _Row(label: '사용자', value: job.giverName),
              _Row(label: '근무지', value: job.address),
              _Row(
                label: '근무기간',
                value:
                    '${fmtDate(job.startAt)} ${fmtTime(job.startAt)} ~ ${fmtTime(job.endAt)}',
              ),
              _Row(label: '업무내용', value: job.title),
              _Row(label: '임금', value: '${job.payType} ${fmtMoney(job.pay)}'),
              _Row(
                  label: '지급방법',
                  value: job.sameDayPayment ? '당일지급 (계좌이체)' : '익일 정산'),
              _Row(label: '식사', value: job.foodProvided ? '제공' : '미제공'),
              _Row(label: '교통비', value: job.extraPay ? '지원' : '미지원'),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            title: '주요 조항 (요약)',
            children: const [
              _Bullet(
                  '근로자는 위 근무 시간을 준수하며, 정당한 사유 없이 결근·지각하지 않는다.'),
              _Bullet('사용자는 약정한 임금을 지급방법에 따라 정확히 지급한다.'),
              _Bullet('근로 중 발생한 산재·상해는 산업재해보상보험법에 따라 처리한다.'),
              _Bullet('본 계약은 Sharework 플랫폼을 통해 체결되며, 분쟁 시 플랫폼 약관을 따른다.'),
              _Bullet('근로기준법, 최저임금법 등 관련 법령을 우선 적용한다.'),
            ],
          ),
          const SizedBox(height: 12),
          if (signed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.draw, color: AppColors.brandDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${me.name} (서명 완료)',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('전자서명: ✓ 인증됨',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: signed
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('나중에'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/job/$jobId/contract/sign'),
                        icon: const Icon(Icons.draw),
                        label: const Text('서명하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _StatusBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: color, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

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
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child:
                Icon(Icons.circle, size: 5, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
