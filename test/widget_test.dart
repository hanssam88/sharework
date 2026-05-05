import 'package:flutter_test/flutter_test.dart';

import 'package:sharework_mockup/router/app_router.dart';
import 'package:sharework_mockup/main.dart';

void main() {
  testWidgets('Sharework app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ShareworkMockupApp());
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('건너뛰기'), findsOneWidget);
  });

  testWidgets('MVP demo routes render without framework errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ShareworkMockupApp());

    final routes = <String>[
      '/worker',
      '/giver',
      '/search',
      '/categories',
      '/job/1',
      '/job/1/review/write',
      '/job/1/checkin',
      '/job/1/contract',
      '/giver/job/create',
      '/giver/job/preview',
      '/giver/job/1/applicants',
      '/giver/job/1/edit',
      '/giver/job/1/stats',
      '/giver/job/1/boost',
      '/giver/payment-methods',
      '/giver/escrow',
      '/giver/business-verification',
      '/me/permissions',
      '/me/resume',
      '/me/portfolio',
      '/support',
      '/notice',
      '/terms',
    ];

    for (final route in routes) {
      AppRouter.config.go(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull, reason: 'route $route');
    }
  });
}
