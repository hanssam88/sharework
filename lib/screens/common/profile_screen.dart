import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class ProfileScreen extends StatelessWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final user = Dummy.userById(userId);
    final reviews = Dummy.reviews;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('프로필')),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.brandSoft,
                      child: Icon(Icons.person,
                          size: 44, color: AppColors.brandDark),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFFC400), size: 16),
                        const SizedBox(width: 2),
                        Text('${user.rating}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Text('· 리뷰 ${user.reviewCount}개',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 18),
                            label: const Text('채팅'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.bookmark_border, size: 18),
                            label: const Text('즐겨찾기'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: Column(
            children: [
              const ColoredBox(
                color: Colors.white,
                child: TabBar(
                  indicatorColor: AppColors.brandDark,
                  labelColor: AppColors.brandDark,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: [Tab(text: '소개'), Tab(text: '리뷰')],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text('소개',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Text(user.introduction,
                            style: const TextStyle(
                                fontSize: 14, height: 1.5)),
                        const SizedBox(height: 24),
                        const Text('태그',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: user.tags
                              .map((t) => TagChip('#$t', primary: true))
                              .toList(),
                        ),
                      ],
                    ),
                    ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => ReviewCard(review: reviews[i]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
