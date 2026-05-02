import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  late String _headline;
  late String _summary;
  late List<CareerEntry> _careers;
  late List<EducationEntry> _educations;
  late List<String> _skills;

  bool _editMode = false;
  bool _dirty = false;

  static const _suggestedSkills = [
    '엑셀 중급', '워드 가능', 'PPT 가능', '한식조리사', '양식조리사',
    '운전면허 2종', '지게차 면허', '응급처치 자격', '사진 편집', '영상 편집',
    '중국어 회화', '일본어 회화', '바리스타 2급', '제과제빵 자격', '컴활 1급',
  ];

  @override
  void initState() {
    super.initState();
    _headline = Dummy.resume.headline;
    _summary = Dummy.resume.summary;
    _careers = List.of(Dummy.resume.careers);
    _educations = List.of(Dummy.resume.educations);
    _skills = List.of(Dummy.resume.skills);
  }

  void _markDirty() => setState(() => _dirty = true);

  Future<bool> _confirmExit() async {
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('편집 중인 내용이 있어요'),
        content: const Text('나가면 변경 사항이 임시저장됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 편집'),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('임시저장 되었어요 (목업)')),
              );
              Navigator.pop(context, true);
            },
            child: const Text('임시저장 후 나가기'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _editHeadlineSummary() {
    final hCtrl = TextEditingController(text: _headline);
    final sCtrl = TextEditingController(text: _summary);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('한 줄 소개·자기소개',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              const Text('한 줄 소개',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: hCtrl,
                maxLength: 40,
                decoration: const InputDecoration(
                  hintText: '예) 시간 엄수 · 카페 3년차',
                ),
              ),
              const SizedBox(height: 12),
              const Text('자기소개',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: sCtrl,
                maxLines: 6,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: '경험·강점·근무 가능 시간대 등을 적어주세요.',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _headline = hCtrl.text.trim();
                    _summary = sCtrl.text.trim();
                    _dirty = true;
                  });
                  Navigator.pop(sheetCtx);
                },
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editCareer({CareerEntry? existing, int? index}) {
    final companyCtrl = TextEditingController(text: existing?.company ?? '');
    final roleCtrl = TextEditingController(text: existing?.role ?? '');
    final periodCtrl = TextEditingController(text: existing?.period ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? '경력 추가' : '경력 수정',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _LabeledField(label: '회사·매장', controller: companyCtrl,
                  hint: '예) 카페 모카 강남점'),
              const SizedBox(height: 12),
              _LabeledField(label: '직무·포지션', controller: roleCtrl,
                  hint: '예) 바리스타 / 홀'),
              const SizedBox(height: 12),
              _LabeledField(label: '기간', controller: periodCtrl,
                  hint: '예) 2024.03 ~ 현재'),
              const SizedBox(height: 12),
              const Text('주요 경험',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: '담당 업무·성과를 자유롭게 적어주세요.',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (existing != null && index != null) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _careers.removeAt(index);
                          _dirty = true;
                        });
                        Navigator.pop(sheetCtx);
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger, size: 18),
                      label: const Text('삭제',
                          style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (companyCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('회사·매장을 입력해주세요')),
                          );
                          return;
                        }
                        final entry = CareerEntry(
                          company: companyCtrl.text.trim(),
                          role: roleCtrl.text.trim(),
                          period: periodCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                        );
                        setState(() {
                          if (existing != null && index != null) {
                            _careers[index] = entry;
                          } else {
                            _careers.add(entry);
                          }
                          _dirty = true;
                        });
                        Navigator.pop(sheetCtx);
                      },
                      child: const Text('저장'),
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

  void _editEducation({EducationEntry? existing, int? index}) {
    final schoolCtrl = TextEditingController(text: existing?.school ?? '');
    final degreeCtrl = TextEditingController(text: existing?.degree ?? '');
    final periodCtrl = TextEditingController(text: existing?.period ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? '학력 추가' : '학력 수정',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _LabeledField(label: '학교명', controller: schoolCtrl,
                  hint: '예) 한국대학교 경영학과'),
              const SizedBox(height: 12),
              _LabeledField(label: '학위·상태', controller: degreeCtrl,
                  hint: '예) 학사 / 재학 / 졸업'),
              const SizedBox(height: 12),
              _LabeledField(label: '기간', controller: periodCtrl,
                  hint: '예) 2021.03 ~ 현재'),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (existing != null && index != null) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _educations.removeAt(index);
                          _dirty = true;
                        });
                        Navigator.pop(sheetCtx);
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger, size: 18),
                      label: const Text('삭제',
                          style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (schoolCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('학교명을 입력해주세요')),
                          );
                          return;
                        }
                        final e = EducationEntry(
                          school: schoolCtrl.text.trim(),
                          degree: degreeCtrl.text.trim(),
                          period: periodCtrl.text.trim(),
                        );
                        setState(() {
                          if (existing != null && index != null) {
                            _educations[index] = e;
                          } else {
                            _educations.add(e);
                          }
                          _dirty = true;
                        });
                        Navigator.pop(sheetCtx);
                      },
                      child: const Text('저장'),
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

  void _addSkillSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (innerCtx, innerSet) {
            final available = _suggestedSkills
                .where((s) => !_skills.contains(s))
                .toList();
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('스킬 추가',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            hintText: '직접 입력 (예: 포토샵 중급)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final v = ctrl.text.trim();
                          if (v.isEmpty) return;
                          if (_skills.contains(v)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('이미 추가된 스킬이에요')),
                            );
                            return;
                          }
                          setState(() {
                            _skills.add(v);
                            _dirty = true;
                          });
                          ctrl.clear();
                          innerSet(() {});
                        },
                        child: const Text('추가'),
                      ),
                    ],
                  ),
                  if (available.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('추천 스킬 빠른 추가',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: available
                          .map((s) => ActionChip(
                                label: Text(s),
                                onPressed: () {
                                  setState(() {
                                    _skills.add(s);
                                    _dirty = true;
                                  });
                                  innerSet(() {});
                                },
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: const Text('완료'),
                    ),
                  ),
                ],
              ),
            );
          },
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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.preview_outlined,
                  color: AppColors.brandDark),
              title: const Text('지원자에게 보이는 미리보기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showPreview();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined,
                  color: AppColors.brandDark),
              title: const Text('가져오기'),
              subtitle: const Text('PDF · LinkedIn · 이전 이력서'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showImportSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined,
                  color: AppColors.brandDark),
              title: const Text('공유 링크 만들기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showShareSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined,
                  color: AppColors.brandDark),
              title: const Text('인쇄'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('인쇄 다이얼로그를 여는 중… (목업)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportSheet() {
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
            const SizedBox(height: 16),
            const Text('이력서 가져오기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.brandDark),
              title: const Text('PDF 파일 업로드'),
              subtitle: const Text('자동으로 분석해 항목을 채워드려요'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('파일 선택 (목업)')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.public, color: AppColors.brandDark),
              title: const Text('LinkedIn 연동'),
              subtitle: const Text('경력·학력 자동 가져오기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('LinkedIn 연결 (목업)')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.brandDark),
              title: const Text('이전 이력서 복원'),
              subtitle: const Text('최근 7일 이내 자동저장본'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('자동저장본을 불러왔어요 (목업)')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
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
              const Text('지원자 미리보기',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('구인자가 보게 될 화면이에요',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: _buildResumeBody(),
                ),
              ),
            ],
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('이력서 공유',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('링크 보유자만 열람할 수 있어요 (24시간 유효)',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
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
                      const SnackBar(
                          content:
                              Text('https://share.work/r/abc123 복사됨 (목업)')),
                    );
                  }),
                  _shareTile(Icons.qr_code, 'QR 코드',
                      AppColors.chipBg, AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR 보기 (목업)')),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security,
                        size: 16, color: AppColors.brandDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '연락처·주소·주민번호는 마스킹되어 공유돼요.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.brandDark),
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

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('내보내기',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _shareTile(Icons.picture_as_pdf, 'PDF',
                      AppColors.brandSoft, AppColors.brandDark, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('이력서_김알바.pdf 다운로드 (목업)')),
                    );
                  }),
                  _shareTile(Icons.image, '이미지',
                      AppColors.chipBg, AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이미지로 저장 (목업)')),
                    );
                  }),
                  _shareTile(Icons.link, '링크',
                      AppColors.chipBg, AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    _showShareSheet();
                  }),
                  _shareTile(Icons.print_outlined, '인쇄',
                      AppColors.chipBg, AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('인쇄 다이얼로그 (목업)')),
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

  List<Widget> _buildResumeBody() {
    final empty = _headline.isEmpty &&
        _summary.isEmpty &&
        _careers.isEmpty &&
        _educations.isEmpty &&
        _skills.isEmpty;
    if (empty) {
      return [
        const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text('아직 이력서가 비어있어요',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      ];
    }
    return [
      // 한줄 소개
      InkWell(
        onTap: _editMode ? _editHeadlineSummary : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(10),
            border: _editMode
                ? Border.all(color: AppColors.brandDark, width: 1.2)
                : null,
          ),
          child: Row(
            children: [
              const Icon(Icons.format_quote, color: AppColors.brandDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _headline.isEmpty ? '한 줄 소개를 입력해보세요' : _headline,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _headline.isEmpty
                        ? AppColors.textMuted
                        : AppColors.brandDark,
                  ),
                ),
              ),
              if (_editMode)
                const Icon(Icons.edit, size: 16, color: AppColors.brandDark),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      // 자기소개
      _SectionHeader(
        title: '자기소개',
        action: _editMode
            ? IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.brandDark,
                onPressed: _editHeadlineSummary,
              )
            : null,
      ),
      const SizedBox(height: 8),
      Text(_summary.isEmpty ? '간단한 자기소개를 작성해보세요.' : _summary,
          style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: _summary.isEmpty
                  ? AppColors.textMuted
                  : AppColors.text)),
      const SizedBox(height: 24),
      // 경력
      _SectionHeader(
        title: '경력 (${_careers.length})',
        action: _editMode
            ? TextButton.icon(
                onPressed: () => _editCareer(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('추가'),
              )
            : null,
      ),
      const SizedBox(height: 8),
      if (_careers.isEmpty && _editMode)
        _EmptyCard(
          message: '경력을 추가해보세요',
          onTap: () => _editCareer(),
        ),
      ...List.generate(_careers.length, (i) {
        final c = _careers[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: _editMode
                ? () => _editCareer(existing: c, index: i)
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.company,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                      ),
                      Text(c.period,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textFaint)),
                      if (_editMode) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.edit,
                            size: 14, color: AppColors.brandDark),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(c.role,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.brandDark,
                          fontWeight: FontWeight.w600)),
                  if (c.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.description,
                        style:
                            const TextStyle(fontSize: 13, height: 1.5)),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: 16),
      // 학력
      _SectionHeader(
        title: '학력 (${_educations.length})',
        action: _editMode
            ? TextButton.icon(
                onPressed: () => _editEducation(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('추가'),
              )
            : null,
      ),
      const SizedBox(height: 8),
      if (_educations.isEmpty && _editMode)
        _EmptyCard(
          message: '학력을 추가해보세요',
          onTap: () => _editEducation(),
        ),
      ...List.generate(_educations.length, (i) {
        final e = _educations[i];
        return InkWell(
          onTap: _editMode
              ? () => _editEducation(existing: e, index: i)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.school_outlined,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.school} · ${e.degree}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      Text(e.period,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (_editMode)
                  const Icon(Icons.edit,
                      size: 14, color: AppColors.brandDark),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 16),
      // 스킬
      _SectionHeader(
        title: '스킬 (${_skills.length})',
        action: _editMode
            ? TextButton.icon(
                onPressed: _addSkillSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('추가'),
              )
            : null,
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ..._skills.map((s) => Chip(
                label: Text(s,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                backgroundColor: AppColors.chipBg,
                deleteIcon: _editMode
                    ? const Icon(Icons.close, size: 14)
                    : null,
                onDeleted: _editMode
                    ? () => setState(() {
                          _skills.remove(s);
                          _dirty = true;
                        })
                    : null,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )),
        ],
      ),
      const SizedBox(height: 40),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmExit();
        if (ok && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('이력서'),
          actions: [
            if (_dirty)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('임시저장 되었어요 (목업)')),
                  );
                  setState(() => _dirty = false);
                },
                child: const Text('임시저장'),
              ),
            IconButton(
              tooltip: _editMode ? '편집 종료' : '편집',
              icon: Icon(_editMode ? Icons.check : Icons.edit_outlined),
              color: _editMode ? AppColors.brandDark : null,
              onPressed: () {
                setState(() {
                  _editMode = !_editMode;
                  if (!_editMode && _dirty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이력서가 저장되었어요 (목업)')),
                    );
                    _dirty = false;
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showMoreMenu,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: _buildResumeBody(),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showShareSheet,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('공유'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showExportSheet,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('내보내기'),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700)),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  const _EmptyCard({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.divider,
              style: BorderStyle.solid,
              width: 1),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_circle_outline,
                color: AppColors.brandDark),
            const SizedBox(height: 6),
            Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
