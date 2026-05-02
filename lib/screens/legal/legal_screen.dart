import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';

enum _FontScale { small, normal, large, xlarge }

extension _FontScaleX on _FontScale {
  double get size => switch (this) {
        _FontScale.small => 13,
        _FontScale.normal => 14,
        _FontScale.large => 16,
        _FontScale.xlarge => 18,
      };
  String get label => switch (this) {
        _FontScale.small => '작게',
        _FontScale.normal => '보통',
        _FontScale.large => '크게',
        _FontScale.xlarge => '특대',
      };
}

class LegalScreen extends StatefulWidget {
  final String docType; // terms / privacy / guide
  const LegalScreen({super.key, required this.docType});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searching = false;
  String _query = '';
  _FontScale _scale = _FontScale.normal;
  bool _agreed = true;
  late DateTime _agreedAt;
  bool _watchUpdates = false;

  // Section anchor offsets (rebuild on body change)
  final Map<String, double> _anchors = {};

  @override
  void initState() {
    super.initState();
    _agreedAt = DateTime.now().subtract(const Duration(days: 14));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title => switch (widget.docType) {
        'terms' => '이용약관',
        'privacy' => '개인정보 처리방침',
        'guide' => '이용가이드',
        _ => '문서',
      };

  String get _body =>
      Dummy.legalContents[widget.docType] ?? '문서를 불러올 수 없어요.';

  bool get _isLegal =>
      widget.docType == 'terms' || widget.docType == 'privacy';

  /// 본문에서 큰 제목 행을 추출 — '제N조 (xxx)' 또는 숫자.공백 패턴 또는 이모지로 시작하는 줄.
  List<String> get _toc {
    final lines = _body.split('\n');
    final out = <String>[];
    for (final raw in lines) {
      final l = raw.trim();
      if (l.isEmpty) continue;
      final isClause = RegExp(r'^제\d+조').hasMatch(l);
      final isNumbered = RegExp(r'^\d+[\.)]\s').hasMatch(l);
      final isHeading = RegExp(r'^[\p{So}\p{Sk}🎯🏪🔒]').hasMatch(l) ||
          (l.length < 28 && !l.endsWith('.') && !l.endsWith('요.') && l.contains(' '));
      if (isClause || isNumbered || isHeading && _isLegal == false) {
        out.add(l);
      }
    }
    return out;
  }

  void _showTocSheet() {
    final toc = _toc;
    if (toc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문서 목차가 없어요')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.list_alt, color: AppColors.brandDark),
                  const SizedBox(width: 8),
                  const Text('목차',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('${toc.length}개',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: scroll,
                  itemCount: toc.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = toc[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(t,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _jumpTo(t);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _jumpTo(String anchor) {
    // 본문은 단일 Text라 정확한 픽셀 점프는 어려우므로 검색 하이라이트로 대체
    setState(() {
      _searching = true;
      _query = anchor;
      _searchCtrl.text = anchor;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$anchor" 위치로 이동했어요')),
    );
  }

  void _showFontSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (innerCtx, innerSet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('글자 크기',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: _FontScale.values
                      .map((s) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () {
                                  innerSet(() => _scale = s);
                                  setState(() => _scale = s);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _scale == s
                                        ? AppColors.brandSoft
                                        : AppColors.bg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _scale == s
                                          ? AppColors.brandDark
                                          : AppColors.divider,
                                      width: _scale == s ? 1.5 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    children: [
                                      Text('가',
                                          style: TextStyle(
                                              fontSize: s.size + 2,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.brandDark)),
                                      const SizedBox(height: 4),
                                      Text(s.label,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '미리보기 — 본 약관은 사용자에게 ${_scale.label} 글자로 표시됩니다.',
                    style: TextStyle(
                        fontSize: _scale.size,
                        height: 1.6,
                        color: AppColors.text),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Text('완료'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_title 공유',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _shareTile(Icons.chat_bubble, '카카오톡',
                      const Color(0xFFFEE500), AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('카카오톡 공유 (목업)')),
                    );
                  }),
                  _shareTile(Icons.link, '링크 복사',
                      AppColors.brandSoft, AppColors.brandDark, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'https://share.work/legal/${widget.docType} 복사됨 (목업)')),
                    );
                  }),
                  _shareTile(Icons.picture_as_pdf, 'PDF 저장',
                      AppColors.chipBg, AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${_title}_v3.2.pdf (목업)')),
                    );
                  }),
                  _shareTile(Icons.ios_share, '다른 앱',
                      AppColors.chipBg, AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OS 공유 시트 (목업)')),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareTile(
      IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: fg),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showVersionsSheet() {
    final versions = const [
      ['v3.2', '2025.04.10', '결제대행사 추가 (토스페이먼츠), 환불 정책 명확화'],
      ['v3.1', '2025.01.18', '단골 워커 약관 추가, 분쟁 조정 단계 보강'],
      ['v3.0', '2024.10.02', '서비스 명칭 변경 (긱워크 → Sharework)'],
      ['v2.5', '2024.06.01', '에스크로 정산 방식 도입'],
      ['v2.4', '2024.03.15', '개인정보 보유기간 6개월로 단축'],
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('변경 이력',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final v in versions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: v == versions.first
                              ? AppColors.brandSoft
                              : AppColors.chipBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(v[0],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: v == versions.first
                                    ? AppColors.brandDark
                                    : AppColors.textMuted)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v[1],
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(v[2],
                                style: const TextStyle(
                                    fontSize: 13, height: 1.4)),
                          ],
                        ),
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

  void _showOtherDocsSheet() {
    final docs = const [
      ['terms', '이용약관', Icons.description_outlined],
      ['privacy', '개인정보 처리방침', Icons.privacy_tip_outlined],
      ['guide', '이용가이드', Icons.menu_book_outlined],
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('다른 문서로 이동',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final d in docs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(d[2] as IconData,
                      color: widget.docType == d[0]
                          ? AppColors.textFaint
                          : AppColors.brandDark),
                  title: Text(d[1] as String,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: widget.docType == d[0]
                              ? AppColors.textFaint
                              : AppColors.text)),
                  trailing: widget.docType == d[0]
                      ? const Text('현재 문서',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textFaint))
                      : const Icon(Icons.arrow_forward_ios, size: 12),
                  onTap: widget.docType == d[0]
                      ? null
                      : () {
                          Navigator.pop(sheetCtx);
                          context.replace('/${d[0]}');
                        },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu() {
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
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.list_alt,
                  color: AppColors.brandDark),
              title: const Text('목차'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showTocSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields,
                  color: AppColors.brandDark),
              title: const Text('글자 크기 (${_scale.label})'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showFontSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history,
                  color: AppColors.brandDark),
              title: const Text('변경 이력'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showVersionsSheet();
              },
            ),
            ListTile(
              leading: Icon(
                _watchUpdates
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
                color: AppColors.brandDark,
              ),
              title: Text(_watchUpdates ? '변경 알림 받는 중' : '변경 알림 받기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                setState(() => _watchUpdates = !_watchUpdates);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(_watchUpdates
                          ? '변경 시 알림으로 안내드릴게요'
                          : '알림이 해제되었어요')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz,
                  color: AppColors.brandDark),
              title: const Text('다른 문서로 이동'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showOtherDocsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined,
                  color: AppColors.brandDark),
              title: const Text('인쇄'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('인쇄 다이얼로그 (목업)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final body = _body;
    if (_query.isEmpty) {
      return Text(
        body,
        style: TextStyle(
          fontSize: _scale.size,
          height: 1.7,
          color: AppColors.text,
        ),
      );
    }
    final spans = <TextSpan>[];
    final pattern = RegExp(RegExp.escape(_query), caseSensitive: false);
    int last = 0;
    for (final m in pattern.allMatches(body)) {
      if (m.start > last) {
        spans.add(TextSpan(text: body.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text: body.substring(m.start, m.end),
        style: const TextStyle(
          backgroundColor: Color(0xFFFFF2A8),
          fontWeight: FontWeight.w800,
          color: AppColors.brandDark,
        ),
      ));
      last = m.end;
    }
    if (last < body.length) {
      spans.add(TextSpan(text: body.substring(last)));
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: _scale.size,
          height: 1.7,
          color: AppColors.text,
        ),
        children: spans,
      ),
    );
  }

  String _fmtAgreedAt() {
    final d = _agreedAt;
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final matchCount = _query.isEmpty
        ? 0
        : RegExp(RegExp.escape(_query), caseSensitive: false)
            .allMatches(_body)
            .length;
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '문서 내 검색',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(_title),
        actions: [
          if (_searching) ...[
            if (_query.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('${matchCount}건',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _searching = false;
                _query = '';
                _searchCtrl.clear();
              }),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _searching = true),
            ),
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: '목차',
              onPressed: _showTocSheet,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _showShareSheet,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showMoreMenu,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메타 카드
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 18, color: AppColors.brandDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('현재 버전 v3.2 · 시행 2025.04.10',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandDark)),
                        const SizedBox(height: 2),
                        Text('마지막 검토일 ${_fmtAgreedAt()}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showVersionsSheet,
                    child: const Text('이력'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: _buildBody(),
            ),
            if (_isLegal) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _agreed
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          color: _agreed
                              ? AppColors.success
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(_agreed ? '동의 상태' : '동의 철회됨',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text(_agreed
                            ? '${_fmtAgreedAt()} 동의'
                            : '동의 필요',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_agreed)
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('동의 철회'),
                              content: const Text(
                                  '동의를 철회하면 일부 서비스 이용이 제한될 수 있어요. 진행할까요?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('취소'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.danger),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() => _agreed = false);
                                  },
                                  child: const Text('철회'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.do_disturb_outlined,
                            size: 16),
                        label: const Text('동의 철회'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _agreed = true;
                            _agreedAt = DateTime.now();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('동의 처리되었어요')),
                          );
                        },
                        child: const Text('동의하고 계속'),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _searching || !_isLegal
          ? null
          : null,
    );
  }
}
