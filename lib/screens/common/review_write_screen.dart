import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';

class ReviewWriteScreen extends StatefulWidget {
  final int jobId;
  const ReviewWriteScreen({super.key, required this.jobId});

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  int _rating = 5;
  final Set<String> _selectedTags = {};
  final _contentCtrl = TextEditingController();
  final List<int> _photoPlaceholders = [];

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해주세요')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('리뷰가 등록되었습니다 (목업)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    return Scaffold(
      appBar: AppBar(title: const Text('리뷰 작성')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.work_outline, color: AppColors.brandDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(job.giverName,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '경험은 어떠셨나요?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  filled ? Icons.star : Icons.star_border,
                  size: 40,
                  color: filled
                      ? const Color(0xFFFFC400)
                      : AppColors.textFaint,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _rating == 0 ? '별점을 선택해주세요' : '$_rating점',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '인상 깊었던 점을 골라주세요',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Dummy.reviewTagPresets.map((t) {
              final on = _selectedTags.contains(t);
              return FilterChip(
                label: Text(t),
                selected: on,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedTags.add(t);
                    } else {
                      _selectedTags.remove(t);
                    }
                  });
                },
                selectedColor: AppColors.brandSoft,
                checkmarkColor: AppColors.brandDark,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            '한 줄 후기 (선택)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contentCtrl,
            maxLines: 5,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: '솔직한 후기는 다른 분들에게도 큰 도움이 됩니다.',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '사진 첨부 (선택)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_photoPlaceholders.length < 5) {
                    setState(() => _photoPlaceholders
                        .add(_photoPlaceholders.length + 1));
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.chipBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          color: AppColors.textMuted),
                      const SizedBox(height: 4),
                      Text(
                        '${_photoPlaceholders.length}/5',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _photoPlaceholders
                        .map((i) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.brandSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '#$i',
                                  style: const TextStyle(
                                      color: AppColors.brandDark,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _submit,
            child: const Text('리뷰 등록'),
          ),
        ),
      ),
    );
  }
}
