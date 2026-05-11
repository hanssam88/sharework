import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sharework_mockup/data/repositories/auth_repository.dart';
import 'package:sharework_mockup/screens/auth/phone_auth_screen.dart';

class _MockAuth implements SupabaseAuthApi {
  String? lastPhone;
  String? lastToken;
  bool verifySucceeds;

  _MockAuth({this.verifySucceeds = true});

  @override
  Future<void> sendOtp(String phone) async {
    lastPhone = phone;
  }

  @override
  Future<bool> verifyOtp({required String phone, required String token}) async {
    lastToken = token;
    return verifySucceeds;
  }

  @override
  String? get accessToken => verifySucceeds ? 'fake-token' : null;

  @override
  Future<void> signOut() async {}
}

Widget _buildTestApp(PhoneAuthScreen screen) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => screen),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('sendOtp on phone submit', (tester) async {
    final mock = _MockAuth();
    final repo = AuthRepository(mock);

    await tester.pumpWidget(
      _buildTestApp(PhoneAuthScreen(authRepository: repo)),
    );

    await tester.enterText(find.byKey(const Key('phone-field')), '+821012345678');
    await tester.tap(find.byKey(const Key('send-otp-button')));
    await tester.pump();

    expect(mock.lastPhone, equals('+821012345678'));
  });

  testWidgets('verifyOtp on otp submit success', (tester) async {
    final mock = _MockAuth(verifySucceeds: true);
    final repo = AuthRepository(mock);
    bool authenticated = false;

    await tester.pumpWidget(
      _buildTestApp(
        PhoneAuthScreen(
          authRepository: repo,
          onAuthenticated: () => authenticated = true,
        ),
      ),
    );

    // Send OTP first
    await tester.enterText(find.byKey(const Key('phone-field')), '+821012345678');
    await tester.tap(find.byKey(const Key('send-otp-button')));
    await tester.pump();

    // Enter OTP and verify
    await tester.enterText(find.byKey(const Key('otp-field')), '123456');
    await tester.tap(find.byKey(const Key('verify-otp-button')));
    await tester.pump();

    expect(mock.lastToken, equals('123456'));
    expect(authenticated, isTrue);
  });

  testWidgets('verifyOtp failure shows error message', (tester) async {
    final mock = _MockAuth(verifySucceeds: false);
    final repo = AuthRepository(mock);

    await tester.pumpWidget(
      _buildTestApp(PhoneAuthScreen(authRepository: repo)),
    );

    // Send OTP first
    await tester.enterText(find.byKey(const Key('phone-field')), '+821012345678');
    await tester.tap(find.byKey(const Key('send-otp-button')));
    await tester.pump();

    // Enter OTP and verify
    await tester.enterText(find.byKey(const Key('otp-field')), '000000');
    await tester.tap(find.byKey(const Key('verify-otp-button')));
    await tester.pump();

    expect(find.textContaining('인증 실패'), findsOneWidget);
  });
}
