import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sharework_mockup/router/app_router.dart';
import 'package:sharework_mockup/main.dart';

Future<void> _initEnv() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Stub shared_preferences channel used by supabase_flutter's local storage.
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (call.method == 'getAll') return <String, Object>{};
    if (call.method == 'setBool' ||
        call.method == 'setString' ||
        call.method == 'remove' ||
        call.method == 'clear') {
      return true;
    }
    return null;
  });

  dotenv.testLoad(
    fileInput:
        'SUPABASE_URL=https://test.supabase.co\nSUPABASE_ANON_KEY=test-anon\nAPI_BASE_URL=http://test\n',
  );

  try {
    Supabase.instance;
  } catch (_) {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon',
    );
  }
}

void main() {
  setUpAll(_initEnv);

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
