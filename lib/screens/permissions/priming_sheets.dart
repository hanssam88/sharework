import 'package:flutter/material.dart';

import '../../data/permission_state.dart';
import '../../theme/app_theme.dart';

/// just-in-time priming 시트 — 권한 요청 직전에 띄움.
/// 이미 허용된 상태면 시트 없이 곧장 true 반환.
Future<bool> ensurePermission(
  BuildContext context,
  PermissionKind kind, {
  String? customWhy,
}) async {
  final store = PermissionStore.I;
  final cur = store.get(kind);
  if (cur.isGranted) return true;
  if (cur == PermissionStatus.denied2) {
    return await _showOpenSettingsSheet(context, kind);
  }
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetCtx) => _PrimingSheet(kind: kind, customWhy: customWhy),
      ) ??
      false;
}

class _PrimingSheet extends StatelessWidget {
  final PermissionKind kind;
  final String? customWhy;
  const _PrimingSheet({required this.kind, this.customWhy});

  IconData get _icon {
    switch (kind) {
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

  List<List<String>> get _benefits {
    switch (kind) {
      case PermissionKind.camera:
        return const [
          ['QR·자격증 자동 인식', '카메라로 비추기만 하면 텍스트 자동 추출'],
          ['셀카 본인 확인', '실시간 캡처로 도용 방지'],
          ['체크인 인증샷', '근무 시작·휴식·종료 사진 첨부'],
        ];
      case PermissionKind.gallery:
        return const [
          ['포트폴리오 등록', '나의 작업물·결과물 사진 추가'],
          ['프로필 사진', '자신을 잘 보여줄 수 있는 사진'],
          ['증빙 자료', '자격증·이력 등 첨부'],
        ];
      case PermissionKind.location:
        return const [
          ['주변 일자리 자동 표시', '내 위치 반경 추천'],
          ['거리 계산', '"여기서 850m" 한눈에'],
          ['GPS 체크인', '근무지 도착 검증'],
        ];
      case PermissionKind.notification:
        return const [
          ['채용 확정 알림', '구인자가 나를 선택하면 즉시'],
          ['체크인 시간', '출근·휴식 알림'],
          ['정산 완료', '돈이 들어오면 바로 알림'],
        ];
    }
  }

  void _request(BuildContext context) async {
    PermissionStore.I.markPrimed(kind);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('"Sharework"이(가) ${kind.label}을(를) 사용하도록 허용하시겠습니까?'),
        content: const Text(
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
    if (!context.mounted) return;
    if (ok == true) {
      PermissionStore.I.set(kind, PermissionStatus.granted);
      Navigator.pop(context, true);
    } else {
      // 한 번 거부 → denied. 두 번 거부 → denied2 (설정에서만 가능)
      final cur = PermissionStore.I.get(kind);
      PermissionStore.I.set(
        kind,
        cur == PermissionStatus.denied
            ? PermissionStatus.denied2
            : PermissionStatus.denied,
      );
      Navigator.pop(context, false);
    }
  }

  void _decline(BuildContext context) {
    PermissionStore.I.markPrimed(kind);
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_icon, color: AppColors.brandDark, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                customWhy ?? '${kind.label} 권한이 필요해요',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                kind.oneLineWhy,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 20),
            for (final b in _benefits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.brandDark, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b[0],
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800)),
                          Text(b[1],
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '필요한 순간에만 사용하고, 정보는 외부에 공유되지 않아요.',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _request(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('지금 허용하기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => _decline(context),
                child: const Text('나중에',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _showOpenSettingsSheet(
    BuildContext context, PermissionKind kind) async {
  return await showModalBottomSheet<bool>(
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
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF6E5),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.settings, color: AppColors.warning),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${kind.label} 권한이 차단되어 있어요',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '앱 내에서는 권한을 다시 켤 수 없어요. 시스템 설정에서 직접 변경해주세요.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. 시스템 설정 → 앱 → Sharework',
                          style: TextStyle(fontSize: 13)),
                      SizedBox(height: 4),
                      Text('2. 권한 → 원하는 권한 선택', style: TextStyle(fontSize: 13)),
                      SizedBox(height: 4),
                      Text('3. "허용" 으로 변경', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx, false),
                        child: const Text('나중에'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx, false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('시스템 설정으로 이동 (목업)')),
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('설정 열기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}
