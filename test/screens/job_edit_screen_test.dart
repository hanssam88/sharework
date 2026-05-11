import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/api_errors.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/giver/job_edit/job_edit_screen.dart';

/// Stub adapter: records every request and returns body/status per-builder.
/// Same pattern as job_create_screen_test.dart's _Stub.
class _Stub implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  String Function(RequestOptions)? bodyBuilder;
  int Function(RequestOptions)? statusBuilder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    requests.add(o);
    final body = bodyBuilder?.call(o) ?? '{}';
    final status = statusBuilder?.call(o) ?? 200;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Replicates ApiClient's _ErrorInterceptor — unwraps response error into
/// ApiError thrown out of the interceptor (re-wrapped by Dio as DioException
/// with error=ApiError). Job edit screen's catch path depends on this exact
/// re-wrap behavior.
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
      int? retryAfter;
      if (res.statusCode == 429) {
        retryAfter = int.tryParse(res.headers.value('retry-after') ?? '');
      }
      throw ApiError(
        statusCode: res.statusCode ?? 0,
        code: parseErrorCode(rawCode),
        message: message,
        retryAfterSec: retryAfter,
      );
    }
    handler.next(err);
  }
}

JobRepository _repoWithStub(_Stub stub) {
  final dio = Dio()..httpClientAdapter = stub;
  dio.interceptors.add(_TestErrorInterceptor());
  return JobRepository(dio);
}

/// Job body for GET /api/jobs/42 — title='카페알바', wage=12000, status=active,
/// photos=[] (Job from BFF response).
const _jobBody =
    '{"data":{"id":"42","title":"카페알바","description":"오전 9시~12시","wage_won":12000,'
    '"schedule_text":"주3일 9-12시","status":"active","category_id":"cafe",'
    '"location_address":"서울 강남","photos":[],'
    '"created_at":"2026-05-12T00:00:00Z","updated_at":"2026-05-12T00:00:00Z"}}';

/// Same job with status=paused — used for status-toggle PATCH response.
const _jobBodyPaused =
    '{"data":{"id":"42","title":"카페알바","description":"오전 9시~12시","wage_won":12000,'
    '"schedule_text":"주3일 9-12시","status":"paused","category_id":"cafe",'
    '"location_address":"서울 강남","photos":[],'
    '"created_at":"2026-05-12T00:00:00Z","updated_at":"2026-05-12T00:00:00Z"}}';

/// Same job with status=closed — used for closed PATCH response.
const _jobBodyClosed =
    '{"data":{"id":"42","title":"카페알바","description":"오전 9시~12시","wage_won":12000,'
    '"schedule_text":"주3일 9-12시","status":"closed","category_id":"cafe",'
    '"location_address":"서울 강남","photos":[],'
    '"created_at":"2026-05-12T00:00:00Z","updated_at":"2026-05-12T00:00:00Z"}}';

/// Same shape with title='카페알바 수정' for PATCH-title test.
const _jobBodyTitleUpdated =
    '{"data":{"id":"42","title":"카페알바 수정","description":"오전 9시~12시","wage_won":12000,'
    '"schedule_text":"주3일 9-12시","status":"active","category_id":"cafe",'
    '"location_address":"서울 강남","photos":[],'
    '"created_at":"2026-05-12T00:00:00Z","updated_at":"2026-05-12T00:00:00Z"}}';

/// Same shape with one photo — used for photos-render test.
const _jobBodyWithPhoto =
    '{"data":{"id":"42","title":"카페알바","description":"오전 9시~12시","wage_won":12000,'
    '"schedule_text":"주3일 9-12시","status":"active","category_id":"cafe",'
    '"location_address":"서울 강남",'
    '"photos":[{"id":"p1","position":1,"signed_url":"https://example/p1.jpg"}],'
    '"created_at":"2026-05-12T00:00:00Z","updated_at":"2026-05-12T00:00:00Z"}}';

void main() {
  testWidgets(
    'loads existing job on init → renders title/wage/desc from API',
    (tester) async {
      final stub = _Stub()..bodyBuilder = (o) => _jobBody;
      final repo = _repoWithStub(stub);
      await tester.pumpWidget(
        MaterialApp(
          home: JobEditScreen(jobId: '42', jobRepository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // GET /api/jobs/42 was called.
      expect(stub.requests, isNotEmpty);
      expect(stub.requests.first.method, 'GET');
      expect(stub.requests.first.path, '/api/jobs/42');

      // Title field shows the loaded value.
      expect(find.text('카페알바'), findsOneWidget);
      expect(find.text('12000'), findsOneWidget);
      expect(find.text('오전 9시~12시'), findsOneWidget);
      expect(find.text('서울 강남'), findsOneWidget);
    },
  );

  testWidgets('tap 저장 → PATCH /api/jobs/42 with modified title',
      (tester) async {
    final stub = _Stub()
      ..bodyBuilder = (o) {
        if (o.method == 'GET') return _jobBody;
        return _jobBodyTitleUpdated;
      };
    final repo = _repoWithStub(stub);
    await tester.pumpWidget(
      MaterialApp(home: JobEditScreen(jobId: '42', jobRepository: repo)),
    );
    await tester.pumpAndSettle();

    // Edit title.
    await tester.enterText(find.byKey(const Key('field-title')), '카페알바 수정');
    await tester.pumpAndSettle();

    // Tap 저장.
    await tester.ensureVisible(find.byKey(const Key('btn-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn-save')));
    await tester.pumpAndSettle();

    // PATCH was sent.
    final patches = stub.requests.where((r) => r.method == 'PATCH').toList();
    expect(patches, isNotEmpty);
    expect(patches.first.path, '/api/jobs/42');
    // Only title is included (modified-only).
    final body = patches.first.data as Map;
    expect(body['title'], '카페알바 수정');
    expect(body.containsKey('description'), false);
    expect(body.containsKey('wage_won'), false);
  });

  testWidgets(
    'JobStatusToggle active → paused → PATCH status:paused',
    (tester) async {
      final stub = _Stub()
        ..bodyBuilder = (o) {
          if (o.method == 'GET') return _jobBody;
          return _jobBodyPaused;
        };
      final repo = _repoWithStub(stub);
      await tester.pumpWidget(
        MaterialApp(home: JobEditScreen(jobId: '42', jobRepository: repo)),
      );
      await tester.pumpAndSettle();

      // SegmentedButton '일시중지' tap.
      await tester.tap(find.text('일시중지'));
      await tester.pumpAndSettle();

      // PATCH /api/jobs/42 with status:paused was sent.
      final patches = stub.requests.where((r) => r.method == 'PATCH').toList();
      expect(patches, isNotEmpty);
      expect(patches.first.path, '/api/jobs/42');
      final body = patches.first.data as Map;
      expect(body['status'], 'paused');
    },
  );

  testWidgets(
    'JobStatusToggle active → closed → confirm dialog → PATCH status:closed',
    (tester) async {
      final stub = _Stub()
        ..bodyBuilder = (o) {
          if (o.method == 'GET') return _jobBody;
          return _jobBodyClosed;
        };
      final repo = _repoWithStub(stub);
      await tester.pumpWidget(
        MaterialApp(home: JobEditScreen(jobId: '42', jobRepository: repo)),
      );
      await tester.pumpAndSettle();

      // SegmentedButton '마감' tap → dialog appears.
      // 토글 라벨 '마감' = dialog 뜨기 전 단일 매칭.
      await tester.tap(find.text('마감'));
      await tester.pumpAndSettle();

      // Confirm dialog '마감' button — dialog title('공고 마감') + 다이얼로그 버튼('마감').
      // 토글의 '마감' 라벨과 다이얼로그 버튼 '마감' 동시 존재 → AlertDialog scope.
      expect(find.text('공고 마감'), findsOneWidget);
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, '마감'),
      ));
      await tester.pumpAndSettle();

      // PATCH /api/jobs/42 with status:closed was sent.
      final patches = stub.requests.where((r) => r.method == 'PATCH').toList();
      expect(patches, isNotEmpty);
      final body = patches.first.data as Map;
      expect(body['status'], 'closed');
    },
  );

  testWidgets('JOB_STATE_INVALID error from PATCH → snackbar', (tester) async {
    final stub = _Stub()
      ..bodyBuilder = (o) {
        if (o.method == 'GET') return _jobBody;
        return '{"error":{"code":"JOB_STATE_INVALID","message":"closed"}}';
      }
      ..statusBuilder = (o) {
        if (o.method == 'GET') return 200;
        return 409;
      };
    final repo = _repoWithStub(stub);
    await tester.pumpWidget(
      MaterialApp(home: JobEditScreen(jobId: '42', jobRepository: repo)),
    );
    await tester.pumpAndSettle();

    // Edit title and save.
    await tester.enterText(find.byKey(const Key('field-title')), '수정 시도');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('btn-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn-save')));
    // Pump just enough for SnackBar to enter without 4s auto-dismiss.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final snacks = find.byType(SnackBar);
    expect(snacks, findsOneWidget);
    expect(
      find.descendant(of: snacks, matching: find.text('마감된 공고는 수정할 수 없어요')),
      findsOneWidget,
    );
  });

  testWidgets('photos from API response → PhotoUploadGrid renders',
      (tester) async {
    final stub = _Stub()..bodyBuilder = (o) => _jobBodyWithPhoto;
    final repo = _repoWithStub(stub);
    await tester.pumpWidget(
      MaterialApp(home: JobEditScreen(jobId: '42', jobRepository: repo)),
    );
    await tester.pumpAndSettle();

    // PhotoUploadGrid header shows '사진 1/5' and add button is rendered.
    expect(find.text('사진 1/5'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
  });
}
