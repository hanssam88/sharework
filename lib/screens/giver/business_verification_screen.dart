import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';

class BusinessVerificationScreen extends StatefulWidget {
  const BusinessVerificationScreen({super.key});

  @override
  State<BusinessVerificationScreen> createState() =>
      _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState
    extends State<BusinessVerificationScreen> {
  final _bizCtrl = TextEditingController(text: '123-45-67890');
  final _nameCtrl = TextEditingController(text: '카페 모카');
  final _ownerCtrl = TextEditingController();
  bool _certAttached = false;

  @override
  void dispose() {
    _bizCtrl.dispose();
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    final num = _bizCtrl.text.replaceAll('-', '');
    if (num.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 사업자번호 (10자리)를 입력해주세요')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('국세청 조회 결과'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('계속 사업자',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            SizedBox(height: 8),
            Text('상호: 카페 모카\n대표자: ○○○\n업종: 비알콜 음료점업'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_certAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사업자등록증 사본을 첨부해주세요')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('사업자 인증 신청 완료. 1 영업일 내 검토됩니다. (목업)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final me = Dummy.me;
    final verified = me.businessVerified;
    return Scaffold(
      appBar: AppBar(title: const Text('사업자 인증')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: verified
                  ? AppColors.brandSoft
                  : const Color(0xFFFFF6E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  verified ? Icons.verified : Icons.gpp_maybe_outlined,
                  size: 28,
                  color: verified
                      ? AppColors.brandDark
                      : const Color(0xFFB45309),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    verified
                        ? '사업자 인증 완료. 공고에 인증 배지가 표시돼요.'
                        : '사업자 인증을 완료하면 공고 노출 우선순위가 올라가고 신뢰도 배지가 부여됩니다.',
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _Label('사업자등록번호'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bizCtrl,
                  decoration: const InputDecoration(hintText: '000-00-00000'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _verify,
                  child: const Text('국세청 조회'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _Label('상호 (업체명)'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(hintText: '예: 카페 모카'),
          ),
          const SizedBox(height: 16),
          const _Label('대표자명'),
          const SizedBox(height: 8),
          TextField(
            controller: _ownerCtrl,
            decoration: const InputDecoration(hintText: '대표자 이름'),
          ),
          const SizedBox(height: 24),
          const _Label('사업자등록증 사본'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _certAttached = !_certAttached),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _certAttached
                      ? AppColors.brandDark
                      : AppColors.divider,
                  width: _certAttached ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _certAttached
                        ? Icons.check_circle
                        : Icons.upload_file,
                    size: 40,
                    color: _certAttached
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _certAttached
                        ? '사업자등록증 첨부됨 (목업)'
                        : '사진 또는 PDF 업로드',
                    style: TextStyle(
                      color: _certAttached
                          ? AppColors.brandDark
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 16, color: AppColors.textMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '제출된 사업자등록증은 인증 검토에만 사용되며, 검토 완료 후 즉시 폐기됩니다.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _submit,
            child: Text(verified ? '재인증 신청' : '인증 신청'),
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
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14));
  }
}
