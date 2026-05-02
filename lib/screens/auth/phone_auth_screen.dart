import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _codeSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('휴대폰 인증')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '휴대폰 번호를 입력해주세요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '본인 확인을 위해 인증번호를 보내드립니다.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),
              const _Label('휴대폰 번호'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: '010-0000-0000',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _codeSent = true),
                      child: Text(_codeSent ? '재전송' : '인증요청'),
                    ),
                  ),
                ],
              ),
              if (_codeSent) ...[
                const SizedBox(height: 24),
                const _Label('인증번호'),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: '6자리 숫자',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '인증번호를 받지 못하셨나요?  ·  남은 시간 03:00',
                  style: TextStyle(fontSize: 12, color: AppColors.textFaint),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _codeSent ? () => context.go('/auth/signup') : null,
                child: const Text('확인'),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _showRoleSheet(context),
                  child: const Text('테스트: 가입 건너뛰기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('어떤 사용자로 진입할까요?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.person_search, color: AppColors.brandDark),
              title: const Text('Worker (구직자)'),
              subtitle: const Text('지도에서 일자리 찾기'),
              onTap: () => context.go('/worker'),
            ),
            ListTile(
              leading: const Icon(Icons.add_business, color: AppColors.brandDark),
              title: const Text('Giver (구인자)'),
              subtitle: const Text('일감 등록·관리'),
              onTap: () => context.go('/giver'),
            ),
            const SizedBox(height: 8),
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
