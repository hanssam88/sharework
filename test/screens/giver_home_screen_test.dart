import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/giver/home/giver_home_screen.dart';

class _Stub implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  String Function(RequestOptions)? bodyBuilder;
  int status = 200;
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async {
    requests.add(o);
    final body = bodyBuilder?.call(o) ?? '{"data":{"items":[]}}';
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _jobActive =
    '{"id":"1","title":"카페 알바","description":"d","wage_won":12000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울","photos":[],"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}';

JobRepository _repoWithStub(_Stub stub) {
  final dio = Dio()..httpClientAdapter = stub;
  return JobRepository(dio);
}

void main() {
  testWidgets('renders 4 status tabs (전체/모집중/일시중지/마감)', (tester) async {
    final stub = _Stub()..bodyBuilder = (o) => '{"data":{"items":[]}}';
    final repo = _repoWithStub(stub);
    await tester
        .pumpWidget(MaterialApp(home: GiverHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('모집중'), findsOneWidget);
    expect(find.text('일시중지'), findsOneWidget);
    expect(find.text('마감'), findsOneWidget);
  });

  testWidgets('initial tab=전체 → listMine() without status query param',
      (tester) async {
    final stub = _Stub()..bodyBuilder = (o) => '{"data":{"items":[]}}';
    final repo = _repoWithStub(stub);
    await tester
        .pumpWidget(MaterialApp(home: GiverHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(stub.requests, isNotEmpty);
    expect(stub.requests.first.path, '/api/me/jobs');
    expect(stub.requests.first.queryParameters.containsKey('status'), isFalse);
  });

  testWidgets('tap 일시중지 tab → listMine(status:paused) called', (tester) async {
    final stub = _Stub()..bodyBuilder = (o) => '{"data":{"items":[]}}';
    final repo = _repoWithStub(stub);
    await tester
        .pumpWidget(MaterialApp(home: GiverHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('일시중지'));
    await tester.pumpAndSettle();
    final lastReq = stub.requests.last;
    expect(lastReq.queryParameters['status'], 'paused');
  });

  testWidgets('renders job item from API response', (tester) async {
    final stub = _Stub()
      ..bodyBuilder = (o) => '{"data":{"items":[$_jobActive]}}';
    final repo = _repoWithStub(stub);
    await tester
        .pumpWidget(MaterialApp(home: GiverHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('카페 알바'), findsOneWidget);
  });

  testWidgets('shows empty state when no jobs', (tester) async {
    final stub = _Stub()..bodyBuilder = (o) => '{"data":{"items":[]}}';
    final repo = _repoWithStub(stub);
    await tester
        .pumpWidget(MaterialApp(home: GiverHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('공고가 없'), findsOneWidget);
  });

  testWidgets('shows error state on API failure', (tester) async {
    final stub = _Stub()
      ..bodyBuilder = ((o) => '{"error":{"code":"INTERNAL","message":"x"}}')
      ..status = 500;
    final repo = _repoWithStub(stub);
    await tester
        .pumpWidget(MaterialApp(home: GiverHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('연결이 불안정'), findsOneWidget);
  });

  // F R6 CR-M1: pull-to-refresh가 listMine() 재요청 트리거
  testWidgets('pull-to-refresh triggers listMine refresh', (tester) async {
    final stub = _Stub()..bodyBuilder = (o) => '{"data":{"items":[]}}';
    final repo = _repoWithStub(stub);
    await tester
        .pumpWidget(MaterialApp(home: GiverHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    final initialCount = stub.requests.length;
    expect(initialCount, 1);

    // RefreshIndicator drag-down으로 _refresh trigger.
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(stub.requests.length, greaterThanOrEqualTo(initialCount + 1));
  });
}
