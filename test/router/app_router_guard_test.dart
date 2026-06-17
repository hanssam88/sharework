import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sharework_mockup/router/app_router.dart';
import 'package:sharework_mockup/screens/auth/phone_auth_screen.dart';

/// Initialize Supabase (no logged-in session) so the redirect guard runs the
/// real `session == null` branch instead of the uninitialized bypass.
Future<void> _initSupabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();

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

/// Pumps the real router and drains the splash screen's 1200ms delayed timer
/// (initialLocation is /splash), leaving the tree settled on /onboarding.
Future<void> _pumpRouter(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: AppRouter.config),
  );
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_initSupabase);

  testWidgets('protected routes redirect to /auth/phone when no session',
      (tester) async {
    await _pumpRouter(tester);

    for (final route in <String>['/worker', '/giver', '/me/edit']) {
      AppRouter.config.go(route);
      await tester.pumpAndSettle();

      expect(find.byType(PhoneAuthScreen), findsOneWidget,
          reason: 'route $route should redirect to /auth/phone');
    }
  });

  testWidgets('/auth/phone stays put (no redirect loop)', (tester) async {
    await _pumpRouter(tester);

    AppRouter.config.go('/auth/phone');
    await tester.pumpAndSettle();

    expect(find.byType(PhoneAuthScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
