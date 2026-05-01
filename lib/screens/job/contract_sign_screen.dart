import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class ContractSignScreen extends StatefulWidget {
  final int jobId;
  const ContractSignScreen({super.key, required this.jobId});

  @override
  State<ContractSignScreen> createState() => _ContractSignScreenState();
}

class _ContractSignScreenState extends State<ContractSignScreen> {
  bool _agreeAll = false;
  bool _agreeMain = false;
  bool _agreePrivacy = false;
  final List<Offset?> _strokes = [];

  bool get _hasSigned => _strokes.isNotEmpty;
  bool get _canSubmit => _agreeMain && _agreePrivacy && _hasSigned;

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('계약서 서명이 완료되었습니다 (목업)')),
    );
    context.go('/job/${widget.jobId}/contract');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전자서명'),
        actions: [
          if (_hasSigned)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '다시 서명',
              onPressed: () => setState(() => _strokes.clear()),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agreeAll,
            onChanged: (v) => setState(() {
              _agreeAll = v ?? false;
              _agreeMain = _agreeAll;
              _agreePrivacy = _agreeAll;
            }),
            title: const Text('전체 동의',
                style: TextStyle(fontWeight: FontWeight.w800)),
            activeColor: AppColors.brandDark,
          ),
          const Divider(),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agreeMain,
            onChanged: (v) => setState(() {
              _agreeMain = v ?? false;
              _agreeAll = _agreeMain && _agreePrivacy;
            }),
            title: const Text('근로계약서 내용에 동의합니다 (필수)'),
            activeColor: AppColors.brandDark,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agreePrivacy,
            onChanged: (v) => setState(() {
              _agreePrivacy = v ?? false;
              _agreeAll = _agreeMain && _agreePrivacy;
            }),
            title: const Text('개인정보 제공 및 위탁 처리에 동의합니다 (필수)'),
            activeColor: AppColors.brandDark,
          ),
          const SizedBox(height: 20),
          const Text('서명',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            '아래 영역에 손가락(또는 마우스)으로 서명해주세요.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Stack(
              children: [
                if (!_hasSigned)
                  const Center(
                    child: Text(
                      '여기에 서명',
                      style: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                GestureDetector(
                  onPanStart: (d) => setState(() => _strokes.add(d.localPosition)),
                  onPanUpdate: (d) =>
                      setState(() => _strokes.add(d.localPosition)),
                  onPanEnd: (_) => setState(() => _strokes.add(null)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomPaint(
                      painter: _SignaturePainter(_strokes),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              TextButton.icon(
                onPressed: _hasSigned
                    ? () => setState(() => _strokes.clear())
                    : null,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('지우기'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: const Text('서명 제출'),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.text
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) =>
      oldDelegate.points.length != points.length;
}
