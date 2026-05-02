import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class InquiryListScreen extends StatelessWidget {
  const InquiryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = Dummy.inquiries;
    return Scaffold(
      appBar: AppBar(title: const Text('1:1 문의')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              message: '문의 내역이 없어요',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final q = items[i];
                final answered = q.status == InquiryStatus.answered;
                return Card(
                  child: InkWell(
                    onTap: () => _showDetail(context, q),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: answered
                                      ? const Color(0xFFE8F8EE)
                                      : AppColors.brandSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  answered ? '답변 완료' : '답변 대기',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: answered
                                        ? const Color(0xFF1F8E48)
                                        : AppColors.brandDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              TagChip(q.category),
                              const Spacer(),
                              Text(
                                fmtRelative(q.createdAt),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textFaint),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(q.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            q.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/support/inquiry/new'),
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('문의 작성'),
      ),
    );
  }

  void _showDetail(BuildContext context, Inquiry q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(q.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  TagChip(q.category),
                  const SizedBox(width: 6),
                  Text(fmtRelative(q.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textFaint)),
                ],
              ),
              const SizedBox(height: 16),
              Text(q.body,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              if (q.answer != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.support_agent,
                              size: 16, color: AppColors.brandDark),
                          SizedBox(width: 6),
                          Text('고객센터 답변',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandDark)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(q.answer!,
                          style: const TextStyle(fontSize: 14, height: 1.5)),
                    ],
                  ),
                ),
              ] else
                const Text(
                  '답변 대기 중입니다. 영업일 기준 24시간 내 답변을 드릴게요.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
