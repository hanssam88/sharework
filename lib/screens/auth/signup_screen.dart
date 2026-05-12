import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _agreeAll = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;
  String _appType = 'worker';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '회원 정보를 입력해주세요',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            const _Label('이름'),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(hintText: '이름을 입력해주세요'),
            ),
            const SizedBox(height: 16),
            const _Label('주민등록번호'),
            const SizedBox(height: 8),
            Row(
              children: const [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: '앞 6자리'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('-'),
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: '뒤 7자리'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _Label('이메일'),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(hintText: '이메일을 입력해주세요'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const _Label('가입 유형'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RolePill(
                    label: '구직자 (Worker)',
                    selected: _appType == 'worker',
                    onTap: () => setState(() => _appType = 'worker'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RolePill(
                    label: '구인자 (Giver)',
                    selected: _appType == 'giver',
                    onTap: () => setState(() => _appType = 'giver'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _AgreeRow(
              text: '전체 동의',
              checked: _agreeAll,
              bold: true,
              onChanged: (v) => setState(() {
                _agreeAll = v;
                _agreeTerms = v;
                _agreePrivacy = v;
                _agreeMarketing = v;
              }),
            ),
            const Divider(height: 16),
            _AgreeRow(
              text: '[필수] 이용약관 동의',
              checked: _agreeTerms,
              onChanged: (v) => setState(() => _agreeTerms = v),
            ),
            _AgreeRow(
              text: '[필수] 개인정보 수집·이용 동의',
              checked: _agreePrivacy,
              onChanged: (v) => setState(() => _agreePrivacy = v),
            ),
            _AgreeRow(
              text: '[선택] 마케팅 정보 수신 동의',
              checked: _agreeMarketing,
              onChanged: (v) => setState(() => _agreeMarketing = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (_agreeTerms && _agreePrivacy)
                  ? () => context.push('/auth/identity')
                  : null,
              child: const Text('다음: 본인인증'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: (_agreeTerms && _agreePrivacy)
                  ? () =>
                      context.go(_appType == 'worker' ? '/worker' : '/giver')
                  : null,
              child: const Text('나중에 인증하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
}

class _RolePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RolePill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: selected ? AppColors.brandSoft : AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.brandDark : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.brandDark : AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AgreeRow extends StatelessWidget {
  final String text;
  final bool checked;
  final bool bold;
  final ValueChanged<bool> onChanged;
  const _AgreeRow({
    required this.text,
    required this.checked,
    required this.onChanged,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: checked ? AppColors.brandDark : AppColors.textFaint,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
