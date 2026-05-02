import 'package:flutter/material.dart';

import '../../data/permission_state.dart';
import '../../theme/app_theme.dart';
import 'priming_sheets.dart';

class PermissionCenterScreen extends StatefulWidget {
  const PermissionCenterScreen({super.key});

  @override
  State<PermissionCenterScreen> createState() =>
      _PermissionCenterScreenState();
}

class _PermissionCenterScreenState extends State<PermissionCenterScreen> {
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

  Color _statusColor(PermissionStatus s) {
    switch (s) {
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

  IconData _kindIcon(PermissionKind k) {
    switch (k) {
      case PermissionKind.location:
        return Icons.location_on_outlined;
      case PermissionKind.notification:
        return Icons.notifications_outlined;
      case PermissionKind.camera:
        return Icons.camera_alt_outlined;
      case PermissionKind.gallery:
        return Icons.photo_library_outlined;
    }
  }

  Future<void> _toggle(PermissionKind k) async {
    final cur = PermissionStore.I.get(k);
    if (cur.isGranted) {
      // 끄기
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('${k.label} 권한 끄기'),
          content: const Text(
              '권한을 끄려면 시스템 설정으로 이동해야 해요. 지금 이동할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('설정 열기'),
            ),
          ],
        ),
      );
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시스템 설정으로 이동 (목업)')),
        );
        PermissionStore.I.set(k, PermissionStatus.denied);
      }
    } else {
      await ensurePermission(context, k);
    }
  }

  Widget _buildRow(PermissionKind k) {
    final s = PermissionStore.I.get(k);
    final color = _statusColor(s);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_kindIcon(k), color: AppColors.brandDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(k.oneLineWhy,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (k == PermissionKind.location &&
                  PermissionStore.I.manualAddress != null) ...[
                const Icon(Icons.place,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '대체 주소: ${PermissionStore.I.manualAddress}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ] else if (k == PermissionKind.notification &&
                  PermissionStore.I.emailFallback) ...[
                const Icon(Icons.email_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text('이메일로 대체 수신',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ),
              ] else
                const Spacer(),
              TextButton(
                onPressed: () => _toggle(k),
                child: Text(s.isGranted ? '끄기' : '허용'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grantedCount = PermissionKind.values
        .where((k) => PermissionStore.I.get(k).isGranted)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 권한 관리'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield,
                    color: AppColors.brandDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$grantedCount / 4 권한 허용됨',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDark)),
                      const Text('필요한 순간에만 사용해 개인정보를 보호해요',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final k in PermissionKind.values) _buildRow(k),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('시스템 설정으로 이동 (목업)')),
              );
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('시스템 권한 설정 열기'),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: AppColors.textMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '거부 후 다시 허용하려면 시스템 설정에서 직접 변경해야 합니다.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
