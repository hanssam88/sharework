import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const _icons = {
    JobCategory.cafe: Icons.local_cafe_outlined,
    JobCategory.restaurant: Icons.restaurant_outlined,
    JobCategory.mart: Icons.storefront_outlined,
    JobCategory.logistics: Icons.local_shipping_outlined,
    JobCategory.delivery: Icons.delivery_dining_outlined,
    JobCategory.event: Icons.event_outlined,
    JobCategory.cleaning: Icons.cleaning_services_outlined,
    JobCategory.office: Icons.work_outline,
    JobCategory.etc: Icons.more_horiz,
  };

  static const _colors = {
    JobCategory.cafe: Color(0xFFFFF3E5),
    JobCategory.restaurant: Color(0xFFFFE5E5),
    JobCategory.mart: Color(0xFFE5F1FF),
    JobCategory.logistics: Color(0xFFEEF4FF),
    JobCategory.delivery: Color(0xFFFFF6E5),
    JobCategory.event: Color(0xFFE6F8F6),
    JobCategory.cleaning: Color(0xFFE8F8EE),
    JobCategory.office: Color(0xFFF1F3F5),
    JobCategory.etc: Color(0xFFF1F3F5),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('카테고리')),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
        children: JobCategory.values.map((c) {
          final count = Dummy.jobs
              .where((j) => j.category == c && j.status == JobStatus.open)
              .length;
          return InkWell(
            onTap: () => context.push('/categories/${c.name}'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _colors[c],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_icons[c],
                        size: 28, color: AppColors.brandDark),
                  ),
                  const SizedBox(height: 10),
                  Text(c.label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    count > 0 ? '$count건' : '준비중',
                    style: TextStyle(
                      fontSize: 11,
                      color: count > 0
                          ? AppColors.brandDark
                          : AppColors.textFaint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
