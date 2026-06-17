import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/me_repository.dart';
import '../../data/role_routing.dart';

class PhoneAuthScreen extends StatefulWidget {
  final AuthRepository? authRepository;
  final VoidCallback? onAuthenticated;

  const PhoneAuthScreen({
    super.key,
    this.authRepository,
    this.onAuthenticated,
  });

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  AuthRepository get _auth => widget.authRepository ?? AuthRepository();

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.sendOtp(phone);
      if (mounted) setState(() => _otpSent = true);
    } catch (_) {
      if (mounted) setState(() => _error = '인증번호 전송에 실패했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final token = _otpCtrl.text.trim();
    if (phone.isEmpty || token.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await _auth.verifyOtp(phone: phone, token: token);
      if (ok) {
        if (widget.onAuthenticated != null) {
          widget.onAuthenticated!();
        } else {
          final route = await homeRouteForCurrentUser(MeRepository.fromApi());
          if (mounted) context.go(route);
        }
      } else if (mounted) {
        setState(() => _error = '인증 실패: 코드를 다시 확인해주세요.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = '인증 실패: 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('전화번호 인증')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('phone-field'),
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+821012345678',
                labelText: '전화번호',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('send-otp-button'),
              onPressed: _loading ? null : _sendOtp,
              child: Text(_otpSent ? '재전송' : '인증번호 전송'),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextField(
                key: const Key('otp-field'),
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: '6자리 인증번호',
                  labelText: '인증번호',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('verify-otp-button'),
                onPressed: _loading ? null : _verifyOtp,
                child: const Text('인증 확인'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
