import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/portfolio_grid.dart';
import '../../widgets/resume_view.dart';
import '../../widgets/shared.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _favorited = false;
  String _reviewSort = '최신순';

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _toggleFavorite(AppUser u) {
    setState(() => _favorited = !_favorited);
    _snack(_favorited ? '${u.name}님을 즐겨찾기에 추가' : '즐겨찾기에서 제거');
  }

  void _openShareSheet(AppUser u) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('프로필 공유',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                children: [
                  _shareTile(Icons.chat_bubble, '카카오톡', const Color(0xFFFEE500),
                      onTap: () {
                    Navigator.pop(sheetCtx);
                    _snack('카카오톡 공유 (목업)');
                  }),
                  _shareTile(Icons.link, '링크 복사', AppColors.brandSoft,
                      onTap: () {
                    Navigator.pop(sheetCtx);
                    _snack('https://sharework.kr/u/${u.id} 복사됨');
                  }),
                  _shareTile(Icons.qr_code, 'QR 코드', AppColors.chipBg,
                      onTap: () {
                    Navigator.pop(sheetCtx);
                    _snack('QR 다이얼로그 (목업)');
                  }),
                  _shareTile(Icons.ios_share, '다른 앱', AppColors.chipBg,
                      onTap: () {
                    Navigator.pop(sheetCtx);
                    _snack('시스템 공유 시트 (목업)');
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareTile(IconData icon, String label, Color bg,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.text, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showMore(AppUser u) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('프로필 공유'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _openShareSheet(u);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('소개글 복사'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('소개글이 복사되었어요');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined,
                  color: AppColors.danger),
              title: const Text('신고하기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/report/user/${u.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.danger),
              title: const Text('차단하기'),
              subtitle: const Text(
                  '이 사용자의 공고·메시지가 더 이상 보이지 않아요',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmBlock(u);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBlock(AppUser u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${u.name}님을 차단하시겠어요?'),
        content: const Text(
            '차단하면 이 사용자의 공고·메시지가 더 이상 보이지 않고, 채팅도 차단됩니다. 마이페이지 > 차단 목록에서 해제할 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(80, 40),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              _snack('${u.name}님을 차단했어요');
              context.pop();
            },
            child: const Text('차단'),
          ),
        ],
      ),
    );
  }

  // 평점 분포 (목업: 결정적)
  Map<int, int> _ratingDistribution(int reviewCount) {
    return {
      5: (reviewCount * 0.62).round(),
      4: (reviewCount * 0.24).round(),
      3: (reviewCount * 0.10).round(),
      2: (reviewCount * 0.03).round(),
      1: (reviewCount * 0.01).round(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = Dummy.userById(widget.userId);
    final reviews = [...Dummy.reviews];
    if (_reviewSort == '별점높은순') {
      reviews.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_reviewSort == '별점낮은순') {
      reviews.sort((a, b) => a.rating.compareTo(b.rating));
    } else {
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final isWorker = user.appType == AppType.worker;
    final tabCount = isWorker ? 4 : 2;
    final hireCount = Dummy.regulars
        .where((r) => r.workerId == user.id)
        .fold(0, (a, r) => a + r.hireCount);

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로필'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _openShareSheet(user),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMore(user),
            ),
          ],
        ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        if (user.identityVerified) ...[
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
                        Text('${user.rating}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Text('· 리뷰 ${user.reviewCount}개',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13)),
                      ],
                    ),
                    if (user.verificationBadges.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: user.verificationBadges
                            .map((b) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSoft,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.brandDark
                                            .withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified,
                                          size: 12,
                                          color: AppColors.brandDark),
                                      const SizedBox(width: 3),
                                      Text(b,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.brandDark,
                                          )),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 신뢰도 통계
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: '함께한 횟수',
                            value: '$hireCount회',
                            icon: Icons.handshake_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            label: '응답 평균',
                            value: '${5 + user.id % 25}분',
                            icon: Icons.bolt_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            label: '완료율',
                            value: '${94 + user.id % 6}%',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _snack('채팅방 진입 (목업)'),
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 18),
                            label: const Text('채팅'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _toggleFavorite(user),
                            icon: Icon(
                              _favorited
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 18,
                              color: _favorited
                                  ? AppColors.brandDark
                                  : null,
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  _favorited ? AppColors.brandSoft : null,
                              side: BorderSide(
                                color: _favorited
                                    ? AppColors.brandDark
                                    : AppColors.divider,
                              ),
                            ),
                            label: Text(_favorited ? '즐겨찾기 됨' : '즐겨찾기'),
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
              ColoredBox(
                color: Colors.white,
                child: TabBar(
                  isScrollable: !isWorker ? false : true,
                  indicatorColor: AppColors.brandDark,
                  labelColor: AppColors.brandDark,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: [
                    const Tab(text: '소개'),
                    if (isWorker) const Tab(text: '이력서'),
                    if (isWorker) const Tab(text: '포트폴리오'),
                    Tab(text: '리뷰 ${user.reviewCount}'),
                  ],
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
                                fontSize: 13,
                                color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Text(user.introduction,
                            style: const TextStyle(
                                fontSize: 14, height: 1.5)),
                        const SizedBox(height: 24),
                        const Text('태그',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted)),
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
                    if (isWorker)
                      ResumeView(
                        resume: Dummy.resume,
                        userTags: user.tags,
                      ),
                    if (isWorker)
                      PortfolioGrid(items: Dummy.portfolio),
                    _ReviewsTab(
                      user: user,
                      reviews: reviews,
                      sort: _reviewSort,
                      distribution:
                          _ratingDistribution(user.reviewCount),
                      onSortChange: (v) =>
                          setState(() => _reviewSort = v),
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

class _ReviewsTab extends StatelessWidget {
  final AppUser user;
  final List<Review> reviews;
  final String sort;
  final Map<int, int> distribution;
  final ValueChanged<String> onSortChange;
  const _ReviewsTab({
    required this.user,
    required this.reviews,
    required this.sort,
    required this.distribution,
    required this.onSortChange,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount =
        distribution.values.fold<int>(1, (a, b) => a > b ? a : b);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 평점 분포 카드
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Column(
                children: [
                  Text('${user.rating}',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w800)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final filled = i < user.rating.round();
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 14,
                        color: filled
                            ? const Color(0xFFFFC400)
                            : AppColors.textFaint,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text('리뷰 ${user.reviewCount}개',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final cnt = distribution[star] ?? 0;
                    final ratio = maxCount == 0 ? 0.0 : cnt / maxCount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            child: Text('$star',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: AppColors.chipBg,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.brandDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 28,
                            child: Text('$cnt',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        // 정렬
        Container(
          color: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Spacer(),
              DropdownButton<String>(
                value: sort,
                underline: const SizedBox(),
                iconSize: 18,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.text,
                    fontWeight: FontWeight.w700),
                items: const [
                  DropdownMenuItem(value: '최신순', child: Text('최신순')),
                  DropdownMenuItem(value: '별점높은순', child: Text('별점높은순')),
                  DropdownMenuItem(value: '별점낮은순', child: Text('별점낮은순')),
                ],
                onChanged: (v) => onSortChange(v ?? '최신순'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        // 리뷰 리스트
        ...reviews.map((r) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ReviewCard(review: r),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.brandDark),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color ?? AppColors.text)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
