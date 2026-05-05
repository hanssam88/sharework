import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';

enum _BizStage { submit, lookup, document, review, done }

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
  final _ownerCtrl = TextEditingController(text: '홍길동');
  final _bankCtrl = TextEditingController();

  bool _bizLookedUp = false;
  bool _certAttached = false;
  bool _bankDocAttached = false;
  String _bizType = '개인사업자';

  @override
  void dispose() {
    _bizCtrl.dispose();
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  _BizStage get _currentStage {
    if (Dummy.me.businessVerified) return _BizStage.done;
    if (_certAttached && _bankDocAttached) return _BizStage.review;
    if (_certAttached) return _BizStage.document;
    if (_bizLookedUp) return _BizStage.document;
    return _BizStage.submit;
  }

  void _verify() {
    final num = _bizCtrl.text.replaceAll('-', '');
    if (num.length != 10) {
      _snack('올바른 사업자번호 (10자리)를 입력해주세요');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.account_balance, color: AppColors.brandDark, size: 20),
            SizedBox(width: 8),
            Text('국세청 조회 결과'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('계속 사업자 (정상)',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            SizedBox(height: 12),
            _Kv(label: '상호', value: '카페 모카'),
            _Kv(label: '대표자', value: '홍 ○ ○'),
            _Kv(label: '업종', value: '비알콜 음료점업'),
            _Kv(label: '개업일자', value: '2021-05-12'),
            _Kv(label: '사업장 주소', value: '서울 강남구 역삼동 123-4'),
          ],
        ),
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
              setState(() => _bizLookedUp = true);
              _snack('사업자 정보가 자동 입력되었어요');
            },
            child: const Text('이 정보로 진행'),
          ),
        ],
      ),
    );
  }

  void _openUploadSheet({required void Function() onPicked}) {
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
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.brandDark),
              title: const Text('카메라로 촬영'),
              subtitle:
                  const Text('OCR로 자동 인식 시도', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(sheetCtx);
                onPicked();
                _snack('OCR 인식 완료 — 항목 자동 채워짐 (목업)');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.image_outlined, color: AppColors.brandDark),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(sheetCtx);
                onPicked();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.danger),
              title: const Text('PDF 파일 선택'),
              onTap: () {
                Navigator.pop(sheetCtx);
                onPicked();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_bizLookedUp) {
      _snack('국세청 조회를 먼저 진행해주세요');
      return;
    }
    if (!_certAttached) {
      _snack('사업자등록증 사본을 첨부해주세요');
      return;
    }
    if (!_bankDocAttached) {
      _snack('통장 사본도 첨부해주세요');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('사업자 인증 신청'),
        content: const Text('제출된 자료는 영업일 기준 1일 내에 검토됩니다. 검토 완료 후 알림으로 알려드릴게요.'),
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
              _snack('인증 신청 완료 (목업)');
              context.pop();
            },
            child: const Text('제출'),
          ),
        ],
      ),
    );
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
          // 진행 단계 표시
          _ProgressStepper(stage: _currentStage),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: verified ? AppColors.brandSoft : const Color(0xFFFFF6E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  verified ? Icons.verified : Icons.gpp_maybe_outlined,
                  size: 28,
                  color:
                      verified ? AppColors.brandDark : const Color(0xFFB45309),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verified ? '사업자 인증 완료' : '인증 시 받는 혜택',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        verified
                            ? '공고에 사업자 인증 배지가 표시돼요. 변경된 정보가 있으면 [재인증]을 눌러주세요.'
                            : '• 검색 노출 우선순위 +20%\n• 신뢰도 배지·수수료 0.5% 할인\n• 매출 정산 한도 상향',
                        style: const TextStyle(fontSize: 12, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const _Label('사업자 유형'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['개인사업자', '법인사업자', '면세사업자'].map((t) {
              final on = _bizType == t;
              return ChoiceChip(
                label: Text(t),
                selected: on,
                showCheckmark: false,
                selectedColor: AppColors.brandDark,
                labelStyle: TextStyle(
                  color: on ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => setState(() => _bizType = t),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
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
                width: 120,
                height: 50,
                child: FilledButton.tonalIcon(
                  onPressed: _verify,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: Icon(_bizLookedUp ? Icons.refresh : Icons.search,
                      size: 16),
                  label: Text(_bizLookedUp ? '재조회' : '국세청 조회'),
                ),
              ),
            ],
          ),
          if (_bizLookedUp) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle,
                      size: 14, color: AppColors.brandDark),
                  SizedBox(width: 4),
                  Text('계속 사업자 · 정상',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.brandDark,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],

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
          const SizedBox(height: 4),
          const Text('국세청에서 발급한 등록증을 첨부해주세요. OCR로 자동 인식해요.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          _UploadCard(
            attached: _certAttached,
            label: _certAttached ? '사업자등록증 첨부됨 (OCR 완료)' : '사진·PDF 업로드',
            onTap: () => _openUploadSheet(
                onPicked: () => setState(() => _certAttached = true)),
            onRemove: () => setState(() => _certAttached = false),
          ),

          const SizedBox(height: 24),
          const _Label('정산용 통장 사본'),
          const SizedBox(height: 4),
          const Text('사업자 명의의 계좌만 가능해요. 마스킹 처리되어 저장됩니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: _bankCtrl,
            decoration: const InputDecoration(
              hintText: '은행 + 계좌번호 (예: 카카오뱅크 3333-01-1234567)',
            ),
          ),
          const SizedBox(height: 8),
          _UploadCard(
            attached: _bankDocAttached,
            label: _bankDocAttached ? '통장 사본 첨부됨' : '통장 첫 페이지 사진/PDF',
            onTap: () => _openUploadSheet(
                onPicked: () => setState(() => _bankDocAttached = true)),
            onRemove: () => setState(() => _bankDocAttached = false),
            small: true,
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '제출된 사업자등록증·통장 사본은 인증 검토에만 사용되며, 검토 완료 후 즉시 폐기됩니다. 영업일 기준 1일 내 검토 완료.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted, height: 1.6),
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

class _ProgressStepper extends StatelessWidget {
  final _BizStage stage;
  const _ProgressStepper({required this.stage});

  static const _steps = [
    ('정보 입력', _BizStage.submit),
    ('국세청 조회', _BizStage.lookup),
    ('서류 첨부', _BizStage.document),
    ('검토', _BizStage.review),
    ('완료', _BizStage.done),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _steps.indexWhere((s) => s.$2 == stage);
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineIdx = i ~/ 2;
          final filled = lineIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? AppColors.brandDark : AppColors.divider,
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final step = _steps[stepIdx];
        final filled = stepIdx <= currentIdx;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: filled ? AppColors.brandDark : AppColors.chipBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('${stepIdx + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: filled ? Colors.white : AppColors.textMuted,
                  )),
            ),
            const SizedBox(height: 4),
            Text(step.$1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: filled ? AppColors.text : AppColors.textFaint,
                )),
          ],
        );
      }),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final bool attached;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool small;
  const _UploadCard({
    required this.attached,
    required this.label,
    required this.onTap,
    required this.onRemove,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = small ? 80.0 : 180.0;
    return GestureDetector(
      onTap: attached ? null : onTap,
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: attached ? AppColors.brandSoft : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: attached ? AppColors.brandDark : AppColors.divider,
            width: attached ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    attached ? Icons.check_circle : Icons.upload_file,
                    size: small ? 24 : 40,
                    color: attached ? AppColors.brandDark : AppColors.textMuted,
                  ),
                  if (!small) const SizedBox(height: 8),
                  Text(label,
                      style: TextStyle(
                        color: attached
                            ? AppColors.brandDark
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: small ? 12 : 14,
                      )),
                ],
              ),
            ),
            if (attached)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: onRemove,
                ),
              ),
          ],
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

class _Kv extends StatelessWidget {
  final String label;
  final String value;
  const _Kv({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted))),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
