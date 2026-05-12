import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/permission_state.dart';
import '../../theme/app_theme.dart';

class NotificationPrimingScreen extends StatefulWidget {
  final String? next;
  const NotificationPrimingScreen({super.key, this.next});

  @override
  State<NotificationPrimingScreen> createState() =>
      _NotificationPrimingScreenState();
}

class _NotificationPrimingScreenState extends State<NotificationPrimingScreen> {
  final Set<String> _categories = {'hire', 'checkin', 'chat'};
  bool _processed = false;

  void _close({bool granted = false}) {
    PermissionStore.I.markPrimed(PermissionKind.notification);
    PermissionStore.I.set(
      PermissionKind.notification,
      granted ? PermissionStatus.granted : PermissionStatus.denied,
    );
    if (widget.next != null) {
      context.go(widget.next!);
    } else {
      Navigator.of(context).pop(granted);
    }
  }

  void _showSystemDialog() async {
    setState(() => _processed = true);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('"Sharework"이(가) 알림을 보내도록 허용하시겠습니까?'),
        content: const Text(
          '잠금화면, 배너, 사운드를 포함합니다. 설정에서 변경할 수 있습니다.\n\n'
          '시스템 다이얼로그 시뮬레이션 (목업)',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('허용 안 함'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('허용'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      _close(granted: true);
    } else {
      _showFallbackSheet();
    }
  }

  void _showFallbackSheet() {
    bool emailOn = true;
    bool smsOn = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (innerCtx, innerSet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE5E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_off,
                        color: AppColors.danger),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('대신 다른 채널로 받으시겠어요?',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '푸시 알림이 꺼져 있어도 중요한 안내(채용 확정·정산·체크인)는 이메일이나 문자로 받을 수 있어요.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: emailOn,
                activeColor: AppColors.brandDark,
                title: const Text('이메일로 받기'),
                subtitle: const Text('a***@gmail.com',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                onChanged: (v) => innerSet(() => emailOn = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: smsOn,
                activeColor: AppColors.brandDark,
                title: const Text('문자(SMS)로 받기'),
                subtitle: const Text('010-****-1234 (건당 30원)',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                onChanged: (v) => innerSet(() => smsOn = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _close(granted: false);
                      },
                      child: const Text('아무것도 받지 않기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        PermissionStore.I.emailFallback = emailOn;
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(emailOn
                                  ? '이메일로 받도록 설정했어요'
                                  : '대체 채널 없이 진행합니다')),
                        );
                        _close(granted: false);
                      },
                      child: const Text('저장'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleCat(String key) {
    setState(() {
      if (_categories.contains(key)) {
        _categories.remove(key);
      } else {
        _categories.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: ListView(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _close(granted: false),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.notifications_active,
                        size: 100, color: AppColors.brandDark),
                    Positioned(
                      top: 30,
                      right: 90,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.danger,
                        child: Text('3',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '채용 소식과 체크인 시간을\n놓치지 않으려면',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                '받고 싶은 알림 종류를 먼저 골라주세요. 마이페이지에서 언제든 변경할 수 있어요.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted, height: 1.6),
              ),
              const SizedBox(height: 20),
              _Cat(
                  icon: Icons.celebration_outlined,
                  title: '채용 확정',
                  desc: '구인자가 나를 선택했을 때 즉시',
                  on: _categories.contains('hire'),
                  onTap: () => _toggleCat('hire')),
              _Cat(
                  icon: Icons.access_time,
                  title: '체크인·근무 시간',
                  desc: '출근 30분 전 알림 + 휴식·퇴근',
                  on: _categories.contains('checkin'),
                  onTap: () => _toggleCat('checkin')),
              _Cat(
                  icon: Icons.chat_bubble_outline,
                  title: '채팅 메시지',
                  desc: '구인자·구직자 메시지',
                  on: _categories.contains('chat'),
                  onTap: () => _toggleCat('chat')),
              _Cat(
                  icon: Icons.account_balance_wallet_outlined,
                  title: '정산·세금',
                  desc: '정산 완료·원천세 신고 안내',
                  on: _categories.contains('payment'),
                  onTap: () => _toggleCat('payment')),
              _Cat(
                  icon: Icons.local_offer_outlined,
                  title: '이벤트·쿠폰',
                  desc: '신규 가입·추천인 혜택',
                  on: _categories.contains('marketing'),
                  onTap: () => _toggleCat('marketing')),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bedtime_outlined,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '야간(22:00~08:00) 방해금지가 자동 설정돼요. 긴급 알림은 예외로 들어옵니다.',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _processed ? null : _showSystemDialog,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(
                    _categories.isEmpty
                        ? '선택 없이 알림 켜기'
                        : '${_categories.length}개 카테고리로 알림 켜기',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _showFallbackSheet,
                  child: const Text('이메일·문자로만 받기',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool on;
  final VoidCallback onTap;
  const _Cat({
    required this.icon,
    required this.title,
    required this.desc,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
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
              Icon(icon, color: on ? AppColors.brandDark : AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    Text(desc,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Icon(
                on ? Icons.check_circle : Icons.radio_button_unchecked,
                color: on ? AppColors.brandDark : AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
