import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

enum _Stage { target, reason, evidence, confirm, submitting, done }

class ReportScreen extends StatefulWidget {
  final String targetType; // user, job, review, chat
  final int targetId;
  const ReportScreen({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  _Stage _stage = _Stage.target;
  String? _reason;
  String? _subAnswer; // 사유별 추가 질문 답변
  final _detailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(); // 사기 사유의 금액
  final List<int> _photos = [];
  final List<String> _evidence = []; // 증거 카테고리: 사진/캡처/링크/대화
  bool _anonymous = false;
  bool _agreeToShare = true;
  String? _ticketNumber;
  bool _dirty = false;

  static const _evidenceTypes = ['사진', '캡처', '링크', '대화 인용'];

  @override
  void dispose() {
    _detailCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String get _targetLabel => switch (widget.targetType) {
        'user' => '사용자',
        'job' => '공고',
        'review' => '리뷰',
        'chat' => '채팅 메시지',
        _ => '대상',
      };

  IconData get _targetIcon => switch (widget.targetType) {
        'user' => Icons.person,
        'job' => Icons.work_outline,
        'review' => Icons.rate_review_outlined,
        'chat' => Icons.chat_bubble_outline,
        _ => Icons.report,
      };

  String get _targetName {
    // 더미 표시명
    switch (widget.targetType) {
      case 'user':
        return '사용자 ID #${widget.targetId}';
      case 'job':
        return '공고 #${widget.targetId} — 강남 카페 모카';
      case 'review':
        return '리뷰 #${widget.targetId}';
      case 'chat':
        return '메시지 #${widget.targetId}';
      default:
        return '대상 #${widget.targetId}';
    }
  }

  List<String> get _reasons => switch (widget.targetType) {
        'job' => const [
            '허위/과장 공고',
            '시급·근무조건 사기',
            '플랫폼 외 거래 유도',
            '불법·위험한 업무',
            '차별·혐오 표현',
            '중복 공고',
            '기타',
          ],
        'chat' => const [
            '욕설/모욕',
            '성희롱·부적절한 발언',
            '플랫폼 외 거래 요구',
            '광고/스팸',
            '협박·괴롭힘',
            '미성년자 대상 부적절',
            '기타',
          ],
        'review' => const [
            '사실과 다른 내용',
            '욕설·인신공격',
            '광고·홍보',
            '경쟁사 비방',
            '개인정보 노출',
            '기타',
          ],
        _ => const [
            '욕설/모욕',
            '성희롱',
            '잠수·노쇼',
            '계약과 다른 업무 요구',
            '플랫폼 외 거래 유도',
            '사기·갈취 시도',
            '신원 도용',
            '기타',
          ],
      };

  bool get _reasonNeedsSub =>
      _reason == '시급·근무조건 사기' ||
      _reason == '사기·갈취 시도' ||
      _reason == '플랫폼 외 거래 유도' ||
      _reason == '플랫폼 외 거래 요구';

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<bool> _confirmExit() async {
    if (!_dirty || _stage == _Stage.done) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('신고 작성을 중단할까요?'),
        content: const Text('지금까지 입력한 내용은 임시저장에 보관됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 작성'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('임시저장 되었어요 (목업)')),
              );
              Navigator.pop(context, true);
            },
            child: const Text('임시저장 후 나가기'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _next() {
    setState(() {
      switch (_stage) {
        case _Stage.target:
          _stage = _Stage.reason;
          break;
        case _Stage.reason:
          if (_reasonNeedsSub) {
            _showSubQuestion();
          } else {
            _stage = _Stage.evidence;
          }
          break;
        case _Stage.evidence:
          _stage = _Stage.confirm;
          break;
        case _Stage.confirm:
          _submit();
          break;
        case _Stage.submitting:
        case _Stage.done:
          break;
      }
    });
  }

  void _back() {
    setState(() {
      switch (_stage) {
        case _Stage.reason:
          _stage = _Stage.target;
          break;
        case _Stage.evidence:
          _stage = _Stage.reason;
          break;
        case _Stage.confirm:
          _stage = _Stage.evidence;
          break;
        default:
          break;
      }
    });
  }

  void _showSubQuestion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_reason — 추가 질문',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (_reason == '시급·근무조건 사기' ||
                _reason == '사기·갈취 시도') ...[
              const Text('관련 금액 (선택)',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '예) 50000',
                  prefixText: '₩ ',
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text('어떤 상황이었나요? (선택)',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final opt in _subOptions)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(opt, style: const TextStyle(fontSize: 13)),
                value: opt,
                groupValue: _subAnswer,
                activeColor: AppColors.brandDark,
                onChanged: (v) {
                  setState(() => _subAnswer = v);
                },
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.pop(sheetCtx);
                setState(() => _stage = _Stage.evidence);
              },
              child: const Text('다음 — 증거 첨부'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _subOptions {
    if (_reason == '시급·근무조건 사기') {
      return const [
        '공고와 다른 시급을 받음',
        '근무 시간이 다름',
        '약속한 식대·교통비 미지급',
        '추가 업무를 강요받음',
      ];
    }
    if (_reason == '사기·갈취 시도') {
      return const [
        '선결제·보증금 요구',
        '교육비·물품비 요구',
        '계좌이체 후 잠수',
        '명의도용 가능성',
      ];
    }
    return const [
      '카카오톡으로 거래 유도',
      '계좌이체 직거래 유도',
      '현금 결제 요구',
      '기타 외부 결제 시도',
    ];
  }

  void _showEvidenceTypeSheet() {
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
              const Text('증거 종류',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _evidenceTile(Icons.photo_camera, '사진', () {
                    Navigator.pop(sheetCtx);
                    setState(() {
                      _photos.add(_photos.length + 1);
                      _evidence.add('사진');
                    });
                    _markDirty();
                  }),
                  _evidenceTile(Icons.screenshot, '캡처', () {
                    Navigator.pop(sheetCtx);
                    setState(() {
                      _photos.add(_photos.length + 1);
                      _evidence.add('캡처');
                    });
                    _markDirty();
                  }),
                  _evidenceTile(Icons.link, '링크', () {
                    Navigator.pop(sheetCtx);
                    _showLinkDialog();
                  }),
                  _evidenceTile(Icons.format_quote, '대화 인용', () {
                    Navigator.pop(sheetCtx);
                    _showQuoteDialog();
                  }),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security,
                        size: 16, color: AppColors.brandDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '제출된 증거는 검토 담당자만 열람할 수 있고, 검토 후 30일 안에 파기됩니다.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.brandDark),
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

  Widget _evidenceTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.brandDark),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showLinkDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('링크 첨부'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              setState(() => _evidence.add('링크: ${ctrl.text.trim()}'));
              _markDirty();
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showQuoteDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('대화 인용'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: '문제가 된 부분을 그대로 옮겨주세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              setState(
                  () => _evidence.add('인용: "${ctrl.text.trim()}"'));
              _markDirty();
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showMore() {
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
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.save_outlined,
                  color: AppColors.brandDark),
              title: const Text('임시저장'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('임시저장 되었어요 (목업)')),
                );
                setState(() => _dirty = false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined,
                  color: AppColors.brandDark),
              title: const Text('신고 가이드'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showGuide();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history,
                  color: AppColors.brandDark),
              title: const Text('이전 신고 내역'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이전 신고 5건 (목업)')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.danger),
              title: const Text('취소', style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(sheetCtx);
                final ok = await _confirmExit();
                if (ok && mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              const Text('신고 가이드',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final t in const [
                ['검토 시간', '평균 4시간, 최대 24시간 내 답변'],
                ['신고자 보호', '신고자 신원은 검토 담당자만 알 수 있고, 신고 대상에는 비공개'],
                ['허위 신고', '반복적인 허위 신고는 계정 제재 사유'],
                ['긴급 신고', '신변 위협이 있는 경우 112와 함께 신고센터 즉시 연락'],
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: AppColors.brandDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.text),
                            children: [
                              TextSpan(
                                  text: '${t[0]} · ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              TextSpan(text: t[1]),
                            ],
                          ),
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

  void _submit() {
    setState(() => _stage = _Stage.submitting);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.done;
        _ticketNumber =
            'R${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _Stage.done) {
      return _buildDone();
    }
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmExit();
        if (ok && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('$_targetLabel 신고'),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showMore,
            ),
          ],
        ),
        body: Column(
          children: [
            _StepBar(active: _stage.index),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildStageBody(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                if (_stage != _Stage.target) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _back,
                      child: const Text('이전'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _stage == _Stage.confirm
                          ? AppColors.danger
                          : AppColors.brandDark,
                    ),
                    onPressed: _stage == _Stage.submitting
                        ? null
                        : _canProceed
                            ? _next
                            : null,
                    child: Text(switch (_stage) {
                      _Stage.target => '신고 사유 선택',
                      _Stage.reason => '다음 — 증거 첨부',
                      _Stage.evidence => '다음 — 제출 확인',
                      _Stage.confirm => '신고하기',
                      _Stage.submitting => '제출 중…',
                      _Stage.done => '닫기',
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canProceed => switch (_stage) {
        _Stage.target => true,
        _Stage.reason => _reason != null,
        _Stage.evidence => true,
        _Stage.confirm => _agreeToShare,
        _ => false,
      };

  Widget _buildStageBody() {
    switch (_stage) {
      case _Stage.target:
        return _buildTargetStage();
      case _Stage.reason:
        return _buildReasonStage();
      case _Stage.evidence:
        return _buildEvidenceStage();
      case _Stage.confirm:
        return _buildConfirmStage();
      case _Stage.submitting:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('신고를 접수하는 중이에요…'),
            ],
          ),
        );
      case _Stage.done:
        return const SizedBox();
    }
  }

  Widget _buildTargetStage() {
    return ListView(
      key: const ValueKey('target'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        const Text('신고 대상 확인',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('아래 정보가 신고하려는 대상이 맞나요?',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.brandSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_targetIcon,
                        color: AppColors.brandDark, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_targetName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Text('신고 대상: $_targetLabel',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      switch (widget.targetType) {
                        'user' => '사용자가 정확한지 확인 후 다음으로 진행해주세요. 잘못된 사용자 신고는 허위 신고로 간주될 수 있어요.',
                        'job' => '공고 내용을 다시 확인하고 사실과 다른 부분이 있는지 검토해주세요.',
                        'review' => '리뷰 내용을 한 번 더 확인하고, 단순 의견 차이는 신고 대상이 아니에요.',
                        _ => '신고 대상 정보를 확인해주세요.',
                      },
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
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
                  color: AppColors.brandDark, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '신고자의 정보는 비공개로 유지되며, 검토 결과는 알림으로 안내드립니다.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonStage() {
    return ListView(
      key: const ValueKey('reason'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        const Text('신고 사유',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('가장 가까운 사유를 선택해주세요',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        for (final r in _reasons)
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(r),
            value: r,
            groupValue: _reason,
            activeColor: AppColors.brandDark,
            onChanged: (v) {
              setState(() => _reason = v);
              _markDirty();
            },
          ),
        const SizedBox(height: 16),
        const Text('상세 내용 (선택)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: _detailCtrl,
          maxLines: 5,
          maxLength: 500,
          onChanged: (_) => _markDirty(),
          decoration: const InputDecoration(
            hintText: '신고 사유를 더 자세히 적어주시면 검토에 도움이 됩니다.',
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceStage() {
    return ListView(
      key: const ValueKey('evidence'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        const Text('증거 첨부',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('관련 사진·캡처·링크·대화 내용을 첨부할 수 있어요',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        if (_evidence.isEmpty && _photos.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Icon(Icons.attach_file,
                    size: 36, color: AppColors.textFaint),
                const SizedBox(height: 8),
                const Text('첨부된 증거가 없어요',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _showEvidenceTypeSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('증거 추가'),
                ),
              ],
            ),
          )
        else ...[
          if (_photos.isNotEmpty) ...[
            const Text('첨부 이미지',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._photos.map((i) => Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text('#$i',
                              style: const TextStyle(
                                  color: AppColors.brandDark,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Positioned(
                          top: 2, right: 2,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _photos.remove(i);
                                _evidence.removeWhere((e) =>
                                    e == '사진' || e == '캡처');
                              });
                            },
                            child: Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 12),
          ],
          for (final e in _evidence
              .where((x) => !_evidenceTypes.contains(x))
              .toList())
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    e.startsWith('링크')
                        ? Icons.link
                        : Icons.format_quote,
                    size: 16,
                    color: AppColors.brandDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() => _evidence.remove(e));
                    },
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: _showEvidenceTypeSheet,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('증거 더 추가'),
          ),
        ],
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _anonymous,
          activeColor: AppColors.brandDark,
          title: const Text('익명 제보로 처리',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          subtitle: const Text('내부 검토용 신원만 보관, 결과 알림은 받지 않아요',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          onChanged: (v) => setState(() => _anonymous = v),
        ),
      ],
    );
  }

  Widget _buildConfirmStage() {
    return ListView(
      key: const ValueKey('confirm'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        const Text('제출 확인',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(label: '대상', value: '$_targetLabel — $_targetName'),
              _SummaryRow(label: '사유', value: _reason ?? '-'),
              if (_subAnswer != null)
                _SummaryRow(label: '추가 정보', value: _subAnswer!),
              if (_amountCtrl.text.isNotEmpty)
                _SummaryRow(label: '관련 금액', value: '₩ ${_amountCtrl.text}'),
              if (_detailCtrl.text.isNotEmpty)
                _SummaryRow(
                    label: '상세 내용',
                    value: _detailCtrl.text.length > 80
                        ? '${_detailCtrl.text.substring(0, 80)}...'
                        : _detailCtrl.text),
              _SummaryRow(
                  label: '증거',
                  value:
                      '${_photos.length}개 이미지 + ${_evidence.where((e) => !_evidenceTypes.contains(e)).length}개 텍스트'),
              _SummaryRow(
                  label: '제출 방식', value: _anonymous ? '익명 제보' : '실명 제보'),
            ],
          ),
        ),
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
              const Row(
                children: [
                  Icon(Icons.access_time,
                      size: 18, color: AppColors.brandDark),
                  SizedBox(width: 8),
                  Text('처리 안내',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandDark)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('• 평균 4시간, 최대 24시간 내 검토',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(_anonymous
                  ? '• 익명 제보이므로 결과 알림은 보내드리지 않아요'
                  : '• 검토 결과는 푸시·이메일로 안내드려요',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              const Text('• 추가 확인이 필요하면 채팅 또는 이메일로 연락드려요',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('신고 내용을 검토자에게 공유하는 것에 동의합니다 (필수)',
              style: TextStyle(fontSize: 13)),
          value: _agreeToShare,
          activeColor: AppColors.brandDark,
          onChanged: (v) => setState(() => _agreeToShare = v ?? false),
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신고 접수 완료'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_circle,
                color: AppColors.success, size: 56),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('신고가 접수되었어요',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _anonymous
                  ? '익명으로 처리됩니다. 검토에는 평균 4시간이 걸려요.'
                  : '검토 결과는 알림으로 안내드릴게요.',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 20),
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
                Row(
                  children: [
                    const Text('접수번호',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted)),
                    const Spacer(),
                    Text(_ticketNumber ?? '-',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark)),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '${_ticketNumber} 복사됨 (목업)')),
                        );
                      },
                      child: const Icon(Icons.copy,
                          size: 16, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatusTimeline(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('닫기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    context.pop();
                    context.push('/support/inquiry/new');
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('추가 문의'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int active;
  const _StepBar({required this.active});

  @override
  Widget build(BuildContext context) {
    final steps = const ['대상', '사유', '증거', '확인'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
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
                width: 26, height: 26,
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
                            color: on
                                ? Colors.white
                                : AppColors.textFaint,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              Text(steps[idx],
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: on
                          ? AppColors.text
                          : AppColors.textFaint)),
            ],
          );
        }),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

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
                    fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = const [
      ['접수', '신고가 접수됨', true],
      ['확인 중', '담당자 배정 대기', false],
      ['검토', '증거 검토·당사자 확인', false],
      ['완료', '결과 통보 및 조치', false],
    ];
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: (steps[i][2] as bool)
                          ? AppColors.success
                          : AppColors.chipBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (steps[i][2] as bool)
                            ? AppColors.success
                            : AppColors.divider,
                      ),
                    ),
                    child: (steps[i][2] as bool)
                        ? const Icon(Icons.check,
                            size: 10, color: Colors.white)
                        : null,
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2, height: 24,
                      color: AppColors.divider,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i][0] as String,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: (steps[i][2] as bool)
                                  ? AppColors.text
                                  : AppColors.textMuted)),
                      Text(steps[i][1] as String,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textFaint)),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
