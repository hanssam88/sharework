import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/permission_state.dart';
import '../../theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  @override
  void initState() {
    super.initState();
    PermissionStore.I.addListener(_onChange);
  }

  @override
  void dispose() {
    PermissionStore.I.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _next() => context.go('/auth/phone');

  Future<void> _openLocationPriming() async {
    await context.push('/onboarding/permissions/location');
  }

  Future<void> _openNotificationPriming() async {
    await context.push('/onboarding/permissions/notification');
  }

  void _grantQuick(PermissionKind k) {
    PermissionStore.I.markPrimed(k);
    PermissionStore.I.set(k, PermissionStatus.granted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${k.label} 권한이 허용되었어요 (목업)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = PermissionStore.I;
    final progress =
        PermissionKind.values.where((k) => store.get(k).isGranted).length;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _next,
                    child: const Text('건너뛰기',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '시작 전, 권한을\n확인해주세요',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                '필요한 권한만 골라서 허용할 수 있어요. 자세한 안내는 카드를 눌러주세요.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted, height: 1.6),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / PermissionKind.values.length,
                  minHeight: 6,
                  backgroundColor: AppColors.chipBg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.brandDark),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$progress / ${PermissionKind.values.length} 완료',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _PermItem(
                      icon: Icons.location_on_outlined,
                      title: '위치 (권장)',
                      desc: '내 주변 일감을 보여주고 거리 계산에 사용',
                      status: store.location,
                      detail: true,
                      onDetail: _openLocationPriming,
                      onQuickGrant: () => _grantQuick(PermissionKind.location),
                    ),
                    const SizedBox(height: 10),
                    _PermItem(
                      icon: Icons.notifications_outlined,
                      title: '알림',
                      desc: '채용 확정·체크인·정산 등 중요한 안내',
                      status: store.notification,
                      detail: true,
                      onDetail: _openNotificationPriming,
                      onQuickGrant: () =>
                          _grantQuick(PermissionKind.notification),
                    ),
                    const SizedBox(height: 10),
                    _PermItem(
                      icon: Icons.camera_alt_outlined,
                      title: '카메라',
                      desc: '본인인증·자격증·체크인 사진 촬영 시 요청',
                      status: store.camera,
                      detail: false,
                      desc2: '필요한 순간에 다시 물어볼게요',
                    ),
                    const SizedBox(height: 10),
                    _PermItem(
                      icon: Icons.photo_library_outlined,
                      title: '사진·갤러리',
                      desc: '포트폴리오·프로필 사진 등록 시 요청',
                      status: store.gallery,
                      detail: false,
                      desc2: '필요한 순간에 다시 물어볼게요',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('계속하기',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  '언제든 마이페이지 → 권한 관리에서 변경할 수 있어요',
                  style: TextStyle(fontSize: 11, color: AppColors.textFaint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String? desc2;
  final PermissionStatus status;
  final bool detail;
  final VoidCallback? onDetail;
  final VoidCallback? onQuickGrant;
  const _PermItem({
    required this.icon,
    required this.title,
    required this.desc,
    this.desc2,
    required this.status,
    required this.detail,
    this.onDetail,
    this.onQuickGrant,
  });

  Color get _statusColor {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.partial:
        return AppColors.success;
      case PermissionStatus.notAsked:
        return AppColors.textFaint;
      case PermissionStatus.denied:
        return AppColors.warning;
      case PermissionStatus.denied2:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final granted = status.isGranted;
    return InkWell(
      onTap: detail ? onDetail : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: granted ? AppColors.brandDark : AppColors.divider,
            width: granted ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.brandDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(status.label,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _statusColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(desc,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              height: 1.5)),
                      if (desc2 != null) ...[
                        const SizedBox(height: 2),
                        Text(desc2!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textFaint,
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
                if (detail)
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
            if (detail && !granted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onQuickGrant,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                      ),
                      child:
                          const Text('빠르게 허용', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: onDetail,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.info_outline, size: 14),
                      label:
                          const Text('자세히 보기', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
