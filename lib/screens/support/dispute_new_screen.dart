import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class DisputeNewScreen extends StatefulWidget {
  const DisputeNewScreen({super.key});

  @override
  State<DisputeNewScreen> createState() => _DisputeNewScreenState();
}

class _DisputeNewScreenState extends State<DisputeNewScreen> {
  Job? _job;
  DisputeReason? _reason;
  final _descCtrl = TextEditingController();
  final List<String> _attachments = [];
  bool _agreed = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _pickJob() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('대상 공고 선택',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: Dummy.jobs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final j = Dummy.jobs[i];
                    return ListTile(
                      title: Text(j.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(j.giverName,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                      onTap: () {
                        setState(() => _job = j);
                        Navigator.pop(sheetCtx);
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

  bool get _canSubmit =>
      _job != null &&
      _reason != null &&
      _descCtrl.text.trim().length >= 10 &&
      _agreed;

  void _submit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('분쟁 조정 신청'),
        content: const Text(
            '제출하신 내용은 양측에 공유되며, 영업일 기준 1~2일 내에 담당자가 검토합니다. 제출하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('분쟁 조정 신청이 접수되었습니다 (목업)')),
              );
              context.go('/support/dispute');
            },
            child: const Text('제출'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('분쟁 조정 신청')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.gavel_outlined, color: AppColors.brandDark),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '단순 신고와 달리, 분쟁 조정은 양측 사이에서 보상·정산 조정을 중재해요. 거짓 신청은 제재 사유가 될 수 있어요.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _Label('대상 공고'),
          InkWell(
            onTap: _pickJob,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _job?.title ?? '공고 선택',
                      style: TextStyle(
                        color:
                            _job == null ? AppColors.textFaint : AppColors.text,
                      ),
                    ),
                  ),
                  const Icon(Icons.expand_more, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _Label('분쟁 사유'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DisputeReason.values.map((r) {
              final on = _reason == r;
              return ChoiceChip(
                label: Text(r.label),
                selected: on,
                showCheckmark: false,
                selectedColor: AppColors.brandDark,
                labelStyle: TextStyle(
                  color: on ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => setState(() => _reason = r),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const _Label('상세 내용 (10자 이상)'),
          TextField(
            controller: _descCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '발생 일시·장소·정황·합의 시도 여부 등을 자세히 적어주세요.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          const _Label('증빙 자료 (사진·녹취·문자)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._attachments.map((a) => Chip(
                    label: Text(a),
                    onDeleted: () => setState(() => _attachments.remove(a)),
                  )),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('파일 첨부'),
                onPressed: () => setState(
                    () => _attachments.add('파일${_attachments.length + 1}.jpg')),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            value: _agreed,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.brandDark,
            title:
                const Text('제출 내용이 사실임에 동의합니다', style: TextStyle(fontSize: 13)),
            subtitle: const Text(
              '거짓 신청 시 계정 제재·법적 책임이 따를 수 있어요',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            onChanged: (v) => setState(() => _agreed = v ?? false),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: const Text('제출하기'),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      );
}
