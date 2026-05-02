import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  static const _reasons = [
    '서비스를 자주 이용하지 않아요',
    '원하는 일감이 없어요',
    '다른 앱을 이용하고 있어요',
    '개인정보가 걱정돼요',
    '오류·불편이 많아요',
    '기타',
  ];

  String? _reason;
  final _confirmCtrl = TextEditingController();
  bool _agreed = false;

  static const _confirmText = '탈퇴에 동의합니다';

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _reason != null &&
      _agreed &&
      _confirmCtrl.text.trim() == _confirmText;

  void _submit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('정말 탈퇴하시겠어요?'),
        content: const Text(
            '탈퇴 후에는 같은 휴대폰 번호로 30일간 재가입이 제한돼요. 미수령 정산금이 있으면 자동 환불되며, 미정산 분쟁은 진행이 종료됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('돌아가기'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('탈퇴 처리되었습니다 (목업)')),
              );
              context.go('/auth/phone');
            },
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원 탈퇴')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text(
            '잠깐, 탈퇴 전에 확인해주세요',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bullet(
                  icon: Icons.account_balance_wallet_outlined,
                  text: '에스크로·미수령 정산금은 등록된 계좌로 환불돼요',
                ),
                _Bullet(
                  icon: Icons.gavel_outlined,
                  text: '진행 중인 분쟁 조정·계약은 자동으로 종료 처리돼요',
                ),
                _Bullet(
                  icon: Icons.workspace_premium_outlined,
                  text: '보유 포인트·쿠폰·등급은 모두 소멸되며 복구되지 않아요',
                ),
                _Bullet(
                  icon: Icons.history,
                  text: '근무·리뷰 기록은 익명 처리되며 30일간 보관돼요',
                ),
                _Bullet(
                  icon: Icons.phone_android,
                  text: '같은 휴대폰 번호로 30일간 재가입할 수 없어요',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('탈퇴 사유',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ..._reasons.map((r) => RadioListTile<String>(
                value: r,
                groupValue: _reason,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppColors.brandDark,
                title: Text(r, style: const TextStyle(fontSize: 13)),
                onChanged: (v) => setState(() => _reason = v),
              )),
          const SizedBox(height: 16),
          const Text('확인 입력',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            '아래 칸에 「$_confirmText」 라고 입력해 주세요.',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmCtrl,
            decoration: InputDecoration(hintText: _confirmText),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _agreed,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.brandDark,
            title: const Text('위 안내사항을 모두 확인했고 탈퇴에 동의합니다',
                style: TextStyle(fontSize: 13)),
            onChanged: (v) => setState(() => _agreed = v ?? false),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('계속 사용하기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger),
                  onPressed: _canSubmit ? _submit : null,
                  child: const Text('탈퇴하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.brandDark),
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
