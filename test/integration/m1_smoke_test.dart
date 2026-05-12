// test/integration/m1_smoke_test.dart
//
// M1 smoke flow: PhoneAuth → JWT 획득 → WorkerHome jobs 표시 → JobInfo (사진 캐러셀) → MyPage (publicId)
// Mock-based widget test — runs via `flutter test`, no simulator required.
// For real BFF/Supabase smoke, user runs `flutter run` in simulator after .env setup.

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/auth_repository.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/data/repositories/me_repository.dart';
import 'package:sharework_mockup/screens/auth/phone_auth_screen.dart';
import 'package:sharework_mockup/screens/common/job_info_screen.dart';
import 'package:sharework_mockup/screens/worker/home/worker_home_screen.dart';
import 'package:sharework_mockup/screens/worker/mypage/mypage_screen.dart';

// ---------------------------------------------------------------------------
// Auth mock — SupabaseAuthApi stub returning jwt-test on verifyOtp
// ---------------------------------------------------------------------------

class _MockAuth implements SupabaseAuthApi {
  String? _token = 'jwt-test';

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<bool> verifyOtp({required String phone, required String token}) async {
    return _token != null;
  }

  @override
  String? get accessToken => _token;

  @override
  Future<void> signOut() async {
    _token = null;
  }
}

// ---------------------------------------------------------------------------
// Route-based Dio adapter — maps path to JSON body for multi-endpoint support
// ---------------------------------------------------------------------------

class _RouteMockAdapter implements HttpClientAdapter {
  final Map<String, String> routes;
  _RouteMockAdapter(this.routes);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestBodyStream,
    Future<void>? cancelFuture,
  ) async {
    // Match by path prefix (handles /api/jobs/j1 before /api/jobs)
    final path = options.path;
    final body = routes[path] ??
        routes.entries
            .firstWhere(
              (e) => path.startsWith(e.key),
              orElse: () => const MapEntry('', '{"data":[]}'),
            )
            .value;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// ---------------------------------------------------------------------------
// Fixtures — M2 schema with giver{public_id, name} + photos[{id,position,signed_url}]
// + public_id on Profile
// ---------------------------------------------------------------------------

const _jobJson =
    '{"id":"j1","title":"카페 알바","description":"디테일","wage_won":12000,'
    '"schedule_text":null,"status":"active","category_id":"c1",'
    '"location_address":"서울시",'
    '"giver":{"public_id":"GVR1","name":"홍길동"},'
    '"photos":[{"id":"p1","position":1,"signed_url":"https://example/sig"}],'
    '"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}';

const _profileJson =
    '{"id":"u1","phone":"+821012345678","name":"홍길동","role":"worker",'
    '"public_id":"PUB123",'
    '"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}';

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  testWidgets(
    'M1 smoke: PhoneAuth → token → WorkerHome → JobInfo (carousel) → MyPage (publicId)',
    (tester) async {
      final auth = AuthRepository(_MockAuth());

      final dio = Dio()
        ..httpClientAdapter = _RouteMockAdapter({
          '/api/jobs/j1': '{"data":$_jobJson}',
          '/api/jobs':
              '{"data":[$_jobJson],"page":{"total":1,"page":1,"limit":20}}',
          '/api/me': '{"data":$_profileJson}',
        });
      final jobRepo = JobRepository(dio);
      final meRepo = MeRepository(dio);

      // ------------------------------------------------------------------
      // Stage 1: PhoneAuth — verify JWT obtained via onAuthenticated
      // ------------------------------------------------------------------
      bool authenticated = false;
      await tester.pumpWidget(MaterialApp(
        home: PhoneAuthScreen(
          authRepository: auth,
          onAuthenticated: () => authenticated = true,
        ),
      ));

      await tester.enterText(
          find.byKey(const Key('phone-field')), '+821012345678');
      await tester.tap(find.byKey(const Key('send-otp-button')));
      await tester.pump();

      // OTP field appears after sendOtp
      await tester.enterText(find.byKey(const Key('otp-field')), '123456');
      await tester.tap(find.byKey(const Key('verify-otp-button')));
      await tester.pumpAndSettle();

      expect(
        authenticated,
        isTrue,
        reason: 'onAuthenticated must fire after successful verifyOtp',
      );
      expect(
        auth.accessToken,
        'jwt-test',
        reason: 'accessToken must be jwt-test after mock verifyOtp',
      );

      // ------------------------------------------------------------------
      // Stage 2: WorkerHome — jobs list with giver name visible
      // ------------------------------------------------------------------
      await tester.pumpWidget(
          MaterialApp(home: WorkerHomeScreen(jobRepository: jobRepo)));
      await tester.pumpAndSettle();

      expect(
        find.text('카페 알바'),
        findsOneWidget,
        reason: 'WorkerHome must show job title from BFF',
      );
      expect(
        find.textContaining('홍길동'),
        findsOneWidget,
        reason: 'WorkerHome subtitle must show giver.name',
      );

      // ------------------------------------------------------------------
      // Stage 3: JobInfo — detail with photo carousel (PageView when photos > 0)
      // ------------------------------------------------------------------
      await tester.pumpWidget(MaterialApp(
          home: JobInfoScreen(jobId: 'j1', jobRepository: jobRepo)));
      await tester.pumpAndSettle();

      expect(find.text('카페 알바'), findsOneWidget);
      expect(find.text('디테일'), findsOneWidget);
      expect(
        find.byType(PageView),
        findsOneWidget,
        reason:
            'JobInfo must show PageView photo carousel when photos non-empty',
      );

      // ------------------------------------------------------------------
      // Stage 4: MyPage — profile with publicId visible
      // ------------------------------------------------------------------
      await tester.pumpWidget(MaterialApp(
          home: MyPageScreen(appType: 'worker', meRepository: meRepo)));
      await tester.pumpAndSettle();

      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('+821012345678'), findsOneWidget);
      expect(
        find.textContaining('PUB123'),
        findsOneWidget,
        reason: 'MyPage must show publicId per M2 P4.1',
      );
    },
  );
}
