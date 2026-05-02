import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

enum _PermStatus { allowed, partial, denied }

enum _SoundTone { ding, chime, beep, silent }

extension _SoundToneX on _SoundTone {
  String get label => switch (this) {
        _SoundTone.ding => '딩동 (기본)',
        _SoundTone.chime => '차임벨',
        _SoundTone.beep => '간단 비프',
        _SoundTone.silent => '무음 (진동만)',
      };
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationPrefs _prefs;
  _PermStatus _perm = _PermStatus.partial;

  // Per-channel toggles (목업)
  final Map<String, _ChannelPrefs> _channels = {
    'application': const _ChannelPrefs(app: true, email: false, sms: false),
    'hire': const _ChannelPrefs(app: true, email: true, sms: true),
    'chat': const _ChannelPrefs(app: true, email: false, sms: false),
    'review': const _ChannelPrefs(app: true, email: true, sms: false),
    'system': const _ChannelPrefs(app: true, email: true, sms: false),
    'marketing': const _ChannelPrefs(app: false, email: false, sms: false),
  };

  // 방해금지 시간 (목업)
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);
  Set<int> _quietWeekdays = {1, 2, 3, 4, 5, 6, 7};
  bool _urgentExempt = true;

  _SoundTone _tone = _SoundTone.ding;
  int _vibration = 2; // 0~3

  String _expanded = '';

  @override
  void initState() {
    super.initState();
    _prefs = Dummy.notificationPrefs;
  }

  void _toggleExpanded(String key) {
    setState(() => _expanded = _expanded == key ? '' : key);
  }

  void _showPermSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _permColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_permIcon, color: _permColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('시스템 알림 권한 — $_permLabel',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Text(_permHint,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('재설정 안내',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final t in const [
                ['1.', '시스템 설정 → 앱 → Sharework'],
                ['2.', '알림 → 알림 표시 ON'],
                ['3.', '잠금 화면 / 배너 / 사운드 모두 허용'],
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t[0],
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t[1],
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: const Text('닫기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('시스템 설정으로 이동 (목업)')),
                        );
                        Future.delayed(const Duration(milliseconds: 800),
                            () {
                          if (mounted) {
                            setState(() => _perm = _PermStatus.allowed);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      '권한이 변경되어 알림이 정상 동작합니다 (목업)')),
                            );
                          }
                        });
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('설정 열기'),
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

  String get _permLabel => switch (_perm) {
        _PermStatus.allowed => '허용됨',
        _PermStatus.partial => '일부 허용',
        _PermStatus.denied => '차단됨',
      };

  String get _permHint => switch (_perm) {
        _PermStatus.allowed => '모든 알림이 정상 도착합니다',
        _PermStatus.partial => '잠금 화면 또는 배너가 비활성화되어 있어요',
        _PermStatus.denied => '시스템 설정에서 허용해주세요',
      };

  Color get _permColor => switch (_perm) {
        _PermStatus.allowed => AppColors.success,
        _PermStatus.partial => AppColors.warning,
        _PermStatus.denied => AppColors.danger,
      };

  IconData get _permIcon => switch (_perm) {
        _PermStatus.allowed => Icons.check_circle,
        _PermStatus.partial => Icons.warning_amber,
        _PermStatus.denied => Icons.notifications_off,
      };

  void _showQuietSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              const Text('방해금지 시간',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('지정한 시간에는 알림 사운드·진동이 꺼집니다',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: '시작',
                      value: _quietStart,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _quietStart,
                        );
                        if (t != null) {
                          innerSet(() => _quietStart = t);
                          setState(() => _quietStart = t);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeButton(
                      label: '종료',
                      value: _quietEnd,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _quietEnd,
                        );
                        if (t != null) {
                          innerSet(() => _quietEnd = t);
                          setState(() => _quietEnd = t);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('적용 요일',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final wd = i + 1;
                  final on = _quietWeekdays.contains(wd);
                  return ChoiceChip(
                    label: Text(['월', '화', '수', '목', '금', '토', '일'][i]),
                    selected: on,
                    onSelected: (_) {
                      innerSet(() {
                        if (on) {
                          _quietWeekdays.remove(wd);
                        } else {
                          _quietWeekdays.add(wd);
                        }
                      });
                      setState(() {});
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _urgentExempt,
                activeColor: AppColors.brandDark,
                title: const Text('긴급 알림은 예외',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: const Text('체크인·정산 지연 등 시간 민감한 알림',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                onChanged: (v) {
                  innerSet(() => _urgentExempt = v);
                  setState(() => _urgentExempt = v);
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(sheetCtx),
                child: const Text('완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPreviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('샘플 알림 미리보기',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const _PreviewCard(
                icon: Icons.send,
                title: '지원 검토 시작',
                body: '강남 카페 모카 매장에서 지원자님의 프로필을 확인 중이에요.',
                relative: '방금',
              ),
              const _PreviewCard(
                icon: Icons.celebration,
                title: '채용 확정!',
                body: '내일 오전 9시 출근 — 카페 모카 강남점',
                relative: '5분 전',
              ),
              const _PreviewCard(
                icon: Icons.chat_bubble,
                title: '새 메시지',
                body: '"내일 위치 안내 드릴게요"',
                relative: '12분 전',
              ),
              const _PreviewCard(
                icon: Icons.local_offer,
                title: '신규 가입 쿠폰 도착',
                body: '첫 정산 시 5,000원 즉시 할인',
                relative: '2시간 전',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSoundSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (innerCtx, innerSet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('사운드 · 진동',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Text('알림 사운드',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700)),
                for (final s in _SoundTone.values)
                  RadioListTile<_SoundTone>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(s.label),
                    secondary: IconButton(
                      icon: const Icon(Icons.play_arrow,
                          color: AppColors.brandDark),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('${s.label} 미리듣기 (목업)')),
                        );
                      },
                    ),
                    value: s,
                    groupValue: _tone,
                    activeColor: AppColors.brandDark,
                    onChanged: (v) {
                      innerSet(() => _tone = v ?? _tone);
                      setState(() => _tone = v ?? _tone);
                    },
                  ),
                const SizedBox(height: 12),
                const Text('진동 강도',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700)),
                Slider(
                  value: _vibration.toDouble(),
                  min: 0, max: 3, divisions: 3,
                  label: ['끄기', '약함', '보통', '강함'][_vibration],
                  activeColor: AppColors.brandDark,
                  onChanged: (v) {
                    innerSet(() => _vibration = v.round());
                    setState(() => _vibration = v.round());
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('끄기', style: TextStyle(fontSize: 11)),
                    Text('약함', style: TextStyle(fontSize: 11)),
                    Text('보통', style: TextStyle(fontSize: 11)),
                    Text('강함', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Text('완료'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryItem({
    required String key,
    required IconData icon,
    required String label,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final ch = _channels[key]!;
    final expanded = _expanded == key;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(icon,
              color: value ? AppColors.brandDark : AppColors.textFaint),
          title: Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          subtitle: Text(desc,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    expanded ? Icons.expand_less : Icons.tune,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => _toggleExpanded(key),
                ),
              Switch(
                value: value,
                activeColor: AppColors.brandDark,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (expanded && value)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _ChannelRow(
                  label: '앱 푸시',
                  value: ch.app,
                  onChanged: (v) => setState(() {
                    _channels[key] = ch.copyWith(app: v);
                  }),
                ),
                _ChannelRow(
                  label: '이메일',
                  value: ch.email,
                  onChanged: (v) => setState(() {
                    _channels[key] = ch.copyWith(email: v);
                  }),
                ),
                _ChannelRow(
                  label: '문자(SMS)',
                  value: ch.sms,
                  onChanged: (v) => setState(() {
                    _channels[key] = ch.copyWith(sms: v);
                  }),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: '미리보기',
            onPressed: _showPreviewSheet,
          ),
        ],
      ),
      body: ListView(
        children: [
          // 시스템 권한 카드
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _permColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _permColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(_permIcon, color: _permColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('시스템 권한 — $_permLabel',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      Text(_permHint,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showPermSheet,
                  child: const Text('관리'),
                ),
              ],
            ),
          ),
          const _SectionHeader('카테고리별 알림'),
          _categoryItem(
            key: 'application',
            icon: Icons.send_outlined,
            label: '지원·매칭',
            desc: '내 지원이 등록·검토될 때',
            value: _prefs.application,
            onChanged: (v) => setState(
                () => _prefs = _prefs.copyWith(application: v)),
          ),
          _categoryItem(
            key: 'hire',
            icon: Icons.celebration_outlined,
            label: '채용 확정',
            desc: '구인자가 채용을 확정했을 때',
            value: _prefs.hire,
            onChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(hire: v)),
          ),
          _categoryItem(
            key: 'chat',
            icon: Icons.chat_bubble_outline,
            label: '채팅 메시지',
            desc: '새 메시지·답장 도착',
            value: _prefs.chat,
            onChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(chat: v)),
          ),
          _categoryItem(
            key: 'review',
            icon: Icons.rate_review_outlined,
            label: '리뷰',
            desc: '새 리뷰 작성·도착',
            value: _prefs.review,
            onChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(review: v)),
          ),
          _categoryItem(
            key: 'system',
            icon: Icons.campaign_outlined,
            label: '서비스 안내',
            desc: '점검·약관·중요 공지',
            value: _prefs.system,
            onChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(system: v)),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const _SectionHeader('마케팅'),
          _categoryItem(
            key: 'marketing',
            icon: Icons.local_offer_outlined,
            label: '이벤트·쿠폰',
            desc: '추천인·할인·신규 이벤트',
            value: _prefs.marketing,
            onChanged: (v) =>
                setState(() => _prefs = _prefs.copyWith(marketing: v)),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const _SectionHeader('방해금지·소리'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.bedtime_outlined),
            title: const Text('방해금지 시간',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${_fmtTime(_quietStart)} ~ ${_fmtTime(_quietEnd)} · '
              '${_quietWeekdays.length}/7일${_urgentExempt ? ' · 긴급 예외' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: Switch(
              value: _prefs.nightQuiet,
              activeColor: AppColors.brandDark,
              onChanged: (v) =>
                  setState(() => _prefs = _prefs.copyWith(nightQuiet: v)),
            ),
            onTap: _prefs.nightQuiet ? _showQuietSheet : null,
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.music_note_outlined),
            title: const Text('사운드 · 진동',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${_tone.label} · 진동 ${['끄기', '약함', '보통', '강함'][_vibration]}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textMuted),
            onTap: _showSoundSheet,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showPermSheet,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('시스템 권한'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/me/permissions'),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('권한 관리'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ChannelPrefs {
  final bool app;
  final bool email;
  final bool sms;
  const _ChannelPrefs({
    required this.app,
    required this.email,
    required this.sms,
  });

  _ChannelPrefs copyWith({bool? app, bool? email, bool? sms}) =>
      _ChannelPrefs(
        app: app ?? this.app,
        email: email ?? this.email,
        sms: sms ?? this.sms,
      );
}

class _ChannelRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ChannelRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Switch(
          value: value,
          activeColor: AppColors.brandDark,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: onChanged,
        ),
      ],
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

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String relative;
  const _PreviewCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.relative,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brandDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ),
                    Text(relative,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textFaint)),
                  ],
                ),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
