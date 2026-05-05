import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
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
  bool _anonymous = false;
  bool _willRehire = true;
  bool _draftSaved = false;

  // 4개 세부 평가 (1~5)
  double _kindness = 5;
  double _communication = 5;
  double _punctuality = 5;
  double _environment = 5;

  static const _bannedKeywords = ['욕설', '광고', '도배', '바보'];

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Review? _previousReview() {
    final job = Dummy.jobById(widget.jobId);
    return Dummy.reviews.firstWhere(
      (r) => r.fromUserId == job.giverId,
      orElse: () => Dummy.reviews.first,
    );
  }

  void _autoCompose() {
    final tags = _selectedTags.isNotEmpty
        ? _selectedTags.take(2).join(', ')
        : '시간엄수, 친절';
    final ratingPart = _rating >= 5
        ? '정말 만족스러운 근무였어요'
        : _rating >= 4
            ? '대체로 좋은 경험이었어요'
            : _rating >= 3
                ? '무난했어요'
                : '아쉬운 점이 있었어요';
    final draft =
        '$ratingPart. 특히 $tags 부분이 인상 깊었습니다.${_willRehire ? " 다음에도 함께 일하고 싶어요!" : ""}';
    setState(() => _contentCtrl.text = draft);
    _snack('AI가 후기 초안을 작성했어요. 자유롭게 수정하세요.');
  }

  String? _bannedWordWarning() {
    for (final w in _bannedKeywords) {
      if (_contentCtrl.text.contains(w)) {
        return '"$w" 단어가 포함되어 있어요. 정중한 표현으로 바꿔주세요.';
      }
    }
    return null;
  }

  Future<void> _submitFull() async {
    final warning = _bannedWordWarning();
    if (warning != null) {
      _snack(warning);
      return;
    }
    if (_rating == 0) {
      _snack('별점을 선택해주세요');
      return;
    }
    _snack('리뷰가 등록되었습니다 (목업)');
    context.pop();
  }

  void _submitRatingOnly() {
    if (_rating == 0) {
      _snack('별점을 선택해주세요');
      return;
    }
    _snack('별점만 등록되었습니다. 후기는 나중에 추가할 수 있어요.');
    context.pop();
  }

  Future<bool> _onWillPop() async {
    if (_contentCtrl.text.isEmpty &&
        _selectedTags.isEmpty &&
        _photoPlaceholders.isEmpty) {
      return true;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('작성 중인 리뷰가 있어요'),
        content: const Text('임시저장하면 마이페이지에서 다시 이어 쓸 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('나가기', style: TextStyle(color: AppColors.danger)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('계속 쓰기'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('임시저장'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      _snack('임시저장되었어요 (목업)');
      return true;
    }
    return result == 'discard';
  }

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    final prev = _previousReview();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onWillPop()) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('리뷰 작성'),
          actions: [
            TextButton.icon(
              onPressed: () {
                setState(() => _draftSaved = true);
                _snack('임시저장되었어요 (목업)');
              },
              icon: Icon(
                _draftSaved ? Icons.cloud_done : Icons.cloud_upload_outlined,
                size: 16,
              ),
              label: Text(_draftSaved ? '저장됨' : '임시저장'),
            ),
          ],
        ),
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
                  if (_anonymous)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('익명',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted)),
                    ),
                ],
              ),
            ),

            // 이전 리뷰 참조
            if (prev != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('지난 ${prev.jobTitle} 리뷰 (${prev.rating}점)',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('"${prev.content}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, height: 1.5)),
                    const SizedBox(height: 4),
                    const Text('이번엔 어떻게 달랐나요?',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],

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
                    color:
                        filled ? const Color(0xFFFFC400) : AppColors.textFaint,
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

            // 4개 세부 슬라이더
            const Text(
              '세부 평가',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            _slider('친절도', _kindness, (v) => setState(() => _kindness = v)),
            _slider('소통', _communication,
                (v) => setState(() => _communication = v)),
            _slider(
                '시간엄수', _punctuality, (v) => setState(() => _punctuality = v)),
            _slider(
                '근무환경', _environment, (v) => setState(() => _environment = v)),

            const SizedBox(height: 16),
            const Text(
              '인상 깊었던 점을 골라주세요',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
            Row(
              children: [
                const Text(
                  '한 줄 후기 (선택)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _autoCompose,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('AI 자동 작성'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentCtrl,
              maxLines: 5,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: '솔직한 후기는 다른 분들에게도 큰 도움이 됩니다.',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_bannedWordWarning() != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        size: 14, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _bannedWordWarning()!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            const Text(
              '사진 첨부 (선택)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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

            const SizedBox(height: 24),

            // 공개·재고용 토글
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _anonymous,
                    activeColor: AppColors.brandDark,
                    title: const Text('익명으로 등록',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('닉네임 대신 "익명"으로 표시돼요',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    onChanged: (v) => setState(() => _anonymous = v),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _willRehire,
                    activeColor: AppColors.brandDark,
                    title: const Text('이 매장에서 또 일하고 싶어요',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('재고용 의향은 매장 추천 점수에만 사용돼요',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    onChanged: (v) => setState(() => _willRehire = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitRatingOnly,
                    child: const Text('별점만 등록'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _submitFull,
                    child: const Text('리뷰 등록'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: AppColors.brandDark,
                inactiveColor: AppColors.chipBg,
                label: '${value.toInt()}점',
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text('${value.toInt()}',
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDark)),
          ),
        ],
      ),
    );
  }
}
