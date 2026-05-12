import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';

class IdentityStatusScreen extends StatelessWidget {
  const IdentityStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = Dummy.me;
    final verified = me.identityVerified;
    return Scaffold(
      appBar: AppBar(title: const Text('본인인증 상태')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: verified ? AppColors.brandSoft : const Color(0xFFFFF6E5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      verified ? Icons.verified : Icons.gpp_maybe_outlined,
                      size: 32,
                      color: verified
                          ? AppColors.brandDark
                          : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      verified ? '본인인증 완료' : '본인인증 미완료',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: verified
                            ? AppColors.brandDark
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  verified
                      ? '신분증으로 인증된 사용자입니다. 프로필에 인증 배지가 표시돼요.'
                      : '본인인증을 완료하면 매칭 우선순위가 높아지고, 구인자에게 신뢰도 배지가 노출됩니다.',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Card(
            title: '인증 정보',
            children: [
              _Row(label: '이름', value: '김 ○ 바 (마스킹)'),
              _Row(
                label: '생년월일',
                value: verified ? '199*-**-**' : '미인증',
              ),
              _Row(
                label: '인증 일시',
                value: verified ? '2025-08-12 14:32' : '없음',
              ),
              _Row(
                label: '인증 방법',
                value: verified ? '신분증 OCR + SMS' : '미인증',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            title: '연결된 인증',
            children: [
              _Row(label: '휴대폰 본인인증', value: '✓ 완료'),
              _Row(
                label: '신분증',
                value: verified ? '✓ 완료' : '미완료',
              ),
              _Row(label: '공공기관 인증서', value: '연동 안 됨'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: () => context.push('/auth/identity'),
            icon: const Icon(Icons.refresh),
            label: Text(verified ? '재인증' : '인증하기'),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
