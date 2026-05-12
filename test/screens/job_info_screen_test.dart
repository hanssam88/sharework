import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/common/job_info_screen.dart';

class _Stub implements HttpClientAdapter {
  final String body;
  final int status;
  _Stub(this.body, [this.status = 200]);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async =>
      ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  void close({bool force = false}) {}
}

JobRepository _repo(String body, [int status = 200]) {
  final dio = Dio()..httpClientAdapter = _Stub(body, status);
  return JobRepository(dio);
}

const _jobNoPhoto =
    '{"data":{"id":"j1","title":"카페 알바","description":"디테일 설명","wage_won":12000,"schedule_text":"토/일","status":"active","category_id":"c1","location_address":"서울시","giver":{"public_id":"GVR1","name":"홍길동"},"photos":[],"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}}';

const _jobThreePhotos =
    '{"data":{"id":"j1","title":"카페 알바","description":"d","wage_won":12000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울","giver":{"public_id":"GVR1","name":"홍길동"},"photos":[{"id":"p1","position":1,"signed_url":"https://example/sig1"},{"id":"p2","position":2,"signed_url":"https://example/sig2"},{"id":"p3","position":3,"signed_url":"https://example/sig3"}],"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}}';

void main() {
  testWidgets('renders job detail with title, description, giver name',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: JobInfoScreen(jobId: 'j1', jobRepository: _repo(_jobNoPhoto)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('카페 알바'), findsOneWidget);
    expect(find.text('디테일 설명'), findsOneWidget);
    expect(find.textContaining('홍길동'), findsOneWidget);
  });

  testWidgets('renders placeholder when photos empty', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: JobInfoScreen(jobId: 'j1', jobRepository: _repo(_jobNoPhoto)),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-placeholder')), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('renders PageView when photos > 0', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: JobInfoScreen(jobId: 'j1', jobRepository: _repo(_jobThreePhotos)),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byKey(const Key('photo-placeholder')), findsNothing);
  });

  testWidgets('shows error on 404', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: JobInfoScreen(
          jobId: 'missing',
          jobRepository:
              _repo('{"error":{"code":"NOT_FOUND","message":"x"}}', 404)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('연결이 불안정'), findsOneWidget);
  });
}
