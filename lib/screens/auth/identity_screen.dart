import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

enum _Step { intro, capture, ocr, complete }

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  _Step _step = _Step.intro;

  void _next() {
    setState(() {
      switch (_step) {
        case _Step.intro:
          _step = _Step.capture;
          break;
        case _Step.capture:
          _step = _Step.ocr;
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) setState(() => _step = _Step.complete);
          });
          break;
        case _Step.ocr:
          break;
        case _Step.complete:
          context.go('/worker');
          break;
      }
    });
  }

  void _skip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('나중에 마이페이지에서 인증할 수 있어요')),
    );
    context.go('/worker');
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
        return '신분증 촬영하기';
      case _Step.capture:
        return '촬영 완료';
      case _Step.ocr:
        return 'OCR 분석 중...';
      case _Step.complete:
        return '시작하기';
    }
  }

  Widget _content() {
    switch (_step) {
      case _Step.intro:
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
              '신분증으로 본인인증을 완료하면 인증 배지가 표시되어\n구인자에게 더 신뢰받을 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            const _BulletRow(
                icon: Icons.shield_outlined, text: '신분증 사본은 암호화되어 저장됩니다'),
            const _BulletRow(
                icon: Icons.text_snippet_outlined,
                text: 'OCR로 자동 추출한 정보만 사용해요'),
            const _BulletRow(
                icon: Icons.delete_outline,
                text: '인증 완료 후 사본 이미지는 즉시 삭제됩니다'),
          ],
        );
      case _Step.capture:
        return Column(
          key: const ValueKey('capture'),
          children: [
            Container(
              color: Colors.black,
              height: 380,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 가이드 프레임
                  Container(
                    width: 280,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.brand, width: 2.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '신분증을\n프레임에 맞춰주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                        border: Border.all(
                            color: AppColors.brand, width: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '신분증 촬영',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '주민등록증 / 운전면허증 / 여권 중 하나를 선택해주세요.\n빛 반사가 없도록 평평한 곳에 두고 촬영해요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        );
      case _Step.ocr:
        return Center(
          key: const ValueKey('ocr'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: AppColors.brandDark),
              SizedBox(height: 20),
              Text('신분증 정보 분석 중...',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('보통 5초 이내 완료됩니다',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        );
      case _Step.complete:
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
            const Text(
              '프로필에 인증 배지가 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 28),
            _DataCard(
              children: [
                _DataRow(label: '이름', value: '김 ○ 바'),
                _DataRow(label: '생년월일', value: '199*-**-**'),
                _DataRow(label: '인증 일시', value: '방금 전'),
              ],
            ),
          ],
        );
    }
  }
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
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.5)),
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
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
