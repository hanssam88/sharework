import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final jobs = Dummy.jobs.where((j) => j.status == JobStatus.open).toList();
    final appliedCount = Dummy.applications
        .where((a) => a.status == ApplicationStatus.applied)
        .length;
    final hiredCount = Dummy.applications
        .where((a) => a.status == ApplicationStatus.hired)
        .length;

    return Scaffold(
      body: Stack(
        children: [
          const _MapPlaceholder(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: _SearchBar(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _StatusPill(
                    label: '지원중', count: appliedCount, color: Colors.blue),
                const SizedBox(width: 8),
                _StatusPill(
                    label: '다가오는알바',
                    count: hiredCount,
                    color: AppColors.brandDark),
                const Spacer(),
                _RecommendedPill(
                  onTap: () => context.push('/recommended'),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              children: [
                _Fab(
                  icon: Icons.star_border,
                  onTap: () => _showFavoritesDialog(context),
                ),
                const SizedBox(height: 10),
                _Fab(
                  icon: Icons.my_location,
                  onTap: () {},
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.12,
            maxChildSize: 0.92,
            builder: (ctx, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2)),
                  ],
                ),
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: jobs.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Column(
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '주변 일자리 ${jobs.length}건',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                onPressed: () => context.push('/search'),
                                icon: const Icon(Icons.tune, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }
                    final job = jobs[i - 1];
                    return JobCard(
                      job: job,
                      distanceKm: 1.0 + i * 0.7,
                      onTap: () => context.push('/job/${job.id}'),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFavoritesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('즐겨찾는 위치',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...Dummy.locationFavorites.map((f) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bookmark, color: AppColors.brandDark),
                    title: Text(f.label),
                    subtitle: Text(f.address),
                    trailing: const Icon(Icons.close, size: 18),
                  )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('현재 위치 추가'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: AppColors.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '지역·키워드로 검색',
              style: TextStyle(color: AppColors.textFaint),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedPill extends StatelessWidget {
  final VoidCallback onTap;
  const _RecommendedPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.brandDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('추천',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusPill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(width: 4),
          Text('$count건',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Fab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.text),
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3F2F5), Color(0xFFD2EFEC)],
        ),
      ),
      child: Stack(
        children: [
          // grid
          ...List.generate(20, (i) => Positioned(
                left: 0,
                right: 0,
                top: i * 50.0,
                child: Container(height: 1, color: Colors.white.withOpacity(0.5)),
              )),
          ...List.generate(20, (i) => Positioned(
                top: 0,
                bottom: 0,
                left: i * 50.0,
                child: Container(width: 1, color: Colors.white.withOpacity(0.5)),
              )),
          // fake markers
          const Positioned(
            top: 200,
            left: 80,
            child: _Marker(label: '1.2만'),
          ),
          const Positioned(
            top: 280,
            left: 200,
            child: _Marker(label: '5건'),
          ),
          const Positioned(
            top: 350,
            right: 60,
            child: _Marker(label: '10만'),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final String label;
  const _Marker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
