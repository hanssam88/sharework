import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sharework_mockup/data/repositories/me_repository.dart';
import 'package:sharework_mockup/models/api_models/profile.dart';
import 'package:sharework_mockup/screens/worker/mypage/mypage_screen.dart';

class _Stub implements HttpClientAdapter {
  String body;
  int status;
  _Stub(this.body, [this.status = 200]);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async =>
      ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: ['application/json']
      });

  @override
  void close({bool force = false}) {}
}

/// Fake repository: stubs getMe() so the FutureBuilder renders, and records
/// the role passed to setRole() (optionally throwing to exercise the error path).
class _FakeMeRepository extends MeRepository {
  _FakeMeRepository({this.throwOnSetRole = false}) : super(Dio());

  final bool throwOnSetRole;
  String? setRoleArg;

  static const _profile = Profile(
    id: 'u1',
    phone: '+821012345678',
    name: '홍길동',
    role: 'worker',
    publicId: 'PUB123',
    createdAt: '2026-05-11T00:00:00Z',
    updatedAt: '2026-05-11T00:00:00Z',
  );

  @override
  Future<Profile> getMe() async => _profile;

  @override
  Future<Profile> setRole(String role) async {
    setRoleArg = role;
    if (throwOnSetRole) throw Exception('boom');
    return _profile;
  }
}

/// Minimal router hosting MyPageScreen plus stub /worker and /giver
/// destinations so context.go() in _switchRole resolves.
Widget _harness(MyPageScreen screen) {
  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (_, __) => screen),
      GoRoute(
          path: '/worker',
          builder: (_, __) => const Scaffold(body: Text('WORKER'))),
      GoRoute(
          path: '/giver',
          builder: (_, __) => const Scaffold(body: Text('GIVER'))),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('renders profile name + phone + publicId', (tester) async {
    final dio = Dio()
      ..httpClientAdapter = _Stub(
        '{"data":{"id":"u1","phone":"+821012345678","name":"홍길동","role":"worker","public_id":"PUB123","created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}}',
      );
    final repo = MeRepository(dio);
    await tester.pumpWidget(
        MaterialApp(home: MyPageScreen(appType: 'worker', meRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('홍길동'), findsOneWidget);
    expect(find.text('+821012345678'), findsOneWidget);
    expect(find.textContaining('PUB123'), findsOneWidget);
  });

  testWidgets('shows error on failure', (tester) async {
    final dio = Dio()
      ..httpClientAdapter =
          _Stub('{"error":{"code":"INTERNAL","message":"x"}}', 500);
    final repo = MeRepository(dio);
    await tester.pumpWidget(
        MaterialApp(home: MyPageScreen(appType: 'worker', meRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('연결이 불안정'), findsOneWidget);
  });

  testWidgets('worker: tapping 구인자로 전환 calls setRole(giver) and navigates to /giver',
      (tester) async {
    final fake = _FakeMeRepository();
    await tester.pumpWidget(
        _harness(MyPageScreen(appType: 'worker', meRepository: fake)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('구인자로 전환'));
    await tester.pumpAndSettle();

    expect(fake.setRoleArg, 'giver');
    expect(find.text('GIVER'), findsOneWidget);
  });

  testWidgets('giver: tapping 구직자로 전환 calls setRole(worker) and navigates to /worker',
      (tester) async {
    final fake = _FakeMeRepository();
    await tester.pumpWidget(
        _harness(MyPageScreen(appType: 'giver', meRepository: fake)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('구직자로 전환'));
    await tester.pumpAndSettle();

    expect(fake.setRoleArg, 'worker');
    expect(find.text('WORKER'), findsOneWidget);
  });

  testWidgets('switch role failure shows SnackBar and does not navigate',
      (tester) async {
    final fake = _FakeMeRepository(throwOnSetRole: true);
    await tester.pumpWidget(
        _harness(MyPageScreen(appType: 'worker', meRepository: fake)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('구인자로 전환'));
    await tester.pump(); // build the SnackBar

    expect(fake.setRoleArg, 'giver');
    expect(find.text('전환에 실패했어요. 잠시 후 다시 시도해주세요'), findsOneWidget);
    expect(find.text('GIVER'), findsNothing);

    // Drain the SnackBar's auto-dismiss timer to avoid a pending-timer error.
    await tester.pump(const Duration(seconds: 4));
  });
}
