import 'package:flutter/material.dart';

/// Job status constants. Matches the BFF schema (lowercase strings).
abstract class JobStatus {
  static const String active = 'active';
  static const String paused = 'paused';
  static const String closed = 'closed';
  static const Set<String> values = {active, paused, closed};
}

/// 공고 상태 토글 (active / paused / closed).
///
/// - 부모가 [current] 를 prop으로 전달, 상태는 부모가 관리 (StatelessWidget)
/// - active|paused ↔ active|paused: 즉시 onChange 호출 (no dialog)
/// - active|paused → closed: AlertDialog 확인 후 onChange('closed') 호출
/// - closed: onSelectionChanged null (disabled, immutable)
class JobStatusToggle extends StatelessWidget {
  final String current; // 'active' | 'paused' | 'closed'
  final void Function(String newStatus) onChange;

  const JobStatusToggle({
    super.key,
    required this.current,
    required this.onChange,
  }) : assert(
          current == JobStatus.active ||
              current == JobStatus.paused ||
              current == JobStatus.closed,
          'JobStatusToggle: invalid current value (must be active/paused/closed)',
        );

  @override
  Widget build(BuildContext context) {
    final isClosed = current == JobStatus.closed;

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: JobStatus.active, label: Text('모집중')),
        ButtonSegment(value: JobStatus.paused, label: Text('일시중지')),
        ButtonSegment(value: JobStatus.closed, label: Text('마감')),
      ],
      selected: {current},
      onSelectionChanged: isClosed
          ? null
          : (sel) async {
              final next = sel.first;
              if (next == current) return;
              if (next == JobStatus.closed) {
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
                if (!context.mounted) return;
                if (ok == true) onChange(JobStatus.closed);
              } else {
                onChange(next);
              }
            },
    );
  }
}
