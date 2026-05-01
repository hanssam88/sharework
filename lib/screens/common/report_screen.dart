import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  final String targetType; // user, job, review, chat
  final int targetId;
  const ReportScreen({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _reason;
  final _detailCtrl = TextEditingController();
  final List<int> _photos = [];

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  String get _targetLabel {
    switch (widget.targetType) {
      case 'user':
        return '사용자';
      case 'job':
        return '공고';
      case 'review':
        return '리뷰';
      case 'chat':
        return '채팅 메시지';
      default:
        return '대상';
    }
  }

  List<String> get _reasons {
    switch (widget.targetType) {
      case 'job':
        return const [
          '허위/과장 공고',
          '시급·근무조건 사기',
          '플랫폼 외 거래 유도',
          '불법·위험한 업무',
          '차별·혐오 표현',
          '기타',
        ];
      case 'chat':
        return const [
          '욕설/모욕',
          '성희롱·부적절한 발언',
          '플랫폼 외 거래 요구',
          '광고/스팸',
          '협박·괴롭힘',
          '기타',
        ];
      default:
        return const [
          '욕설/모욕',
          '성희롱',
          '잠수·노쇼',
          '계약과 다른 업무 요구',
          '플랫폼 외 거래 유도',
          '사기·갈취 시도',
          '기타',
        ];
    }
  }

  void _submit() {
    if (_reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고 사유를 선택해주세요')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('신고가 접수되었습니다. 24시간 내 검토 후 알림을 드릴게요. (목업)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_targetLabel 신고')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined,
                    color: AppColors.brandDark, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '신고 내용은 신고센터에서 검토하며, 신고자의 정보는 비공개로 유지됩니다.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('신고 사유',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ..._reasons.map((r) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(r),
                value: r,
                groupValue: _reason,
                activeColor: AppColors.brandDark,
                onChanged: (v) => setState(() => _reason = v),
              )),
          const SizedBox(height: 16),
          const Text('상세 내용 (선택)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            controller: _detailCtrl,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: '신고 사유를 더 자세히 적어주시면 검토에 도움이 됩니다.',
            ),
          ),
          const SizedBox(height: 8),
          const Text('증거 첨부 (선택, 최대 3장)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_photos.length < 3) {
                    setState(() => _photos.add(_photos.length + 1));
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
                      const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.textMuted),
                      const SizedBox(height: 4),
                      Text('${_photos.length}/3',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ..._photos.map((i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('#$i',
                          style: const TextStyle(
                              color: AppColors.brandDark,
                              fontWeight: FontWeight.w700)),
                    ),
                  )),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: _submit,
            child: const Text('신고하기'),
          ),
        ),
      ),
    );
  }
}
