import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

enum _SignMethod { draw, text, fingerprint }

extension _SignMethodX on _SignMethod {
  String get label {
    switch (this) {
      case _SignMethod.draw:
        return '그리기';
      case _SignMethod.text:
        return '텍스트';
      case _SignMethod.fingerprint:
        return '지문';
    }
  }

  IconData get icon {
    switch (this) {
      case _SignMethod.draw:
        return Icons.draw;
      case _SignMethod.text:
        return Icons.text_fields;
      case _SignMethod.fingerprint:
        return Icons.fingerprint;
    }
  }
}

class ContractSignScreen extends StatefulWidget {
  final int jobId;
  const ContractSignScreen({super.key, required this.jobId});

  @override
  State<ContractSignScreen> createState() => _ContractSignScreenState();
}

class _ContractSignScreenState extends State<ContractSignScreen> {
  bool _agreeAll = false;
  bool _agreeMain = false;
  bool _agreePrivacy = false;
  final List<Offset?> _strokes = [];
  final _textCtrl = TextEditingController();
  bool _fingerprintConfirmed = false;
  bool _identityReverified = false;
  bool _isMinor = false;
  String? _guardianPhone;

  _SignMethod _method = _SignMethod.draw;

  bool get _hasSigned {
    switch (_method) {
      case _SignMethod.draw:
        return _strokes.isNotEmpty;
      case _SignMethod.text:
        return _textCtrl.text.trim().isNotEmpty;
      case _SignMethod.fingerprint:
        return _fingerprintConfirmed;
    }
  }

  bool get _canSubmit =>
      _agreeMain &&
      _agreePrivacy &&
      _hasSigned &&
      _identityReverified &&
      (!_isMinor || _guardianPhone != null);

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _reverifyIdentity() {
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
                child: Text('서명 전 본인인증',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ListTile(
              leading: _appIcon(Icons.security, const Color(0xFFE60000)),
              title: const Text('PASS'),
              subtitle: const Text('이동통신 3사 통합인증',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                setState(() => _identityReverified = true);
                _snack('PASS 인증 완료 (목업)');
              },
            ),
            ListTile(
              leading: _appIcon(Icons.chat_bubble, const Color(0xFFFEE500)),
              title: const Text('카카오 인증'),
              onTap: () {
                Navigator.pop(sheetCtx);
                setState(() => _identityReverified = true);
                _snack('카카오 인증 완료 (목업)');
              },
            ),
            ListTile(
              leading: _appIcon(Icons.fingerprint, AppColors.brandDark),
              title: const Text('지문·생체 인증'),
              onTap: () {
                Navigator.pop(sheetCtx);
                setState(() => _identityReverified = true);
                _snack('생체 인증 완료 (목업)');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _appIcon(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _openGuardianSheet() {
    final ctrl = TextEditingController(text: _guardianPhone ?? '');
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('보호자 동의',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  '만 18세 미만인 경우 보호자 휴대폰 번호를 입력해주세요. 인증 SMS가 발송되며 보호자가 동의하면 서명이 완료됩니다.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '010-0000-0000',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (ctrl.text.trim().length < 9) {
                      _snack('전화번호를 정확히 입력해주세요');
                      return;
                    }
                    Navigator.pop(sheetCtx);
                    setState(() => _guardianPhone = ctrl.text.trim());
                    _snack('보호자께 인증 SMS 발송 (목업)');
                  },
                  child: const Text('인증 SMS 발송'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_canSubmit) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('서명 제출 완료'),
        content: const Text('전자근로계약서가 양측에 자동 발송되었어요. 사본은 마이페이지에서 다운로드할 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _snack('PDF 다운로드 (목업)');
            },
            child: const Text('PDF 받기'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              context.go('/job/${widget.jobId}/contract');
            },
            child: const Text('계약서로'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전자서명'),
        actions: [
          if (_method == _SignMethod.draw && _hasSigned)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '다시 서명',
              onPressed: () => setState(() => _strokes.clear()),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agreeAll,
            onChanged: (v) => setState(() {
              _agreeAll = v ?? false;
              _agreeMain = _agreeAll;
              _agreePrivacy = _agreeAll;
            }),
            title: const Text('전체 동의',
                style: TextStyle(fontWeight: FontWeight.w800)),
            activeColor: AppColors.brandDark,
          ),
          const Divider(),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agreeMain,
            onChanged: (v) => setState(() {
              _agreeMain = v ?? false;
              _agreeAll = _agreeMain && _agreePrivacy;
            }),
            title: const Text('근로계약서 내용에 동의합니다 (필수)'),
            activeColor: AppColors.brandDark,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agreePrivacy,
            onChanged: (v) => setState(() {
              _agreePrivacy = v ?? false;
              _agreeAll = _agreeMain && _agreePrivacy;
            }),
            title: const Text('개인정보 제공 및 위탁 처리에 동의합니다 (필수)'),
            activeColor: AppColors.brandDark,
          ),
          const SizedBox(height: 12),

          // 보호자 동의 (미성년자)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isMinor,
                  activeColor: AppColors.brandDark,
                  title: const Text('만 18세 미만이에요',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                      '청소년 근로보호법에 따라 보호자 동의가 필요해요',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  onChanged: (v) => setState(() {
                    _isMinor = v;
                    if (!v) _guardianPhone = null;
                  }),
                ),
                if (_isMinor) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _guardianPhone == null
                              ? '보호자 휴대폰 번호 미입력'
                              : '보호자: $_guardianPhone (인증 대기)',
                          style: TextStyle(
                              fontSize: 12,
                              color: _guardianPhone == null
                                  ? AppColors.danger
                                  : AppColors.brandDark,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _openGuardianSheet,
                        child: Text(_guardianPhone == null ? '입력' : '변경'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 서명 방식 탭
          const Text('서명 방식',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: _SignMethod.values.map((m) {
              final on = _method == m;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _method = m),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: on ? AppColors.brandSoft : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: on
                              ? AppColors.brandDark
                              : AppColors.divider,
                          width: on ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(m.icon,
                              color: on
                                  ? AppColors.brandDark
                                  : AppColors.textMuted,
                              size: 22),
                          const SizedBox(height: 4),
                          Text(m.label,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: on
                                      ? AppColors.brandDark
                                      : AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          _signArea(),

          const SizedBox(height: 16),

          // 본인인증 재확인
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _identityReverified
                  ? AppColors.brandSoft
                  : const Color(0xFFFFF6E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _identityReverified
                      ? Icons.verified
                      : Icons.shield_outlined,
                  color: _identityReverified
                      ? AppColors.brandDark
                      : const Color(0xFFB45309),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _identityReverified
                            ? '본인인증 완료'
                            : '서명 전 본인인증이 필요해요',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: _identityReverified
                              ? AppColors.brandDark
                              : const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text('PASS · 카카오 · 지문 중 1가지',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (!_identityReverified)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 36),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    ),
                    onPressed: _reverifyIdentity,
                    child: const Text('인증'),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: const Text('서명 제출'),
          ),
        ),
      ),
    );
  }

  Widget _signArea() {
    switch (_method) {
      case _SignMethod.draw:
        return Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('아래 영역에 손가락(또는 마우스)으로 서명해주세요.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Stack(
                children: [
                  if (!_hasSigned)
                    const Center(
                      child: Text(
                        '여기에 서명',
                        style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  GestureDetector(
                    onPanStart: (d) =>
                        setState(() => _strokes.add(d.localPosition)),
                    onPanUpdate: (d) =>
                        setState(() => _strokes.add(d.localPosition)),
                    onPanEnd: (_) => setState(() => _strokes.add(null)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: _SignaturePainter(_strokes),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: _hasSigned
                      ? () => setState(() => _strokes.clear())
                      : null,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('지우기'),
                ),
              ],
            ),
          ],
        );
      case _SignMethod.text:
        return Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('이름을 입력하면 자동으로 손글씨 폰트가 적용돼요.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                _textCtrl.text.isEmpty ? '서명 미리보기' : _textCtrl.text,
                style: TextStyle(
                  fontSize: 36,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'cursive',
                  color: _textCtrl.text.isEmpty
                      ? AppColors.textFaint
                      : AppColors.text,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textCtrl,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '이름',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        );
      case _SignMethod.fingerprint:
        return Container(
          height: 220,
          decoration: BoxDecoration(
            color: _fingerprintConfirmed
                ? AppColors.brandSoft
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _fingerprintConfirmed
                  ? AppColors.brandDark
                  : AppColors.divider,
            ),
          ),
          child: InkWell(
            onTap: () {
              if (_fingerprintConfirmed) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Row(
                    children: [
                      Icon(Icons.fingerprint, color: AppColors.brandDark),
                      SizedBox(width: 8),
                      Text('생체 인증'),
                    ],
                  ),
                  content: const Text(
                      '기기에 등록된 지문 또는 Face ID로 서명해주세요.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(80, 40),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8)),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _fingerprintConfirmed = true);
                        _snack('생체 서명 완료 (목업)');
                      },
                      child: const Text('인증'),
                    ),
                  ],
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _fingerprintConfirmed
                        ? Icons.verified
                        : Icons.fingerprint,
                    size: 80,
                    color: _fingerprintConfirmed
                        ? AppColors.brandDark
                        : AppColors.textFaint,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fingerprintConfirmed ? '생체 서명 완료' : '눌러서 인증',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _fingerprintConfirmed
                          ? AppColors.brandDark
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.text
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) =>
      oldDelegate.points.length != points.length;
}
