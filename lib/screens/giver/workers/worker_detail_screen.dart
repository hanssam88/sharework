import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/portfolio_grid.dart';
import '../../../widgets/resume_view.dart';
import '../../../widgets/shared.dart';

class WorkerDetailScreen extends StatelessWidget {
  final int workerId;
  const WorkerDetailScreen({super.key, required this.workerId});

  void _showScoutSheet(BuildContext context, AppUser u) {
    final messageCtrl = TextEditingController(
      text: '안녕하세요. 프로필 보고 연락드립니다. 함께 일하실 수 있을까요?',
    );
    final hourlyCtrl = TextEditingController(text: '13000');
    int? selectedJobId;
    final myJobs = Dummy.jobs.where((j) => j.status == JobStatus.open).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${u.name}님 스카웃',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  '구직자에게 직접 일감을 제안할 수 있어요. 채팅으로 연결됩니다.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                const Text('연결할 공고 (선택)',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (myJobs.isEmpty)
                  const Text('등록된 공고가 없어요',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted))
                else
                  Column(
                    children: myJobs
                        .map((j) => RadioListTile<int>(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                j.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              value: j.id,
                              groupValue: selectedJobId,
                              activeColor: AppColors.brandDark,
                              onChanged: (v) =>
                                  setSheet(() => selectedJobId = v),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 12),
                const Text('제안 시급',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextField(
                  controller: hourlyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(suffixText: '원'),
                ),
                const SizedBox(height: 12),
                const Text('메시지',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextField(
                  controller: messageCtrl,
                  maxLines: 4,
                  maxLength: 300,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${u.name}님께 스카웃을 보냈어요 (목업)')),
                          );
                        },
                        child: const Text('스카웃 보내기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = Dummy.userById(workerId);
    final reviews = Dummy.reviews;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('워커 프로필'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: '단골 워커 추가',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${u.name}님을 단골 워커에 추가했어요 (목업)')),
                );
              },
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.brandSoft,
                      child: Icon(Icons.person,
                          size: 44, color: AppColors.brandDark),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(u.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        if (u.identityVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              color: AppColors.brandDark, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFFC400), size: 16),
                        const SizedBox(width: 2),
                        Text('${u.rating}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Text('· 리뷰 ${u.reviewCount}개',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                    if (u.verificationBadges.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: u.verificationBadges
                            .map((b) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(b,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brandDark)),
                                ))
                            .toList(),
                      ),
                    ],
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
                  tabs: [
                    Tab(text: '이력서'),
                    Tab(text: '포트폴리오'),
                    Tab(text: '리뷰'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ResumeView(
                      resume: Dummy.resume,
                      userTags: u.tags,
                    ),
                    PortfolioGrid(items: Dummy.portfolio),
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
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    child: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.text),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showScoutSheet(context, u),
                    icon: const Icon(Icons.send),
                    label: const Text('스카웃 보내기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
