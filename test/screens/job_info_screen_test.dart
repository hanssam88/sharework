import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/api_errors.dart';
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

class _RouteStub implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  String Function(RequestOptions)? bodyBuilder;
  int Function(RequestOptions)? statusBuilder;

  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async {
    requests.add(o);
    return ResponseBody.fromString(
      bodyBuilder?.call(o) ?? '{}',
      statusBuilder?.call(o) ?? 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TestErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final res = err.response;
    if (res != null) {
      final body = res.data;
      String? rawCode;
      String message = err.message ?? 'unknown';
      if (body is Map && body['error'] is Map) {
        rawCode = body['error']['code'] as String?;
        message = (body['error']['message'] as String?) ?? message;
      }
      throw ApiError(
        statusCode: res.statusCode ?? 0,
        code: parseErrorCode(rawCode),
        rawCode: rawCode,
        message: message,
      );
    }
    handler.next(err);
  }
}

JobRepository _repo(String body, [int status = 200]) {
  final dio = Dio()..httpClientAdapter = _Stub(body, status);
  return JobRepository(dio);
}

JobRepository _repoWithRouter(_RouteStub stub) {
  final dio = Dio()..httpClientAdapter = stub;
  dio.interceptors.add(_TestErrorInterceptor());
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

  group('apply flow', () {
    testWidgets('active job → "지원하기" button visible + enabled',
        (tester) async {
      final stub = _RouteStub()..bodyBuilder = (o) => _jobNoPhoto;
      await tester.pumpWidget(MaterialApp(
        home: JobInfoScreen(jobId: 'j1', jobRepository: _repoWithRouter(stub)),
      ));
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(FilledButton, '지원하기');
      expect(btn, findsOneWidget);
      expect(
        tester.widget<FilledButton>(btn).onPressed,
        isNotNull,
      );
    });

    testWidgets('tap "지원하기" → dialog → "지원" sends POST',
        (tester) async {
      final stub = _RouteStub()
        ..bodyBuilder = (o) {
          if (o.method == 'POST') {
            return '{"data":{"id":"new-app","status":"applied","applied_at":"2026-05-19T08:00:00Z"}}';
          }
          return _jobNoPhoto;
        };
      stub.statusBuilder = (o) => o.method == 'POST' ? 201 : 200;
      await tester.pumpWidget(MaterialApp(
        home: JobInfoScreen(jobId: 'j1', jobRepository: _repoWithRouter(stub)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '지원하기'));
      await tester.pumpAndSettle();
      // dialog appears
      expect(find.text('간단한 메시지 (선택)'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '카페 경험 1년');
      await tester.tap(find.widgetWithText(FilledButton, '지원'));
      await tester.pumpAndSettle();

      final posts = stub.requests.where((r) => r.method == 'POST').toList();
      expect(posts, hasLength(1));
      expect(posts.first.path, '/api/jobs/j1/applications');
      expect(posts.first.data, {'cover_note': '카페 경험 1년'});
      // button now shows "지원 완료" and is disabled
      expect(find.text('지원 완료'), findsOneWidget);
    });

    testWidgets('non-active job → "지원 불가" disabled', (tester) async {
      const closedJob =
          '{"data":{"id":"j1","title":"마감 공고","description":"d","wage_won":1,"schedule_text":null,"status":"closed","category_id":"c1","location_address":"서울","photos":[],"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}}';
      final stub = _RouteStub()..bodyBuilder = (o) => closedJob;
      await tester.pumpWidget(MaterialApp(
        home: JobInfoScreen(jobId: 'j1', jobRepository: _repoWithRouter(stub)),
      ));
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(FilledButton, '지원 불가');
      expect(btn, findsOneWidget);
      expect(tester.widget<FilledButton>(btn).onPressed, isNull);
    });

    testWidgets('REAPPLY_REJECTED error shows friendly message',
        (tester) async {
      final stub = _RouteStub();
      stub.bodyBuilder = (o) {
        if (o.method == 'POST') {
          return '{"error":{"code":"REAPPLY_REJECTED","message":"cannot reapply after rejection"}}';
        }
        return _jobNoPhoto;
      };
      stub.statusBuilder = (o) => o.method == 'POST' ? 400 : 200;
      await tester.pumpWidget(MaterialApp(
        home: JobInfoScreen(jobId: 'j1', jobRepository: _repoWithRouter(stub)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '지원하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '지원'));
      await tester.pumpAndSettle();

      expect(find.textContaining('이전에 거절된 공고'), findsOneWidget);
      // button reverts back to "지원하기" enabled
      expect(find.widgetWithText(FilledButton, '지원하기'), findsOneWidget);
    });
  });
}
