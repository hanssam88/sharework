import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/permission_state.dart';
import '../../theme/app_theme.dart';

class LocationPrimingScreen extends StatefulWidget {
  /// `next` 경로가 있으면 priming 종료 후 이동, 없으면 pop.
  final String? next;
  const LocationPrimingScreen({super.key, this.next});

  @override
  State<LocationPrimingScreen> createState() => _LocationPrimingScreenState();
}

class _LocationPrimingScreenState extends State<LocationPrimingScreen> {
  bool _showSystemDialog = false;

  void _close({bool granted = false}) {
    PermissionStore.I.markPrimed(PermissionKind.location);
    PermissionStore.I.set(
      PermissionKind.location,
      granted ? PermissionStatus.granted : PermissionStatus.denied,
    );
    if (widget.next != null) {
      context.go(widget.next!);
    } else {
      Navigator.of(context).pop(granted);
    }
  }

  void _showSystemPermissionDialog() async {
    setState(() => _showSystemDialog = true);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('"Sharework"이(가) 위치를 사용하도록 허용하시겠습니까?'),
        content: const Text(
          '근처 일자리를 보여드리고, 거리 계산·길안내·근무지 도착 확인에 사용합니다.\n\n'
          '시스템 다이얼로그 시뮬레이션 (목업)',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('허용 안 함'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('한 번만 허용'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('앱을 사용하는 동안 허용'),
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
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE5E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_off,
                      color: AppColors.danger),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('위치 권한 없이도 사용할 수 있어요',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '주소를 직접 입력하면 해당 지역의 일자리를 보여드릴게요. 거리 계산은 입력한 주소를 기준으로 표시됩니다.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: '검색할 지역',
                hintText: '예) 서울특별시 강남구 역삼동',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: const ['강남구', '마포구', '송파구', '성동구', '서초구']
                  .map((d) => ActionChip(
                        label: Text(d),
                        onPressed: () {
                          ctrl.text = '서울특별시 $d';
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _close(granted: false);
                    },
                    child: const Text('나중에'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (ctrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('지역을 입력해주세요')),
                        );
                        return;
                      }
                      PermissionStore.I.manualAddress = ctrl.text.trim();
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${ctrl.text.trim()} 기준으로 보여드릴게요')),
                      );
                      _close(granted: false);
                    },
                    child: const Text('주소로 사용'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.map_outlined,
                        size: 100, color: AppColors.brandDark),
                    Positioned(
                      top: 36,
                      child: Icon(Icons.location_pin,
                          size: 48, color: AppColors.danger),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '주변 일자리를 보여드리려면\n위치 정보가 필요해요',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                '다음 단계에서 시스템 권한 다이얼로그가 표시돼요. 한 번만 누르면 끝!',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted, height: 1.6),
              ),
              const SizedBox(height: 24),
              const _Benefit(
                icon: Icons.near_me,
                title: '주변 일자리 자동 표시',
                desc: '내 위치 1km/3km/5km 반경 추천',
              ),
              const _Benefit(
                icon: Icons.straighten,
                title: '거리 계산',
                desc: '"여기서 850m" 처럼 한눈에 거리 파악',
              ),
              const _Benefit(
                icon: Icons.where_to_vote,
                title: '근무지 도착 확인',
                desc: 'GPS 체크인 — 방문 거리 검증',
              ),
              const _Benefit(
                icon: Icons.directions_walk,
                title: '안전 동선',
                desc: '심야 근무 시 긴급연락처에 위치 공유',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 16, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '위치 정보는 매칭에만 사용되고 다른 사용자에게 공개되지 않아요. 언제든 끌 수 있습니다.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed:
                    _showSystemDialog ? null : _showSystemPermissionDialog,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('지금 허용하기',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _showFallbackSheet,
                  child: const Text('주소 직접 입력',
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

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _Benefit({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brandDark, size: 20),
          ),
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
        ],
      ),
    );
  }
}
