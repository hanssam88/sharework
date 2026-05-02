import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';

class UserInfoUpdateScreen extends StatelessWidget {
  const UserInfoUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = Dummy.me;
    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필 수정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.brandSoft,
                  child: Icon(Icons.person,
                      size: 48, color: AppColors.brandDark),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.brandDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _Field(label: '이름'),
          TextField(
            decoration: const InputDecoration(),
            controller: TextEditingController(text: me.name),
          ),
          const SizedBox(height: 16),
          const _Field(label: '휴대폰 번호'),
          TextField(
            enabled: false,
            decoration: const InputDecoration(),
            controller: TextEditingController(text: me.phone),
          ),
          const SizedBox(height: 16),
          const _Field(label: '이메일'),
          TextField(
            decoration: const InputDecoration(),
            controller: TextEditingController(text: me.email),
          ),
          const SizedBox(height: 16),
          const _Field(label: '주소'),
          TextField(
            decoration: const InputDecoration(),
            controller: TextEditingController(text: me.address),
          ),
          const SizedBox(height: 16),
          const _Field(label: '한 줄 소개'),
          TextField(
            maxLines: 3,
            decoration: const InputDecoration(),
            controller: TextEditingController(text: me.introduction),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  const _Field({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      );
}
