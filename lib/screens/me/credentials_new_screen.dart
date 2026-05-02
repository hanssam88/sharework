import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

enum _SubmitPhase { editing, submitting, queued, autoCheck, manualCheck, done }

class CredentialsNewScreen extends StatefulWidget {
  const CredentialsNewScreen({super.key});

  @override
  State<CredentialsNewScreen> createState() => _CredentialsNewScreenState();
}

class _CredentialsNewScreenState extends State<CredentialsNewScreen> {
  CredentialKind _kind = CredentialKind.barista;
  final _memoCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  DateTime? _issuedAt;
  DateTime? _expiresAt;
  bool _photoAttached = false;
  bool _ocrApplied = false;
  bool _agreeTerms = false;
  bool _agreeShare = false;
  bool _notifyOnReview = true;
  _SubmitPhase _phase = _SubmitPhase.editing;
  bool _dirty = false;

  static const Map<String, List<CredentialKind>> _categories = {
    '신분·운전': [CredentialKind.idCard, CredentialKind.driverLicense],
    '식음·위생': [CredentialKind.barista, CredentialKind.cookCert,
                   CredentialKind.hygieneEdu, CredentialKind.health],
    '산업': [CredentialKind.forkLift],
    '기타': [CredentialKind.etc],
  };

  @override
  void dispose() {
    _memoCtrl.dispose();
    _orgCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickDate(bool issued) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        if (issued) {
          _issuedAt = picked;
        } else {
          _expiresAt = picked;
        }
      });
      _markDirty();
    }
  }

  String _fmt(DateTime? d) => d == null
      ? '선택 안 됨'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<bool> _confirmExit() async {
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('작성 중인 내용이 있어요'),
        content: const Text('나가면 임시저장에 보관됩니다.'),
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

  void _showKindSheet() {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('서류 종류 선택',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                for (final entry in _categories.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(entry.key,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700)),
                  ),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                    children: entry.value
                        .map((k) => InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() => _kind = k);
                                _markDirty();
                                Navigator.pop(sheetCtx);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _kind == k
                                      ? AppColors.brandSoft
                                      : AppColors.bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _kind == k
                                        ? AppColors.brandDark
                                        : AppColors.divider,
                                    width: _kind == k ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(k.icon,
                                        color: AppColors.brandDark,
                                        size: 28),
                                    const SizedBox(height: 6),
                                    Text(k.label,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOcrSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (innerCtx, innerSet) {
          int step = 0; // 0=guide, 1=preview, 2=fields
          return Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.center_focus_strong,
                          color: AppColors.brandDark),
                      const SizedBox(width: 8),
                      Text(
                        ['촬영 가이드', '인식 결과 확인', '항목 수정'][step],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (step == 0) ...[
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: Colors.white54, size: 48),
                          Positioned(
                            top: 24, left: 24, right: 24, bottom: 24,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.fromBorderSide(BorderSide(
                                    color: AppColors.brand, width: 2)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _GuideTip(
                        icon: Icons.wb_sunny_outlined,
                        text: '밝은 곳에서 그림자 없이 촬영해주세요'),
                    const _GuideTip(
                        icon: Icons.crop_free,
                        text: '문서 모서리가 화면 안에 모두 들어오게'),
                    const _GuideTip(
                        icon: Icons.image_not_supported_outlined,
                        text: '글자가 가려지지 않도록 손가락 위치 주의'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => innerSet(() => step = 1),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('카메라 열기 (목업)'),
                    ),
                  ] else if (step == 1) ...[
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 56, color: AppColors.success),
                          SizedBox(height: 8),
                          Text('인식 완료',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandDark)),
                          SizedBox(height: 4),
                          Text('자동으로 항목을 채워드릴게요',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => innerSet(() => step = 2),
                      child: const Text('다음 — 항목 확인'),
                    ),
                  ] else ...[
                    const _OcrField(label: '발급기관', value: '한국식품 직업전문학교'),
                    const _OcrField(label: '등급', value: '2급'),
                    const _OcrField(label: '발급일', value: '2024-03-15'),
                    const _OcrField(label: '만료일', value: '없음'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _ocrApplied = true;
                          _photoAttached = true;
                          _orgCtrl.text = '한국식품 직업전문학교';
                          _gradeCtrl.text = '2급';
                          _issuedAt = DateTime(2024, 3, 15);
                          _dirty = true;
                        });
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('항목이 자동으로 채워졌어요')),
                        );
                      },
                      child: const Text('적용'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFastActions() {
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
              const Text('빠른 작업',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _quickTile(Icons.add, '다른 서류', () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('서류를 추가로 등록할게요 (목업)')),
                    );
                  }),
                  _quickTile(Icons.notifications_active_outlined, '알림 받기',
                      () {
                    setState(() => _notifyOnReview = !_notifyOnReview);
                    Navigator.pop(sheetCtx);
                  }),
                  _quickTile(Icons.help_outline, '도움말', () {
                    Navigator.pop(sheetCtx);
                    _showHelp();
                  }),
                  _quickTile(Icons.support_agent, '문의', () {
                    Navigator.pop(sheetCtx);
                    context.push('/support/inquiry/new');
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickTile(IconData icon, String label, VoidCallback onTap) {
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

  void _showHelp() {
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
              const Text('자격증 등록 안내',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final t in const [
                ['검증 절차', '제출 → 자동검증 → 수동검토 → 완료까지 평균 1~2 영업일'],
                ['서류 형식', 'JPG·PNG·PDF (최대 10MB)'],
                ['반려 사유', '글자 흐림 / 만료 / 본인 정보 불일치'],
                ['보안', '제출 서류는 검증 후 30일 안에 안전하게 파기됩니다'],
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
    if (_issuedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('발급일을 선택해주세요')),
      );
      return;
    }
    if (!_photoAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서류 사진을 첨부해주세요')),
      );
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해주세요')),
      );
      return;
    }
    setState(() => _phase = _SubmitPhase.submitting);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _phase = _SubmitPhase.queued);
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _phase = _SubmitPhase.autoCheck);
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _phase = _SubmitPhase.manualCheck);
    });
  }

  void _showStepperSheet() {
    final steps = const [
      ['접수', '제출이 정상적으로 접수되었어요'],
      ['자동 검증', '서류 형식과 만료 여부를 자동으로 확인합니다'],
      ['수동 검토', '담당자가 본인 정보와 서류를 대조해요'],
      ['완료', '인증 배지가 부여되고 알림으로 안내드립니다'],
    ];
    int active = 0;
    switch (_phase) {
      case _SubmitPhase.editing:
      case _SubmitPhase.submitting:
      case _SubmitPhase.queued:
        active = 0;
        break;
      case _SubmitPhase.autoCheck:
        active = 1;
        break;
      case _SubmitPhase.manualCheck:
        active = 2;
        break;
      case _SubmitPhase.done:
        active = 3;
        break;
    }
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_kind.icon, color: AppColors.brandDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_kind.label} 등록 진행 중',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      const Text('예상 소요: 1~2 영업일',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: i < active
                            ? AppColors.success
                            : (i == active
                                ? AppColors.brandDark
                                : AppColors.chipBg),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: i < active
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : Text('${i + 1}',
                              style: TextStyle(
                                color: i == active
                                    ? Colors.white
                                    : AppColors.textFaint,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i][0],
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: i <= active
                                      ? AppColors.text
                                      : AppColors.textFaint)),
                          const SizedBox(height: 2),
                          Text(steps[i][1],
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _notifyOnReview
                          ? '검토가 완료되면 알림으로 알려드릴게요'
                          : '진행 중에는 알림을 받지 않아요',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _showFastActions();
                    },
                    child: const Text('빠른 작업'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      context.pop();
                    },
                    child: const Text('닫기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase != _SubmitPhase.editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ModalRoute.of(context)?.isCurrent == true) {
          _showStepperSheet();
          setState(() => _phase = _SubmitPhase.editing);
        }
      });
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
          title: const Text('서류 등록'),
          actions: [
            if (_dirty)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('임시저장 되었어요 (목업)')),
                  );
                  setState(() => _dirty = false);
                },
                child: const Text('임시저장'),
              ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelp,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const _Label('서류 종류'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showKindSheet,
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
                    Icon(_kind.icon,
                        color: AppColors.brandDark, size: 20),
                    const SizedBox(width: 10),
                    Text(_kind.label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _Label('서류 사진'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _photoAttached = !_photoAttached);
                      _markDirty();
                    },
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _photoAttached
                              ? AppColors.brandDark
                              : AppColors.divider,
                          width: _photoAttached ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _photoAttached
                                ? Icons.check_circle
                                : Icons.add_a_photo_outlined,
                            size: 36,
                            color: _photoAttached
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _photoAttached
                                ? '서류 첨부됨 (목업)'
                                : '갤러리·카메라',
                            style: TextStyle(
                              fontSize: 12,
                              color: _photoAttached
                                  ? AppColors.brandDark
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _showOcrSheet,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _ocrApplied
                              ? AppColors.brandDark
                              : AppColors.brandSoft,
                          width: _ocrApplied ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _ocrApplied
                                ? Icons.check_circle
                                : Icons.center_focus_strong,
                            size: 36,
                            color: _ocrApplied
                                ? AppColors.success
                                : AppColors.brandDark,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _ocrApplied
                                ? 'OCR 자동 인식 완료'
                                : 'OCR 자동 인식',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.brandDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_ocrApplied)
                            const Text('빠른 입력',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('발급일'),
                      const SizedBox(height: 8),
                      _DateField(
                        value: _fmt(_issuedAt),
                        onTap: () => _pickDate(true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('만료일 (선택)'),
                      const SizedBox(height: 8),
                      _DateField(
                        value: _fmt(_expiresAt),
                        onTap: () => _pickDate(false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _Label('발급기관 (선택)'),
            const SizedBox(height: 8),
            TextField(
              controller: _orgCtrl,
              onChanged: (_) => _markDirty(),
              decoration: const InputDecoration(
                hintText: '예) 한국식품 직업전문학교',
              ),
            ),
            const SizedBox(height: 16),
            const _Label('등급·번호 (선택)'),
            const SizedBox(height: 8),
            TextField(
              controller: _gradeCtrl,
              onChanged: (_) => _markDirty(),
              decoration: const InputDecoration(
                hintText: '예) 2급 / 자격번호',
              ),
            ),
            const SizedBox(height: 16),
            const _Label('메모 (선택)'),
            const SizedBox(height: 8),
            TextField(
              controller: _memoCtrl,
              onChanged: (_) => _markDirty(),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '심사자에게 전할 추가 정보',
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
                  const Text('약관 동의',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('(필수) 본인이 직접 발급받은 서류임을 확인합니다',
                        style: TextStyle(fontSize: 13)),
                    value: _agreeTerms,
                    activeColor: AppColors.brandDark,
                    onChanged: (v) {
                      setState(() => _agreeTerms = v ?? false);
                      _markDirty();
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('(선택) 인증 배지를 프로필에 공개합니다',
                        style: TextStyle(fontSize: 13)),
                    value: _agreeShare,
                    activeColor: AppColors.brandDark,
                    onChanged: (v) {
                      setState(() => _agreeShare = v ?? false);
                      _markDirty();
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('검토 완료 시 알림 받기',
                        style: TextStyle(fontSize: 13)),
                    value: _notifyOnReview,
                    activeColor: AppColors.brandDark,
                    onChanged: (v) =>
                        setState(() => _notifyOnReview = v ?? true),
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '제출된 서류는 검토 후 인증 배지가 부여됩니다. 만료 30일 전 알림으로 안내해드려요.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFastActions,
                    icon: const Icon(Icons.dashboard_customize_outlined,
                        size: 18),
                    label: const Text('빠른 작업'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _phase == _SubmitPhase.editing ? _submit : null,
                    child: Text(_phase == _SubmitPhase.editing
                        ? '등록 신청'
                        : '검토 진행 중'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14));
  }
}

class _DateField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const _DateField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideTip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _GuideTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.brandDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}

class _OcrField extends StatelessWidget {
  final String label;
  final String value;
  const _OcrField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const Icon(Icons.edit_outlined,
              size: 16, color: AppColors.textFaint),
        ],
      ),
    );
  }
}
