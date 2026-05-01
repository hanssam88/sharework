import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationPrefs _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = Dummy.notificationPrefs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: ListView(
        children: [
          const _SectionHeader('카테고리별 알림'),
          _Item(
            icon: Icons.send_outlined,
            label: '지원 알림',
            desc: '내 지원이 등록·검토될 때',
            value: _prefs.application,
            onChanged: (v) => setState(
                () => _prefs = _prefs.copyWith(application: v)),
          ),
          _Item(
            icon: Icons.celebration_outlined,
            label: '채용 확정 알림',
            desc: '구인자가 채용을 확정했을 때',
            value: _prefs.hire,
            onChanged: (v) => setState(() => _prefs = _prefs.copyWith(hire: v)),
          ),
          _Item(
            icon: Icons.chat_bubble_outline,
            label: '채팅 메시지',
            desc: '새 메시지 도착',
            value: _prefs.chat,
            onChanged: (v) => setState(() => _prefs = _prefs.copyWith(chat: v)),
          ),
          _Item(
            icon: Icons.rate_review_outlined,
            label: '리뷰 알림',
            desc: '새 리뷰 도착',
            value: _prefs.review,
            onChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(review: v)),
          ),
          _Item(
            icon: Icons.campaign_outlined,
            label: '서비스 안내',
            desc: '점검·약관·중요 공지',
            value: _prefs.system,
            onChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(system: v)),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const _SectionHeader('마케팅'),
          _Item(
            icon: Icons.local_offer_outlined,
            label: '이벤트·쿠폰 알림',
            desc: '추천인·할인·이벤트',
            value: _prefs.marketing,
            onChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(marketing: v)),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const _SectionHeader('방해금지'),
          _Item(
            icon: Icons.bedtime_outlined,
            label: '야간 방해금지',
            desc: '22:00 ~ 08:00 사이 알림 음소거',
            value: _prefs.nightQuiet,
            onChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(nightQuiet: v)),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('시스템 알림 설정으로 이동합니다 (목업)')),
                );
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('시스템 알림 권한 관리'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Item({
    required this.icon,
    required this.label,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: Icon(icon, color: AppColors.text),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: Text(desc,
          style:
              const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.brandDark,
    );
  }
}
