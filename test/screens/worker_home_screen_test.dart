import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/worker/home/worker_home_screen.dart';

class _Stub implements HttpClientAdapter {
  String body;
  int status = 200;
  _Stub(this.body);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async =>
      ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  void close({bool force = false}) {}
}

const _job =
    '{"id":"j1","title":"카페 알바","description":"d","wage_won":12000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울시","giver":{"public_id":"GVR1","name":"홍길동"},"photos":[{"id":"p1","position":1,"signed_url":"https://example/sig"}],"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}';

JobRepository _repo(String body, {int status = 200}) {
  final dio = Dio()..httpClientAdapter = (_Stub(body)..status = status);
  return JobRepository(dio);
}

void main() {
  testWidgets('renders job list from JobRepository (giver name visible)',
      (tester) async {
    final repo =
        _repo('{"data":[$_job],"page":{"total":1,"page":1,"limit":20}}');
    await tester
        .pumpWidget(MaterialApp(home: WorkerHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('카페 알바'), findsOneWidget);
    expect(find.textContaining('홍길동'), findsOneWidget); // giver.name 표시
  });

  testWidgets('shows empty state when no jobs', (tester) async {
    final repo = _repo('{"data":[],"page":{"total":0,"page":1,"limit":20}}');
    await tester
        .pumpWidget(MaterialApp(home: WorkerHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('근처 공고가 없'), findsOneWidget);
  });

  testWidgets('shows error state on API failure', (tester) async {
    final repo =
        _repo('{"error":{"code":"INTERNAL","message":"x"}}', status: 500);
    await tester
        .pumpWidget(MaterialApp(home: WorkerHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('연결이 불안정'), findsOneWidget);
  });

  testWidgets('applied/hired pill always shows 0건 in M1 (U3)', (tester) async {
    final repo = _repo('{"data":[],"page":{"total":0,"page":1,"limit":20}}');
    await tester
        .pumpWidget(MaterialApp(home: WorkerHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    final pill = find.byKey(const Key('status-pill-applied'));
    expect(pill, findsOneWidget);
    expect(
        find.descendant(of: pill, matching: find.text('0건')), findsOneWidget);
  });
}
