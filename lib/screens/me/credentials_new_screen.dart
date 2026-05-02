import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

class CredentialsNewScreen extends StatefulWidget {
  const CredentialsNewScreen({super.key});

  @override
  State<CredentialsNewScreen> createState() => _CredentialsNewScreenState();
}

class _CredentialsNewScreenState extends State<CredentialsNewScreen> {
  CredentialKind _kind = CredentialKind.barista;
  final _memoCtrl = TextEditingController();
  DateTime? _issuedAt;
  DateTime? _expiresAt;
  bool _photoAttached = false;

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool issued) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        if (issued) {
          _issuedAt = picked;
        } else {
          _expiresAt = picked;
        }
      });
    }
  }

  void _submit() {
    if (_issuedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('발급일을 선택해주세요')),
      );
      return;
    }
    if (!_photoAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서류 사진을 첨부해주세요')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('서류가 등록되었습니다. 1~2 영업일 내 검토됩니다. (목업)')),
    );
    context.pop();
  }

  String _fmt(DateTime? d) =>
      d == null ? '선택 안 됨' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('서류 등록')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const _Label('서류 종류'),
          const SizedBox(height: 8),
          DropdownButtonFormField<CredentialKind>(
            value: _kind,
            isExpanded: true,
            items: CredentialKind.values
                .map((k) => DropdownMenuItem(
                      value: k,
                      child: Row(
                        children: [
                          Icon(k.icon, size: 18, color: AppColors.brandDark),
                          const SizedBox(width: 8),
                          Text(k.label),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _kind = v ?? _kind),
          ),
          const SizedBox(height: 20),
          const _Label('발급일'),
          const SizedBox(height: 8),
          _DateField(
            value: _fmt(_issuedAt),
            onTap: () => _pickDate(true),
          ),
          const SizedBox(height: 16),
          const _Label('만료일 (선택)'),
          const SizedBox(height: 8),
          _DateField(
            value: _fmt(_expiresAt),
            onTap: () => _pickDate(false),
          ),
          const SizedBox(height: 20),
          const _Label('서류 사진'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _photoAttached = !_photoAttached),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _photoAttached
                      ? AppColors.brandDark
                      : AppColors.divider,
                  width: _photoAttached ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _photoAttached
                        ? Icons.check_circle
                        : Icons.add_a_photo_outlined,
                    size: 40,
                    color: _photoAttached
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _photoAttached ? '서류 1장 첨부됨 (목업)' : '카메라 또는 앨범에서 선택',
                    style: TextStyle(
                      color: _photoAttached
                          ? AppColors.brandDark
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _Label('메모 (선택)'),
          const SizedBox(height: 8),
          TextField(
            controller: _memoCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '발급 기관·등급 등 추가 정보',
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: AppColors.textMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '제출된 서류는 검토 후 인증 배지가 부여됩니다. 만료 30일 전 알림으로 안내해드려요.',
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
            child: const Text('등록 신청'),
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

class _DateField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const _DateField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Text(value,
                style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
