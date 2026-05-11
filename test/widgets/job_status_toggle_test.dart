import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sharework_mockup/widgets/job_status_toggle.dart';

void main() {
  group('JobStatusToggle', () {
    testWidgets('active → paused: immediate callback (no dialog)',
        (tester) async {
      String? newStatus;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: JobStatus.active,
            onChange: (s) => newStatus = s,
          ),
        ),
      ));

      // SegmentedButton 라벨이 한글로 변경됨 (Active/Paused/Close → 모집중/일시중지/마감).
      // 다이얼로그의 '마감' title/button과 토글 라벨이 같으므로
      // 토글 라벨은 widgetWithText(ButtonSegment-scoped)로 disambiguate.
      await tester.tap(find.text('일시중지'));
      await tester.pumpAndSettle();

      expect(newStatus, JobStatus.paused);
    });

    testWidgets('paused → active: immediate callback', (tester) async {
      String? newStatus;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: JobStatus.paused,
            onChange: (s) => newStatus = s,
          ),
        ),
      ));

      await tester.tap(find.text('모집중'));
      await tester.pumpAndSettle();

      expect(newStatus, JobStatus.active);
    });

    testWidgets('active → closed: shows confirm dialog, only fires on OK',
        (tester) async {
      String? newStatus;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: JobStatus.active,
            onChange: (s) => newStatus = s,
          ),
        ),
      ));

      // 토글 '마감' 탭 (다이얼로그는 아직 안 떴으므로 find.text 단일).
      await tester.tap(find.text('마감'));
      await tester.pumpAndSettle();

      // dialog visible (use content text, unique to dialog)
      expect(find.text('마감 후 복구 불가'), findsOneWidget);
      // not yet fired
      expect(newStatus, isNull);

      // tap confirm button ('마감' label in dialog) — TextButton-scoped
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, '마감'),
      ));
      await tester.pumpAndSettle();

      expect(newStatus, JobStatus.closed);
    });

    testWidgets('paused → closed: shows confirm dialog, fires on 마감',
        (tester) async {
      String? newStatus;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: JobStatus.paused,
            onChange: (s) => newStatus = s,
          ),
        ),
      ));

      await tester.tap(find.text('마감'));
      await tester.pumpAndSettle();

      expect(find.text('마감 후 복구 불가'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, '마감'),
      ));
      await tester.pumpAndSettle();

      expect(newStatus, JobStatus.closed);
    });

    testWidgets('cancel dialog: no callback', (tester) async {
      String? newStatus;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: JobStatus.active,
            onChange: (s) => newStatus = s,
          ),
        ),
      ));

      await tester.tap(find.text('마감'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(newStatus, isNull);
    });

    testWidgets('tapping same value: no callback (no-op guard)',
        (tester) async {
      String? newStatus;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: JobStatus.active,
            onChange: (s) => newStatus = s,
          ),
        ),
      ));

      await tester.tap(find.text('모집중'));
      await tester.pumpAndSettle();

      expect(newStatus, isNull);
    });

    testWidgets('closed: disables all toggles', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: JobStatus.closed,
            onChange: (_) {},
          ),
        ),
      ));

      final segmented = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );
      expect(segmented.onSelectionChanged, isNull);
    });
  });
}
