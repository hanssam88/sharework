import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/categories/category_jobs_screen.dart';
import 'package:sharework_mockup/widgets/api_job_card.dart';
import 'package:sharework_mockup/widgets/shared.dart' show EmptyState;

class _Stub implements HttpClientAdapter {
  Map<String, List<String>>? lastQuery;
  String body;
  _Stub(this.body);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async {
    lastQuery = o.uri.queryParametersAll;
    return ResponseBody.fromString(body, 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter that never resolves until [completer] completes — for loading state.
class _DelayStub implements HttpClientAdapter {
  final Completer<ResponseBody> completer;
  _DelayStub(this.completer);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) => completer.future;
  @override
  void close({bool force = false}) {}
}

/// Adapter that throws — for the error branch.
class _ErrorStub implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async {
    throw DioException(requestOptions: o, message: 'boom');
  }

  @override
  void close({bool force = false}) {}
}

String _job(String id, String title, int wage, String created) =>
    '{"id":"$id","title":"$title","description":"d","wage_won":$wage,'
    '"schedule_text":null,"status":"active","category_id":"c1",'
    '"location_address":"서울","giver":{"public_id":"GVR1","name":"홍길동"},'
    '"photos":[],"created_at":"$created","updated_at":"$created"}';

String _page(List<String> jobs) =>
    '{"data":[${jobs.join(",")}],"page":{"total":${jobs.length},"page":1,"limit":20}}';

Future<JobRepository> _repoWith(String body) async {
  final dio = Dio()..httpClientAdapter = _Stub(body);
  return JobRepository(dio);
}

Future<void> _pump(WidgetTester tester, JobRepository repo) async {
  await tester.pumpWidget(MaterialApp(
    home: CategoryJobsScreen(
        categoryId: 'c1', categoryName: '카페', jobRepository: repo),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('passes categoryId to listJobs', (tester) async {
    final adapter =
        _Stub(_page([_job('j1', '카페 알바', 12000, '2026-05-11T00:00:00Z')]));
    final repo = JobRepository(Dio()..httpClientAdapter = adapter);
    await _pump(tester, repo);
    expect(adapter.lastQuery!['category'], ['c1']);
    expect(find.text('카페 알바'), findsOneWidget);
  });

  testWidgets('renders jobs via ApiJobCard with count toolbar', (tester) async {
    await _pump(
        tester,
        await _repoWith(_page([
          _job('j1', '카페 알바', 12000, '2026-05-11T00:00:00Z'),
        ])));
    expect(find.byType(ApiJobCard), findsOneWidget);
    expect(find.text('1건'), findsOneWidget);
    expect(find.text('최신순'), findsOneWidget); // default sort label
  });

  testWidgets('shows loading indicator while fetching', (tester) async {
    final completer = Completer<ResponseBody>();
    final repo = JobRepository(Dio()..httpClientAdapter = _DelayStub(completer));
    await tester.pumpWidget(MaterialApp(
      home: CategoryJobsScreen(
          categoryId: 'c1', categoryName: '카페', jobRepository: repo),
    ));
    await tester.pump(); // one frame — future not yet resolved
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(ResponseBody.fromString(
        _page([_job('j1', '카페 알바', 12000, '2026-05-11T00:00:00Z')]), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        }));
    await tester.pumpAndSettle();
  });

  testWidgets('shows error message on fetch failure', (tester) async {
    final repo = JobRepository(Dio()..httpClientAdapter = _ErrorStub());
    await _pump(tester, repo);
    expect(find.text('연결이 불안정합니다'), findsOneWidget);
  });

  testWidgets('empty result shows EmptyState', (tester) async {
    await _pump(tester, await _repoWith(_page([])));
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('아직 이 카테고리에 공고가 없어요'), findsOneWidget);
    expect(find.byIcon(Icons.work_off_outlined), findsOneWidget);
  });

  testWidgets('AppBar exposes the category-alert action', (tester) async {
    await _pump(
        tester,
        await _repoWith(
            _page([_job('j1', '카페 알바', 12000, '2026-05-11T00:00:00Z')])));
    expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
  });

  testWidgets('default order is latest-first by createdAt', (tester) async {
    // j_old created earlier, j_new later -> j_new should appear above j_old
    await _pump(
        tester,
        await _repoWith(_page([
          _job('old', '오래된 공고', 10000, '2026-05-01T00:00:00Z'),
          _job('new', '최신 공고', 9000, '2026-05-20T00:00:00Z'),
        ])));
    final yNew = tester.getTopLeft(find.text('최신 공고')).dy;
    final yOld = tester.getTopLeft(find.text('오래된 공고')).dy;
    expect(yNew, lessThan(yOld));
  });

  testWidgets('switching to 시급순 orders by wage desc', (tester) async {
    await _pump(
        tester,
        await _repoWith(_page([
          _job('lo', '저시급', 9000, '2026-05-20T00:00:00Z'),
          _job('hi', '고시급', 15000, '2026-05-01T00:00:00Z'),
        ])));
    await tester.tap(find.text('최신순'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시급순').last);
    await tester.pumpAndSettle();
    final yHi = tester.getTopLeft(find.text('고시급')).dy;
    final yLo = tester.getTopLeft(find.text('저시급')).dy;
    expect(yHi, lessThan(yLo));
  });
}
