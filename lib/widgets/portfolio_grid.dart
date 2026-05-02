import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class PortfolioGrid extends StatelessWidget {
  final List<PortfolioItem> items;
  final EdgeInsets padding;
  const PortfolioGrid({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('아직 등록된 포트폴리오가 없어요',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _PortfolioCard(item: items[i]),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioItem item;
  const _PortfolioCard({required this.item});

  Color _bgColor() {
    if (item.colorTag != null) {
      final s = item.colorTag!.replaceAll('#', '');
      return Color(int.parse('FF$s', radix: 16));
    }
    return AppColors.chipBg;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.title} 상세 (목업)')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: _bgColor(),
                alignment: Alignment.center,
                child: Icon(
                  item.kind == PortfolioKind.image
                      ? Icons.image_outlined
                      : Icons.link,
                  size: 36,
                  color: AppColors.brandDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
