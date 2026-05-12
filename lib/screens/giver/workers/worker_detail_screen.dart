import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/portfolio_grid.dart';
import '../../../widgets/resume_view.dart';
import '../../../widgets/shared.dart';

class WorkerDetailScreen extends StatefulWidget {
  final int workerId;
  const WorkerDetailScreen({super.key, required this.workerId});

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  bool _isRegular = false;
  bool _isFavorite = false;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 함께한 횟수 (목업: 결정적)
  int _hireCount(int workerId) {
    final regular =
        Dummy.regulars.where((r) => r.workerId == workerId).toList();
    return regular.isEmpty ? 0 : regular.first.hireCount;
  }

  void _toggleRegular(AppUser u) {
    setState(() => _isRegular = !_isRegular);
    _snack(_isRegular ? '${u.name}님을 단골 워커에 추가했어요' : '단골 워커에서 제거했어요');
  }

  void _toggleFavorite(AppUser u) {
    setState(() => _isFavorite = !_isFavorite);
    _snack(_isFavorite ? '즐겨찾기에 추가' : '즐겨찾기에서 제거');
  }

  void _openMoreMenu(AppUser u) {
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
              subtitle:
                  const Text('동료 사장님께 추천', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('https://sharework.kr/worker/${u.id} 복사됨');
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('비교 목록에 추가'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('비교 목록에 추가 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.danger),
              title: const Text('신고하기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/report/user/${u.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.danger),
              title: const Text('차단하기'),
              subtitle: const Text('내 공고에 다시 지원할 수 없어요',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${u.name}님을 차단하시겠어요?'),
        content: const Text('차단된 워커는 내 공고에 지원·문의할 수 없고, 채팅도 차단돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              _snack('${u.name}님을 차단했어요');
              Navigator.pop(context);
            },
            child: const Text('차단'),
          ),
        ],
      ),
    );
  }

  void _showScoutSheet(BuildContext context, AppUser u) {
    int? selectedJobId;
    int hourly = 13000;
    String? selectedTemplate;
    final messageCtrl = TextEditingController(
      text: '안녕하세요. 프로필 보고 연락드립니다. 함께 일하실 수 있을까요?',
    );
    final myJobs = Dummy.jobs.where((j) => j.status == JobStatus.open).toList();

    final templates = const [
      _ScoutTemplate(
        name: '신규 채용 제안',
        body: '안녕하세요, 프로필 보고 연락드립니다. 다음 근무에 함께해주실 수 있을까요?',
      ),
      _ScoutTemplate(
        name: '단골 재의뢰',
        body: '저번에 같이 일했던 알바입니다. 비슷한 일정으로 다시 모실 수 있으면 좋겠어요!',
      ),
      _ScoutTemplate(
        name: '시급 우대',
        body: '경력이 좋아 보여서 시급 우대해드리려 해요. 일정 가능하시면 회신 부탁드립니다.',
      ),
      _ScoutTemplate(
        name: '면접 요청',
        body: '간단한 사전 면접 후 진행하려고 합니다. 가능한 시간을 알려주세요.',
      ),
    ];

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
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                const Text('메시지 템플릿',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: templates.map((t) {
                    final on = selectedTemplate == t.name;
                    return ChoiceChip(
                      label: Text(t.name),
                      selected: on,
                      showCheckmark: false,
                      selectedColor: AppColors.brandDark,
                      labelStyle: TextStyle(
                        color: on ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setSheet(() {
                        selectedTemplate = t.name;
                        messageCtrl.text = t.body;
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('연결할 공고 (선택)',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (myJobs.isEmpty)
                  const Text('등록된 공고가 없어요',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted))
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
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: hourly.toDouble(),
                          min: 10000,
                          max: 25000,
                          divisions: 30,
                          activeColor: AppColors.brandDark,
                          inactiveColor: AppColors.chipBg,
                          label: '${(hourly / 1000).toStringAsFixed(0)}천원',
                          onChanged: (v) => setSheet(() => hourly = v.toInt()),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text('${hourly}원',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDark)),
                    ),
                  ],
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
                          _snack('${u.name}님께 스카웃 발송 (시급 ${hourly}원, 목업)');
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
    final u = Dummy.userById(widget.workerId);
    final reviews = Dummy.reviews;
    final hireCount = _hireCount(u.id);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('워커 프로필'),
          actions: [
            IconButton(
              icon: Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border),
              color: _isFavorite ? AppColors.brandDark : null,
              tooltip: '즐겨찾기',
              onPressed: () => _toggleFavorite(u),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _openMoreMenu(u),
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
                                fontSize: 20, fontWeight: FontWeight.w800)),
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
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
                    const SizedBox(height: 16),

                    // 통계 카드
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
                            label: '응답률',
                            value: '${85 + (u.id * 3) % 12}%',
                            icon: Icons.bolt_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            label: '노쇼율',
                            value: '0%',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
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
                    onPressed: () => _snack('채팅방 진입 (목업)'),
                    child: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.text),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: _isRegular ? AppColors.brandSoft : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                          color: _isRegular
                              ? AppColors.brandDark
                              : AppColors.divider),
                    ),
                    onPressed: () => _toggleRegular(u),
                    child: Icon(
                      _isRegular ? Icons.star : Icons.star_outline,
                      color: _isRegular ? AppColors.brandDark : AppColors.text,
                    ),
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
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ScoutTemplate {
  final String name;
  final String body;
  const _ScoutTemplate({required this.name, required this.body});
}
