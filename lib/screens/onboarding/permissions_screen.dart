import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<String, bool> _granted = {
    'location': false,
    'notification': false,
    'camera': false,
  };

  void _grant(String key) {
    setState(() => _granted[key] = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('권한이 허용되었어요 (목업)')),
    );
  }

  void _next() => context.go('/auth/phone');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '시작 전, 권한을 확인해주세요',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                '서비스를 정상적으로 이용하려면 아래 권한이 필요해요. 언제든 설정에서 변경할 수 있어요.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted, height: 1.6),
              ),
              const SizedBox(height: 28),
              _PermItem(
                icon: Icons.location_on_outlined,
                title: '위치 (필수)',
                desc: '내 주변 일감을 보여주고 거리 계산에 사용해요',
                granted: _granted['location']!,
                onTap: () => _grant('location'),
              ),
              const SizedBox(height: 12),
              _PermItem(
                icon: Icons.notifications_outlined,
                title: '알림',
                desc: '채용 확정·정산 완료 등 중요한 소식을 받아요',
                granted: _granted['notification']!,
                onTap: () => _grant('notification'),
              ),
              const SizedBox(height: 12),
              _PermItem(
                icon: Icons.camera_alt_outlined,
                title: '카메라·사진',
                desc: '본인인증·자격증·포트폴리오 등록에 사용해요',
                granted: _granted['camera']!,
                onTap: () => _grant('camera'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _next,
                child: const Text('계속하기'),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _next,
                  child: const Text('나중에 설정',
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

class _PermItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool granted;
  final VoidCallback onTap;
  const _PermItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted ? AppColors.brandDark : AppColors.divider,
          width: granted ? 1.5 : 1,
        ),
      ),
      child: Row(
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          granted
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.check_circle,
                      color: AppColors.brandDark),
                )
              : OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 36),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('허용'),
                ),
        ],
      ),
    );
  }
}
