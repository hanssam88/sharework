import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/me_repository.dart';
import 'package:sharework_mockup/screens/worker/mypage/mypage_screen.dart';

class _Stub implements HttpClientAdapter {
  String body;
  int status;
  _Stub(this.body, [this.status = 200]);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async =>
      ResponseBody.fromString(body, status,
          headers: {Headers.contentTypeHeader: ['application/json']});

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('renders profile name + phone + publicId', (tester) async {
    final dio = Dio()
      ..httpClientAdapter = _Stub(
        '{"data":{"id":"u1","phone":"+821012345678","name":"홍길동","role":"worker","public_id":"PUB123","created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}}',
      );
    final repo = MeRepository(dio);
    await tester.pumpWidget(MaterialApp(
        home: MyPageScreen(appType: 'worker', meRepository: repo)));
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
    await tester.pumpWidget(MaterialApp(
        home: MyPageScreen(appType: 'worker', meRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('연결이 불안정'), findsOneWidget);
  });
}
