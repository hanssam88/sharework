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
            current: 'active',
            onChange: (s) => newStatus = s,
          ),
        ),
      ));

      await tester.tap(find.text('Paused'));
      await tester.pumpAndSettle();

      expect(newStatus, 'paused');
    });

    testWidgets('paused → active: immediate callback', (tester) async {
      String? newStatus;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: 'paused',
            onChange: (s) => newStatus = s,
          ),
        ),
      ));

      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      expect(newStatus, 'active');
    });

    testWidgets('active → closed: shows confirm dialog, only fires on OK',
        (tester) async {
      String? newStatus;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: 'active',
            onChange: (s) => newStatus = s,
          ),
        ),
      ));

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // dialog visible (use content text, unique to dialog)
      expect(find.text('마감 후 복구 불가'), findsOneWidget);
      // not yet fired
      expect(newStatus, isNull);

      // tap confirm button ('마감' label in dialog)
      await tester.tap(find.text('마감'));
      await tester.pumpAndSettle();

      expect(newStatus, 'closed');
    });

    testWidgets('cancel dialog: no callback', (tester) async {
      String? newStatus;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: 'active',
            onChange: (s) => newStatus = s,
          ),
        ),
      ));

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(newStatus, isNull);
    });

    testWidgets('closed: disables all toggles', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JobStatusToggle(
            current: 'closed',
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
