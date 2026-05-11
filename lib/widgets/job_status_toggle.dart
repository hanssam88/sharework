import 'package:flutter/material.dart';

/// 공고 상태 토글 (active / paused / closed).
///
/// - 부모가 [current] 를 prop으로 전달, 상태는 부모가 관리 (StatelessWidget)
/// - active ↔ paused 즉시 [onChange] 호출
/// - active|paused → closed 진입 시 confirm dialog ("마감 후 복구 불가") 표시,
///   확인 시에만 onChange('closed')
/// - current == 'closed' 면 SegmentedButton disable (onSelectionChanged: null)
class JobStatusToggle extends StatelessWidget {
  final String current; // 'active' | 'paused' | 'closed'
  final void Function(String newStatus) onChange;

  const JobStatusToggle({
    super.key,
    required this.current,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = current == 'closed';

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'active', label: Text('Active')),
        ButtonSegment(value: 'paused', label: Text('Paused')),
        ButtonSegment(value: 'closed', label: Text('Close')),
      ],
      selected: {current},
      onSelectionChanged: isClosed
          ? null
          : (sel) async {
              final next = sel.first;
              if (next == current) return;
              if (next == 'closed') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('공고 마감'),
                    content: const Text('마감 후 복구 불가'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('마감'),
                      ),
                    ],
                  ),
                );
                if (ok == true) onChange('closed');
              } else {
                onChange(next);
              }
            },
    );
  }
}
