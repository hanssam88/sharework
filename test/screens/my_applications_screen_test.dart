import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/api_errors.dart';
import 'package:sharework_mockup/data/repositories/me_repository.dart';
import 'package:sharework_mockup/screens/worker/applications/my_applications_screen.dart';

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
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
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

MeRepository _repoWithStub(_Stub stub) {
  final dio = Dio()..httpClientAdapter = stub;
  dio.interceptors.add(_TestErrorInterceptor());
  return MeRepository(dio);
}

const _listBody = '''
{"data":{"items":[
  {"id":"a1","job_id":"j1","status":"applied","cover_note":"잘 부탁드립니다","rejected_reason":null,
   "applied_at":"2026-05-18T10:00:00Z","hired_at":null,"rejected_at":null,"withdrawn_at":null,
   "worker":{"public_id":"PUBW","name":"내이름"}},
  {"id":"a2","job_id":"j2","status":"hired","cover_note":null,"rejected_reason":null,
   "applied_at":"2026-05-17T10:00:00Z","hired_at":"2026-05-18T08:00:00Z","rejected_at":null,"withdrawn_at":null,
   "worker":{"public_id":"PUBW","name":"내이름"}}
],"has_more":false,"next_cursor":null}}
''';

const _withdrawBody =
    '{"data":{"id":"a1","status":"withdrawn","withdrawn_at":"2026-05-19T08:00:00Z"}}';

void main() {
  testWidgets('renders my applications from BFF', (tester) async {
    final stub = _Stub()..bodyBuilder = (o) => _listBody;
    final repo = _repoWithStub(stub);

    await tester.pumpWidget(MaterialApp(
      home: MyApplicationsScreen(repository: repo),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Job #j1'), findsOneWidget);
    expect(find.text('Job #j2'), findsOneWidget);
    expect(find.text('잘 부탁드립니다'), findsOneWidget);
    expect(find.text('지원중'), findsOneWidget); // applied
    expect(find.text('채용'), findsOneWidget); // hired
    expect(find.text('지원 철회'), findsOneWidget); // only on applied row
  });

  testWidgets('empty state when no applications', (tester) async {
    final stub = _Stub()
      ..bodyBuilder = (o) =>
          '{"data":{"items":[],"has_more":false,"next_cursor":null}}';
    final repo = _repoWithStub(stub);

    await tester.pumpWidget(MaterialApp(
      home: MyApplicationsScreen(repository: repo),
    ));
    await tester.pumpAndSettle();

    expect(find.text('아직 지원한 공고가 없어요'), findsOneWidget);
  });

  testWidgets('tap "지원 철회" → confirm → sends PATCH withdrawn',
      (tester) async {
    final stub = _Stub()
      ..bodyBuilder = (o) {
        if (o.method == 'PATCH') return _withdrawBody;
        return _listBody;
      };
    final repo = _repoWithStub(stub);

    await tester.pumpWidget(MaterialApp(
      home: MyApplicationsScreen(repository: repo),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('지원 철회'));
    await tester.pumpAndSettle();
    // Dialog should now be visible
    expect(find.text('이 지원을 철회할까요? 철회 후에는 다시 지원할 수 없어요.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '철회'));
    await tester.pumpAndSettle();

    final patches = stub.requests.where((r) => r.method == 'PATCH').toList();
    expect(patches, hasLength(1));
    expect(patches.first.path, '/api/me/applications/a1');
    expect(patches.first.data, {'status': 'withdrawn'});
  });

  testWidgets('AUTH_REQUIRED on load shows friendly error', (tester) async {
    final stub = _Stub();
    stub.statusBuilder = (o) => 401;
    stub.bodyBuilder = (o) =>
        '{"error":{"code":"AUTH_REQUIRED","message":"login required"}}';
    final repo = _repoWithStub(stub);

    await tester.pumpWidget(MaterialApp(
      home: MyApplicationsScreen(repository: repo),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('다시 로그인'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
