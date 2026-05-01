import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _keyword = '';
  String _category = '전체';

  List<String> get _categories {
    final set = <String>{'전체'};
    for (final f in Dummy.faqs) {
      set.add(f.category);
    }
    return set.toList();
  }

  List<FaqItem> get _filtered {
    return Dummy.faqs.where((f) {
      final matchCat = _category == '전체' || f.category == _category;
      final matchKw = _keyword.isEmpty ||
          f.question.contains(_keyword) ||
          f.answer.contains(_keyword);
      return matchCat && matchKw;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자주 묻는 질문')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '검색어를 입력하세요',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
              onChanged: (v) => setState(() => _keyword = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final c = _categories[i];
                final on = c == _category;
                return Center(
                  child: ChoiceChip(
                    label: Text(c),
                    selected: on,
                    onSelected: (_) => setState(() => _category = c),
                    selectedColor: AppColors.brandSoft,
                    labelStyle: TextStyle(
                      color: on ? AppColors.brandDark : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    message: '검색 결과가 없어요',
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final f = _filtered[i];
                      return ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        title: Text(f.question,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text(f.category,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textFaint)),
                        children: [
                          Container(
                            color: AppColors.bg,
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: Text(f.answer,
                                style: const TextStyle(
                                    fontSize: 13, height: 1.5)),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
