import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

enum _Step { intro, method, capture, ocr, edit, complete }

enum _IdMethod {
  residentCard,
  driverLicense,
  passport,
  foreignerCard,
  pass,
  kakao
}

extension _IdMethodX on _IdMethod {
  String get label {
    switch (this) {
      case _IdMethod.residentCard:
        return '주민등록증';
      case _IdMethod.driverLicense:
        return '운전면허증';
      case _IdMethod.passport:
        return '여권';
      case _IdMethod.foreignerCard:
        return '외국인등록증';
      case _IdMethod.pass:
        return 'PASS 인증';
      case _IdMethod.kakao:
        return '카카오 인증';
    }
  }

  IconData get icon {
    switch (this) {
      case _IdMethod.residentCard:
        return Icons.badge_outlined;
      case _IdMethod.driverLicense:
        return Icons.directions_car_outlined;
      case _IdMethod.passport:
        return Icons.flight_takeoff;
      case _IdMethod.foreignerCard:
        return Icons.public;
      case _IdMethod.pass:
        return Icons.security;
      case _IdMethod.kakao:
        return Icons.chat_bubble;
    }
  }

  bool get isCertApp => this == _IdMethod.pass || this == _IdMethod.kakao;
}

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  _Step _step = _Step.intro;
  _IdMethod _method = _IdMethod.residentCard;
  bool _isMinor = false;
  String? _guardianPhone;

  final _nameCtrl = TextEditingController(text: '김알바');
  final _birthCtrl = TextEditingController(text: '1995-08-12');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _next() {
    setState(() {
      switch (_step) {
        case _Step.intro:
          _step = _Step.method;
          break;
        case _Step.method:
          if (_method.isCertApp) {
            // 인증앱은 자동 흐름
            _step = _Step.ocr;
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) setState(() => _step = _Step.edit);
            });
          } else {
            _step = _Step.capture;
          }
          break;
        case _Step.capture:
          _step = _Step.ocr;
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) setState(() => _step = _Step.edit);
          });
          break;
        case _Step.ocr:
          break;
        case _Step.edit:
          if (_isMinor && _guardianPhone == null) {
            _snack('보호자 휴대폰 번호를 입력해주세요');
            return;
          }
          _step = _Step.complete;
          break;
        case _Step.complete:
          context.go('/worker');
          break;
      }
    });
  }

  void _skip() {
    _snack('나중에 마이페이지에서 인증할 수 있어요');
    context.go('/worker');
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  '청소년 근로보호법에 따라 만 18세 미만은 보호자 휴대폰 인증이 필요해요.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('본인인증'),
        actions: [
          if (_step != _Step.complete)
            TextButton(
              onPressed: _skip,
              child: const Text('나중에'),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _content(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _step == _Step.ocr ? null : _next,
            child: Text(_buttonLabel),
          ),
        ),
      ),
    );
  }

  String get _buttonLabel {
    switch (_step) {
      case _Step.intro:
        return '인증 시작하기';
      case _Step.method:
        return _method.isCertApp
            ? '${_method.label}으로 인증'
            : '${_method.label} 촬영';
      case _Step.capture:
        return '촬영 완료';
      case _Step.ocr:
        return _method.isCertApp ? '인증 진행 중...' : 'OCR 분석 중...';
      case _Step.edit:
        return '확인 완료';
      case _Step.complete:
        return '시작하기';
    }
  }

  Widget _content() {
    switch (_step) {
      case _Step.intro:
        return _intro();
      case _Step.method:
        return _methodPicker();
      case _Step.capture:
        return _capture();
      case _Step.ocr:
        return Center(
          key: const ValueKey('ocr'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandDark),
              const SizedBox(height: 20),
              Text(
                _method.isCertApp
                    ? '${_method.label} 진행 중...'
                    : '신분증 정보 분석 중...',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('보통 5초 이내 완료됩니다',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        );
      case _Step.edit:
        return _editForm();
      case _Step.complete:
        return _complete();
    }
  }

  Widget _intro() {
    return ListView(
      key: const ValueKey('intro'),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.verified_user_outlined,
              size: 80, color: AppColors.brandDark),
        ),
        const SizedBox(height: 24),
        const Text(
          '안전한 거래를 위해\n본인인증이 필요해요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          '신분증 또는 인증앱(PASS/카카오)으로 인증을 완료하면\n구인자에게 더 신뢰받을 수 있어요.',
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
        ),
        const SizedBox(height: 28),
        const _BulletRow(
            icon: Icons.shield_outlined, text: '신분증 사본은 암호화되어 저장됩니다'),
        const _BulletRow(
            icon: Icons.text_snippet_outlined, text: 'OCR로 자동 추출한 정보만 사용해요'),
        const _BulletRow(
            icon: Icons.delete_outline, text: '인증 완료 후 사본 이미지는 즉시 삭제됩니다'),
      ],
    );
  }

  Widget _methodPicker() {
    return ListView(
      key: const ValueKey('method'),
      padding: const EdgeInsets.all(20),
      children: [
        const Text('인증 방식 선택',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('가장 편한 방법을 선택해주세요. 한 가지만 인증하면 돼요.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        const _SectionLabel('인증앱 (가장 빠름)'),
        _methodCard(
          method: _IdMethod.pass,
          desc: '이동통신 3사 통합 · 5초',
          color: const Color(0xFFE60000),
        ),
        const SizedBox(height: 8),
        _methodCard(
          method: _IdMethod.kakao,
          desc: '카카오톡으로 즉시 · 5초',
          color: const Color(0xFFFEE500),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('신분증 촬영'),
        _methodCard(
          method: _IdMethod.residentCard,
          desc: '대한민국 주민등록증',
          color: AppColors.brandSoft,
        ),
        const SizedBox(height: 8),
        _methodCard(
          method: _IdMethod.driverLicense,
          desc: '1종·2종 운전면허증',
          color: AppColors.brandSoft,
        ),
        const SizedBox(height: 8),
        _methodCard(
          method: _IdMethod.passport,
          desc: '대한민국 여권',
          color: AppColors.brandSoft,
        ),
        const SizedBox(height: 8),
        _methodCard(
          method: _IdMethod.foreignerCard,
          desc: '외국인등록증 (E-9, F-2 등)',
          color: AppColors.brandSoft,
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isMinor,
          activeColor: AppColors.brandDark,
          title: const Text('만 18세 미만이에요',
              style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('청소년 근로보호법에 따라 보호자 동의가 필요해요',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          onChanged: (v) => setState(() {
            _isMinor = v;
            if (!v) _guardianPhone = null;
          }),
        ),
        if (_isMinor) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _guardianPhone == null
                        ? '보호자 휴대폰 번호 미입력'
                        : '보호자 $_guardianPhone',
                    style: TextStyle(
                      fontSize: 12,
                      color: _guardianPhone == null
                          ? AppColors.danger
                          : AppColors.brandDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _openGuardianSheet,
                  child: Text(_guardianPhone == null ? '입력' : '변경'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _methodCard({
    required _IdMethod method,
    required String desc,
    required Color color,
  }) {
    final on = _method == method;
    return InkWell(
      onTap: () => setState(() => _method = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: on ? AppColors.brandSoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? AppColors.brandDark : AppColors.divider,
            width: on ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(method.icon, color: AppColors.brandDark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (on) const Icon(Icons.check_circle, color: AppColors.brandDark),
          ],
        ),
      ),
    );
  }

  Widget _capture() {
    return ListView(
      key: const ValueKey('capture'),
      children: [
        Container(
          color: Colors.black,
          height: 380,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 280,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.brand, width: 2.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${_method.label}을\n프레임에 맞춰주세요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Positioned(
                bottom: 16,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brand, width: 4),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                '${_method.label} 촬영',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '빛 반사가 없도록 평평한 곳에 두고 촬영해요. 글자가 또렷하게 보이도록 정렬해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _snack('갤러리에서 선택 (목업)'),
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('갤러리'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _snack('자동 촬영 모드 (목업)'),
                      icon: const Icon(Icons.flash_auto, size: 18),
                      label: const Text('자동 촬영'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editForm() {
    return ListView(
      key: const ValueKey('edit'),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.task_alt, color: AppColors.brandDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_method.label} 인증 정보 추출 완료. 정확한지 확인해주세요.',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('이름',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        TextField(controller: _nameCtrl),
        const SizedBox(height: 16),
        const Text('생년월일',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        TextField(controller: _birthCtrl),
        const SizedBox(height: 16),
        if (_isMinor)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.family_restroom, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _guardianPhone == null
                        ? '보호자 인증 미완료'
                        : '보호자 $_guardianPhone — 인증 대기 중',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w700),
                  ),
                ),
                if (_guardianPhone == null)
                  TextButton(
                    onPressed: _openGuardianSheet,
                    child: const Text('입력'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _complete() {
    return ListView(
      key: const ValueKey('done'),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Icon(Icons.check_circle,
              size: 100, color: AppColors.success),
        ),
        const SizedBox(height: 24),
        const Text(
          '본인인증 완료!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          '${_method.label}로 인증되었어요. 프로필에 인증 배지가 표시됩니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 28),
        _DataCard(
          children: [
            _DataRow(label: '이름', value: _maskName(_nameCtrl.text)),
            _DataRow(label: '생년월일', value: _maskBirth(_birthCtrl.text)),
            _DataRow(label: '인증 방식', value: _method.label),
            const _DataRow(label: '인증 일시', value: '방금 전'),
            if (_isMinor)
              _DataRow(label: '보호자', value: _guardianPhone ?? '미입력'),
          ],
        ),
      ],
    );
  }

  String _maskName(String name) {
    if (name.length < 2) return name;
    if (name.length == 2) return '${name[0]} ○';
    final chars = name.split('');
    for (int i = 1; i < chars.length - 1; i++) {
      chars[i] = '○';
    }
    return chars.join(' ');
  }

  String _maskBirth(String birth) {
    if (birth.length < 4) return birth;
    return birth
        .replaceAll(RegExp(r'\d'), '*')
        .replaceFirst('*', birth[0])
        .replaceFirst('*', birth[1])
        .replaceFirst('*', birth[2])
        .replaceFirst('*', birth[3]);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted)),
      );
}

class _BulletRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BulletRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandDark, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child:
                Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final List<Widget> children;
  const _DataCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
