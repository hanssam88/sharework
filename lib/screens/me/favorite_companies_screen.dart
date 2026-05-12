import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class FavoriteCompaniesScreen extends StatefulWidget {
  const FavoriteCompaniesScreen({super.key});

  @override
  State<FavoriteCompaniesScreen> createState() =>
      _FavoriteCompaniesScreenState();
}

class _FavoriteCompaniesScreenState extends State<FavoriteCompaniesScreen> {
  late List<FavoriteCompany> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(Dummy.favoriteCompanies);
  }

  void _remove(FavoriteCompany c) {
    setState(() => _items.removeWhere((x) => x.giverId == c.giverId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${c.name} 즐겨찾기 해제'),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () => setState(() => _items.add(c)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('즐겨찾는 업체')),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border,
              message: '즐겨찾는 업체가 없어요',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = _items[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/profile/${c.giverId}'),
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
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.brandSoft,
                              child: Icon(Icons.business,
                                  color: AppColors.brandDark),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(c.address,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bookmark,
                                  color: AppColors.brandDark),
                              onPressed: () => _remove(c),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFFFC400), size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${c.rating} · 리뷰 ${c.reviewCount}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '진행중 ${c.recentJobsCount}건',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brandDark),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              fmtRelative(c.addedAt),
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textFaint),
                            ),
                          ],
                        ),
                        if (c.badges.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: c.badges.map((b) => TagChip(b)).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
