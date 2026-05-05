import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  Color _color(String tag) {
    final s = tag.replaceAll('#', '');
    return Color(int.parse('FF$s', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final banners = Dummy.eventBanners;
    final missions = Dummy.missions;
    return Scaffold(
      appBar: AppBar(title: const Text('이벤트·미션')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (banners.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: Text('진행 중인 이벤트',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            ...banners.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EventCard(banner: b, color: _color(b.colorTag)),
                )),
          ],
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Text('도전 미션',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          ...missions.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(m.icon, color: AppColors.brandDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(m.desc,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('+${m.rewardPoint}P',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brandDark)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: m.rate,
                          backgroundColor: AppColors.divider,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.brandDark),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('${m.progress}/${m.goal}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                          const Spacer(),
                          if (m.status == MissionStatus.completed)
                            const Text('🎉 수령 가능',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success))
                          else if (m.status == MissionStatus.claimed)
                            const Text('수령 완료',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textFaint))
                          else
                            const Text('진행 중',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textFaint)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventBanner banner;
  final Color color;
  const _EventCard({required this.banner, required this.color});

  @override
  Widget build(BuildContext context) {
    final daysLeft = banner.endAt.difference(DateTime.now()).inDays;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${banner.title} 상세 (목업)')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(banner.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(banner.subtitle,
                      style: const TextStyle(fontSize: 12, height: 1.5)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: AppColors.text),
                        const SizedBox(width: 4),
                        Text('${daysLeft}일 남음',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (banner.cta != null) ...[
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => context.push('/me/invite'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Text(banner.cta!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
