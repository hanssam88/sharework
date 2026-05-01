import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class RecommendedScreen extends StatelessWidget {
  const RecommendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = Dummy.me;
    final prefs = Dummy.preferences;
    final scouts = Dummy.scouts
        .where((s) => s.toWorkerId == me.id && s.status == ScoutStatus.sent)
        .toList();
    final allOpen =
        Dummy.jobs.where((j) => j.status == JobStatus.open).toList();
    final byPreferred = allOpen
        .where((j) =>
            prefs.preferredCategories.contains(j.category) ||
            prefs.preferredWorkTypes.contains(j.workType))
        .toList();
    final nearby = allOpen
        .where((j) => !byPreferred.contains(j))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('추천 알바')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
        children: [
          _Hero(name: me.name),
          if (scouts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionHeader(
              title: '받은 스카웃',
              subtitle: '구인자가 직접 보낸 제안',
            ),
            ...scouts.map((s) => _ScoutCard(s: s)),
          ],
          const SizedBox(height: 16),
          const _SectionHeader(
            title: '내 조건에 맞는 공고',
            subtitle: '카테고리·근무유형 매칭 + 거리 가중치',
          ),
          if (byPreferred.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('조건 매칭 공고가 없어요. 희망 조건을 다양화해보세요.',
                  style: TextStyle(color: AppColors.textMuted)),
            )
          else
            ...byPreferred.map((j) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: JobCard(
                    job: j,
                    distanceKm: 1.0 + j.id % 5,
                    onTap: () => context.push('/job/${j.id}'),
                  ),
                )),
          if (nearby.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionHeader(
              title: '근처에서 인기 있는 공고',
              subtitle: '반경 ${5}km 이내',
            ),
            ...nearby.map((j) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: JobCard(
                    job: j,
                    distanceKm: 1.5 + j.id % 7,
                    onTap: () => context.push('/job/${j.id}'),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String name;
  const _Hero({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandDark, AppColors.brand],
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
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '$name 님께 어울리는 알바',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '활동 이력·받은 리뷰·희망 조건을 종합해 추천해드려요.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('AI 매칭 v2.1',
                      style:
                          TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _ScoutCard extends StatelessWidget {
  final Scout s;
  const _ScoutCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brandDark, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.send_to_mobile,
                    color: AppColors.brandDark, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${s.fromGiverName} 님이 스카웃을 보냈어요',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDark,
                  ),
                ),
                const Spacer(),
                Text(fmtRelative(s.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textFaint)),
              ],
            ),
            if (s.jobTitle != null) ...[
              const SizedBox(height: 6),
              Text(s.jobTitle!,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
            const SizedBox(height: 8),
            Text(s.message,
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: AppColors.text)),
            if (s.offerHourly != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 14, color: AppColors.brandDark),
                  const SizedBox(width: 4),
                  Text(
                    '제안 시급 ${fmtMoney(s.offerHourly!)}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.brandDark,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('거절했습니다 (목업)')),
                      );
                    },
                    child: const Text('거절'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('수락했습니다. 채팅으로 연결돼요. (목업)')),
                      );
                    },
                    child: const Text('수락하고 채팅'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
