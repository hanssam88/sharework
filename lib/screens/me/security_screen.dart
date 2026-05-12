import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  late SecurityPrefs _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = Dummy.securityPrefs;
  }

  void _setupPin() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('PIN 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('앱 잠금에 사용할 4자리 PIN을 입력해주세요.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 12),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '••••',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
              if (ctrl.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('4자리를 입력해주세요')),
                );
                return;
              }
              Navigator.pop(context);
              setState(() => _prefs = _prefs.copyWith(pinEnabled: true));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN이 설정되었어요 (목업)')),
              );
            },
            child: const Text('설정'),
          ),
        ],
      ),
    );
  }

  void _pickAutoLock() {
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
                child: Text('자동 잠금 시간',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ...[
              const Duration(seconds: 0),
              const Duration(minutes: 1),
              const Duration(minutes: 5),
              const Duration(minutes: 15),
              const Duration(hours: 1),
            ].map((d) {
              final label = d.inSeconds == 0
                  ? '즉시'
                  : d.inHours >= 1
                      ? '${d.inHours}시간 후'
                      : '${d.inMinutes}분 후';
              final on = _prefs.autoLock == d;
              return RadioListTile<int>(
                value: d.inSeconds,
                groupValue: _prefs.autoLock.inSeconds,
                activeColor: AppColors.brandDark,
                title: Text(label),
                onChanged: (_) {
                  setState(() => _prefs = _prefs.copyWith(autoLock: d));
                  Navigator.pop(sheetCtx);
                },
                selected: on,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _autoLockLabel() {
    final d = _prefs.autoLock;
    if (d.inSeconds == 0) return '즉시';
    if (d.inHours >= 1) return '${d.inHours}시간 후';
    return '${d.inMinutes}분 후';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('계정 보안')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SectionHeader(title: '앱 잠금'),
          SwitchListTile(
            value: _prefs.pinEnabled,
            activeColor: AppColors.brandDark,
            secondary: const Icon(Icons.lock_outline),
            title: const Text('PIN 잠금'),
            subtitle: const Text('앱 실행 시 4자리 PIN 입력',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onChanged: (v) {
              if (v) {
                _setupPin();
              } else {
                setState(() => _prefs = _prefs.copyWith(pinEnabled: false));
              }
            },
          ),
          SwitchListTile(
            value: _prefs.biometricEnabled,
            activeColor: AppColors.brandDark,
            secondary: const Icon(Icons.fingerprint),
            title: const Text('생체 인증'),
            subtitle: const Text('Face ID / 지문으로 빠르게 잠금 해제',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onChanged: _prefs.pinEnabled
                ? (v) => setState(
                    () => _prefs = _prefs.copyWith(biometricEnabled: v))
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('자동 잠금'),
            subtitle: Text(_autoLockLabel(),
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textFaint),
            onTap: _prefs.pinEnabled ? _pickAutoLock : null,
            enabled: _prefs.pinEnabled,
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '결제·정산'),
          SwitchListTile(
            value: _prefs.requireAuthOnPay,
            activeColor: AppColors.brandDark,
            secondary: const Icon(Icons.shield_outlined),
            title: const Text('결제 시 추가 인증'),
            subtitle: const Text('에스크로 충전·환불 시 PIN 또는 생체 인증 요구',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(requireAuthOnPay: v)),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '로그인 보안'),
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('로그인 기기 관리'),
            subtitle: const Text('현재 2개 기기에서 로그인됨',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textFaint),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('기기 관리 (목업)')),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('최근 로그인 기록'),
            subtitle: const Text('30일간의 접속 이력',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textFaint),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('로그인 기록 (목업)')),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
