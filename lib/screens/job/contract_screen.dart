import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class ContractScreen extends StatefulWidget {
  final int jobId;
  const ContractScreen({super.key, required this.jobId});

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  static const _clauses = <_Clause>[
    _Clause(
      title: '근태·결근',
      body:
          '근로자는 위 근무 시간을 준수하며, 정당한 사유 없이 결근·지각하지 않는다. 사전 통지 없는 결근은 1회당 평점 -0.5점 페널티가 부여된다.',
    ),
    _Clause(
      title: '임금 지급',
      body:
          '사용자는 약정한 임금을 지급방법(당일/익일)에 따라 정확히 지급한다. 정산 지연 시 일 0.05% 지연이자가 부과된다.',
    ),
    _Clause(
      title: '산재·상해',
      body:
          '근로 중 발생한 산재·상해는 산업재해보상보험법에 따라 처리한다. Sharework는 매 근무 1만원 한도의 단기 보장보험을 자동 부여한다.',
    ),
    _Clause(
      title: '분쟁 조정',
      body:
          '본 계약은 Sharework 플랫폼을 통해 체결되며, 분쟁 시 플랫폼 약관과 조정 절차를 따른다. 신청은 [고객센터 → 분쟁 조정]에서 접수.',
    ),
    _Clause(
      title: '준거 법령',
      body:
          '근로기준법, 최저임금법, 청소년 근로보호 등 관련 법령을 우선 적용한다. 만 18세 미만 근로자는 보호자 동의가 필요하다.',
    ),
  ];

  final Set<int> _understood = {};

  bool get _allUnderstood => _understood.length >= _clauses.length;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openSharePdf() {
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
                child: Text('계약서 공유',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.email_outlined, color: AppColors.brandDark),
              title: const Text('이메일로 받기'),
              subtitle:
                  const Text('가입 이메일로 PDF 발송', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('PDF가 이메일로 발송되었어요 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFFFEE500)),
              title: const Text('카카오톡으로 보내기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('카카오톡 공유 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.danger),
              title: const Text('PDF 다운로드'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('PDF 다운로드 시작 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('인쇄'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('인쇄 다이얼로그 (목업)');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openMoreMenu() {
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
              leading: const Icon(Icons.edit_calendar_outlined),
              title: const Text('변경 요청 보내기'),
              subtitle: const Text('일정·임금·식대·교통비 등 협의가 필요한 항목 요청',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _openChangeRequestSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('본인인증 다시 받기'),
              subtitle:
                  const Text('PASS / 카카오 / 지문', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('본인인증 흐름 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('이의 제기'),
              subtitle: const Text('계약서 내용에 동의할 수 없는 경우',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/support/dispute/new');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openChangeRequestSheet() {
    String topic = '일정 변경';
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (_, setSheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('계약 변경 요청',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                    '사장님께 변경 의견을 전달해요. 합의되면 새 계약서가 다시 발송돼요.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      '일정 변경',
                      '임금 협의',
                      '식대·교통비',
                      '근무 내용',
                      '기타',
                    ].map((t) {
                      final on = topic == t;
                      return ChoiceChip(
                        label: Text(t),
                        selected: on,
                        showCheckmark: false,
                        selectedColor: AppColors.brandDark,
                        labelStyle: TextStyle(
                          color: on ? Colors.white : AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => setSheet(() => topic = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: '예) "$topic"에 대해 어떤 조건으로 변경되면 좋을지 적어주세요',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      if (ctrl.text.trim().isEmpty) {
                        _snack('내용을 입력해주세요');
                        return;
                      }
                      Navigator.pop(sheetCtx);
                      _snack('변경 요청이 사장님께 전송되었어요 (목업)');
                    },
                    child: const Text('요청 보내기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    final me = Dummy.me;
    final signed = job.contractStatus == ContractStatus.signed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('전자근로계약서'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '공유',
            onPressed: _openSharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: '더보기',
            onPressed: _openMoreMenu,
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
              text: '서명 대기 · 5개 조항 모두 확인 후 서명 가능',
              color: AppColors.warning,
            ),
          const SizedBox(height: 16),

          // 핵심 4가지 하이라이트
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brandDark.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.lightbulb_outline,
                        color: AppColors.brandDark, size: 18),
                    SizedBox(width: 6),
                    Text('꼭 확인해주세요',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.brandDark)),
                  ],
                ),
                const SizedBox(height: 10),
                _highlight(Icons.payments_outlined, '임금',
                    '${job.payType} ${fmtMoney(job.pay)} · ${job.sameDayPayment ? "당일지급" : "익일 정산"}'),
                _highlight(
                  Icons.access_time,
                  '근무 시간',
                  '${fmtDate(job.startAt)} ${fmtTime(job.startAt)} ~ ${fmtTime(job.endAt)}',
                ),
                _highlight(Icons.calendar_today_outlined, '정산일',
                    job.sameDayPayment ? '근무 종료 후 자동' : '근무일 +1 영업일'),
                _highlight(Icons.shield_outlined, '산재 보장',
                    '플랫폼 단기보장보험 자동 가입 (1만원 한도)'),
              ],
            ),
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

          // 단계별 펼치기 동의
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_outlined,
                          color: AppColors.brandDark),
                      const SizedBox(width: 8),
                      const Text('주요 조항',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const Spacer(),
                      Text(
                        '${_understood.length}/${_clauses.length}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _allUnderstood
                                ? AppColors.brandDark
                                : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                ..._clauses.asMap().entries.map((e) {
                  final i = e.key;
                  final c = e.value;
                  final understood = _understood.contains(i);
                  return Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      leading: Icon(
                        understood
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: understood
                            ? AppColors.brandDark
                            : AppColors.textFaint,
                      ),
                      title: Text(
                        '${i + 1}. ${c.title}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color:
                              understood ? AppColors.brandDark : AppColors.text,
                        ),
                      ),
                      children: [
                        Text(c.body,
                            style: const TextStyle(fontSize: 13, height: 1.6)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                if (understood) {
                                  _understood.remove(i);
                                } else {
                                  _understood.add(i);
                                }
                              });
                            },
                            icon: Icon(
                              understood
                                  ? Icons.undo
                                  : Icons.check_circle_outline,
                              size: 16,
                            ),
                            label: Text(understood ? '취소' : '이해했어요'),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),
          if (signed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                                    fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _snack('PDF 다운로드 시작 (목업)');
                          },
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              size: 18),
                          label: const Text('PDF 다운'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _snack('PDF가 이메일로 발송되었어요 (목업)');
                          },
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('이메일로 받기'),
                        ),
                      ),
                    ],
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
                        onPressed: _allUnderstood
                            ? () => context
                                .push('/job/${widget.jobId}/contract/sign')
                            : null,
                        icon: const Icon(Icons.draw),
                        label: Text(_allUnderstood
                            ? '서명하기'
                            : '조항 ${_clauses.length - _understood.length}개 더 확인'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _highlight(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.brandDark),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _Clause {
  final String title;
  final String body;
  const _Clause({required this.title, required this.body});
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: color, fontSize: 13)),
          ),
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
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
