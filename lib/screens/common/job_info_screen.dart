import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class JobInfoScreen extends StatefulWidget {
  final int jobId;
  const JobInfoScreen({super.key, required this.jobId});

  @override
  State<JobInfoScreen> createState() => _JobInfoScreenState();
}

class _JobInfoScreenState extends State<JobInfoScreen> {
  bool _bookmarked = false;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Duration _shiftDuration(Job job) {
    final d = job.endAt.difference(job.startAt);
    return d.isNegative ? Duration.zero : d;
  }

  int _expectedPay(Job job) {
    if (job.payType == '시급') {
      final hours = _shiftDuration(job).inMinutes / 60.0;
      return (job.pay * hours).round();
    }
    return job.pay; // 일급 등은 그대로
  }

  void _toggleBookmark() {
    setState(() => _bookmarked = !_bookmarked);
    _snack(_bookmarked ? '즐겨찾는 매장에 추가했어요' : '즐겨찾기에서 제거했어요');
  }

  void _openShareSheet(Job job) {
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
                child: Text('공고 공유',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                children: [
                  _shareTile(
                      Icons.chat_bubble, '카카오톡', const Color(0xFFFEE500),
                      onTap: () {
                    Navigator.pop(sheetCtx);
                    _snack('카카오톡 공유 (목업)');
                  }),
                  _shareTile(Icons.link, '링크 복사', AppColors.brandSoft,
                      onTap: () {
                    Navigator.pop(sheetCtx);
                    _snack('https://sharework.kr/job/${job.id} 복사됨');
                  }),
                  _shareTile(Icons.qr_code, 'QR 코드', AppColors.chipBg,
                      onTap: () {
                    Navigator.pop(sheetCtx);
                    _showQrDialog(job);
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

  void _showQrDialog(Job job) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('공고 QR 코드'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.qr_code,
                  size: 140, color: AppColors.text),
            ),
            const SizedBox(height: 12),
            Text('공고 #${job.id} · ${job.giverName}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              _snack('QR 이미지 저장 완료 (목업)');
            },
            child: const Text('이미지 저장'),
          ),
        ],
      ),
    );
  }

  void _openRouteSheet() {
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('길찾기 앱 선택',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ListTile(
              leading: _appIcon(Icons.map_outlined, const Color(0xFFFFC400)),
              title: const Text('카카오맵'),
              subtitle: const Text('자동차·도보 경로',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('카카오맵으로 길찾기 (목업)');
              },
            ),
            ListTile(
              leading: _appIcon(Icons.map, const Color(0xFF03C75A)),
              title: const Text('네이버 지도'),
              subtitle: const Text('자동차·대중교통·도보',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('네이버 지도로 길찾기 (목업)');
              },
            ),
            ListTile(
              leading: _appIcon(Icons.directions_car, const Color(0xFFE60000)),
              title: const Text('티맵'),
              subtitle: const Text('자동차 실시간 교통',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('티맵으로 길찾기 (목업)');
              },
            ),
            ListTile(
              leading: _appIcon(Icons.directions_bus, const Color(0xFF2F66E2)),
              title: const Text('대중교통 (카카오버스)'),
              subtitle: const Text('실시간 도착·환승',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('대중교통 안내 (목업)');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _appIcon(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _openInquirySheet(Job job) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('지원 전 사전 문의',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '${job.giverName} 사장님께 1회 무료로 질문할 수 있어요. 사전 문의를 보낸 워커는 지원율이 평균 28% 더 높아요.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    '시간 조정 가능한가요?',
                    '주차 공간 있나요?',
                    '복장 규정은요?',
                    '식사 시간 별도 있나요?',
                  ]
                      .map((q) => ActionChip(
                            label: Text(q,
                                style: const TextStyle(fontSize: 12)),
                            onPressed: () => ctrl.text = q,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '예의 있게, 짧게 적어주세요.',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) {
                      _snack('내용을 입력해주세요');
                      return;
                    }
                    Navigator.pop(sheetCtx);
                    _snack('문의가 사장님께 전송되었어요 (목업)');
                  },
                  child: const Text('문의 보내기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openReportSheet(Job job) {
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('이 공고 신고/문의',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            _reportTile(sheetCtx, '임금·조건이 실제와 다름', Icons.report_outlined,
                () => context.push('/report/job/${job.id}')),
            _reportTile(sheetCtx, '광고·홍보 의심', Icons.campaign_outlined,
                () => context.push('/report/job/${job.id}')),
            _reportTile(sheetCtx, '부적절한 내용', Icons.flag_outlined,
                () => context.push('/report/job/${job.id}')),
            _reportTile(sheetCtx, '중복 공고', Icons.copy_all_outlined,
                () => context.push('/report/job/${job.id}')),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.headset_mic_outlined, color: AppColors.brandDark),
              title: const Text('고객센터에 문의'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/support/inquiry/new');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportTile(BuildContext sheetCtx, String label, IconData icon,
      VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.danger),
      title: Text(label),
      onTap: () {
        Navigator.pop(sheetCtx);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    final isHired = Dummy.applications.any((a) =>
        a.jobId == widget.jobId &&
        a.workerId == Dummy.me.id &&
        a.status == ApplicationStatus.hired);

    final shift = _shiftDuration(job);
    final expected = _expectedPay(job);
    final daysToStart = job.startAt.difference(DateTime.now()).inDays;
    final isImminent = daysToStart >= 0 && daysToStart <= 1;
    final isPopular = job.hiredCount >= 1 || job.personnel >= 5;

    final similar = Dummy.jobs
        .where((j) =>
            j.id != job.id &&
            j.status == JobStatus.open &&
            (j.category == job.category || j.giverId == job.giverId))
        .take(3)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('공고 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _openShareSheet(job),
          ),
          IconButton(
            icon: Icon(_bookmarked
                ? Icons.bookmark
                : Icons.bookmark_border),
            color: _bookmarked ? AppColors.brandDark : null,
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => _openReportSheet(job),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (isImminent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          daysToStart == 0 ? '오늘 시작' : 'D-1 마감 임박',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🔥 인기 공고',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    if (job.sameDayPayment)
                      const TagChip('당일지급', primary: true),
                    if (job.foodProvided) const TagChip('식사제공'),
                    if (job.extraPay) const TagChip('교통비지원'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(job.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                _InfoRow(
                    icon: Icons.location_on_outlined, text: job.address),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.access_time,
                  text:
                      '${fmtDate(job.startAt)} · ${fmtTime(job.startAt)} ~ ${fmtTime(job.endAt)}',
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  text: '${job.payType} ${fmtMoney(job.pay)}',
                  highlight: true,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                    icon: Icons.people_outline,
                    text: '${job.hiredCount}/${job.personnel}명 모집중'),
              ],
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg),

          // 시급 계산기
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calculate_outlined,
                          color: AppColors.brandDark, size: 18),
                      SizedBox(width: 6),
                      Text('예상 수입',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDark)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmtMoney(expected),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDark)),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '근무 ${shift.inHours}h ${shift.inMinutes.remainder(60)}m × ${fmtMoney(job.pay)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '※ 휴식 시간(있을 경우)·세금 3.3%는 자동 차감돼요',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg),

          // giver
          InkWell(
            onTap: () => context.push('/profile/${job.giverId}'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.brandSoft,
                    child: Icon(Icons.business, color: AppColors.brandDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.giverName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        const Row(
                          children: [
                            Icon(Icons.star,
                                color: Color(0xFFFFC400), size: 14),
                            SizedBox(width: 2),
                            Text('4.9 · 리뷰 128',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textFaint),
                ],
              ),
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: '상세 설명'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(job.description,
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
          if (job.tags.isNotEmpty) ...[
            const Divider(thickness: 8, color: AppColors.bg),
            const SectionHeader(title: '태그'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: job.tags.map((t) => TagChip('#$t')).toList(),
              ),
            ),
          ],
          if (job.checklists.isNotEmpty) ...[
            const Divider(thickness: 8, color: AppColors.bg),
            const SectionHeader(title: '지원 전 체크리스트'),
            ...job.checklists.map((c) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_box_outline_blank,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],

          const Divider(thickness: 8, color: AppColors.bg),

          // 근무 위치 + 길찾기
          SectionHeader(
            title: '근무 위치',
            trailing: TextButton.icon(
              onPressed: _openRouteSheet,
              icon: const Icon(Icons.directions, size: 16),
              label: const Text('길찾기'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 160,
                color: const Color(0xFFE3F2F5),
                alignment: Alignment.center,
                child: const Icon(Icons.location_pin,
                    size: 36, color: AppColors.brandDark),
              ),
            ),
          ),

          // 유사 공고
          if (similar.isNotEmpty) ...[
            const Divider(thickness: 8, color: AppColors.bg),
            SectionHeader(
              title: '${job.giverName}의 다른 공고 · 유사 공고',
              trailing: TextButton(
                onPressed: () =>
                    context.push('/categories/${job.category.name}'),
                child: const Text('더보기'),
              ),
            ),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: similar.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final j = similar[i];
                  return SizedBox(
                    width: 240,
                    child: JobCard(
                      job: j,
                      onTap: () => context.push('/job/${j.id}'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHired && job.status != JobStatus.done) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/job/${job.id}/contract'),
                        icon: const Icon(Icons.description_outlined,
                            size: 18),
                        label: Text(
                          job.contractStatus == ContractStatus.signed
                              ? '계약서 보기'
                              : '계약서 서명',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/job/${job.id}/checkin'),
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('출퇴근 체크'),
                      ),
                    ),
                  ],
                ),
              ] else
                Row(
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
                        onPressed: () => _openInquirySheet(job),
                        child: const Icon(Icons.chat_bubble_outline,
                            color: AppColors.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: job.status == JobStatus.done
                          ? FilledButton.icon(
                              onPressed: () => context
                                  .push('/job/${job.id}/review/write'),
                              icon:
                                  const Icon(Icons.rate_review_outlined),
                              label: const Text('리뷰 작성'),
                            )
                          : FilledButton(
                              onPressed: () => _showApplyDialog(
                                  context, job.checklists),
                              child: const Text('지원하기'),
                            ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplyDialog(BuildContext context, List<String> items) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('지원 전 확인',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (items.isEmpty)
                const Text('정말 이 공고에 지원하시겠어요?')
              else ...items.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.brandDark, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(c)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _snack('지원이 접수되었습니다 (목업)');
            },
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: const Text('지원하기'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;
  const _InfoRow(
      {required this.icon, required this.text, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: highlight ? AppColors.brandDark : AppColors.text,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
