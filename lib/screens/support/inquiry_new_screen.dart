import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class InquiryNewScreen extends StatefulWidget {
  const InquiryNewScreen({super.key});

  @override
  State<InquiryNewScreen> createState() => _InquiryNewScreenState();
}

class _InquiryNewScreenState extends State<InquiryNewScreen> {
  String _category = '계정';
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final List<int> _photos = [];

  static const _categories = ['계정', '지원·채용', '정산', '신고·안전', '버그/오류', '기타'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('문의가 접수되었습니다 (목업)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1:1 문의 작성')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text('카테고리',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((c) {
              final on = c == _category;
              return ChoiceChip(
                label: Text(c),
                selected: on,
                onSelected: (_) => setState(() => _category = c),
                selectedColor: AppColors.brandSoft,
                labelStyle: TextStyle(
                  color: on ? AppColors.brandDark : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('제목',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: '문의 제목'),
          ),
          const SizedBox(height: 16),
          const Text('내용',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyCtrl,
            maxLines: 8,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: '상황을 자세히 적어주실수록 빠른 답변이 가능합니다.',
            ),
          ),
          const SizedBox(height: 8),
          const Text('첨부 (선택, 최대 3장)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
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
            onPressed: _submit,
            child: const Text('문의 등록'),
          ),
        ),
      ),
    );
  }
}
