import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sharework_mockup/screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> _initSupabase() async {
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

  // Only initialize if not already done.
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
  setUpAll(_initSupabase);

  testWidgets('SplashScreen renders branding (Sharework, handshake icon)',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(
            path: '/onboarding',
            builder: (_, __) => const Scaffold(body: Text('onboarding'))),
        GoRoute(
            path: '/worker',
            builder: (_, __) => const Scaffold(body: Text('worker'))),
        GoRoute(
            path: '/auth/phone',
            builder: (_, __) => const Scaffold(body: Text('auth'))),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(); // first frame — branding is visible before timer fires
    expect(find.text('Sharework'), findsOneWidget);
    expect(find.byIcon(Icons.handshake_outlined), findsOneWidget);
    // Drain the pending 1.2 s timer so the test ends cleanly.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen redirects to /onboarding when no session',
      (tester) async {
    // currentSession is null — no signIn performed in setUpAll
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(
            path: '/onboarding',
            builder: (_, __) => const Scaffold(body: Text('onboarding-page'))),
        GoRoute(
            path: '/worker',
            builder: (_, __) => const Scaffold(body: Text('worker-page'))),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    // Wait past the 1.2 s splash delay
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('onboarding-page'), findsOneWidget);
  });
}
