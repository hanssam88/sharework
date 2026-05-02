import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lvl = Dummy.levelInfo;
    final missions = Dummy.missions;
    return Scaffold(
      appBar: AppBar(title: const Text('등급·포인트')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 등급 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lvl.color, lvl.color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(lvl.icon, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Text(lvl.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('${lvl.currentPoint}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        )),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, top: 6),
                      child: Text('P',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: lvl.progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '다음 등급까지 ${lvl.nextLevelPoint - lvl.currentPoint}P 남음',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 혜택
          _Section(
            title: '${lvl.name} 등급 혜택',
            child: Column(
              children: lvl.benefits
                  .map((b) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.brandDark, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(b,
                                  style:
                                      const TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          // 미션
          _Section(
            title: '진행 중인 미션',
            trailing: TextButton(
              onPressed: () => context.push('/events'),
              child: const Text('전체 보기'),
            ),
            child: Column(
              children: missions
                  .map((m) => _MissionRow(m: m))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          // 포인트 활용
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.redeem, color: AppColors.brandDark),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '포인트로 쿠폰을 교환할 수 있어요',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/me/coupons'),
                  child: const Text('쿠폰함'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  const _Section({required this.title, this.trailing, required this.child});

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
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final Mission m;
  const _MissionRow({required this.m});

  @override
  Widget build(BuildContext context) {
    final completed = m.status != MissionStatus.ongoing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: completed ? AppColors.brandSoft : AppColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(m.icon,
                color: completed
                    ? AppColors.brandDark
                    : AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(m.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                    Text(
                      '+${m.rewardPoint}P',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: completed
                            ? AppColors.brandDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: m.rate,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      completed
                          ? AppColors.success
                          : AppColors.brandDark,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completed
                      ? (m.status == MissionStatus.claimed
                          ? '수령 완료'
                          : '🎉 보상 수령 가능')
                      : '${m.progress}/${m.goal}',
                  style: TextStyle(
                    fontSize: 11,
                    color: completed
                        ? AppColors.success
                        : AppColors.textFaint,
                    fontWeight: FontWeight.w600,
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
