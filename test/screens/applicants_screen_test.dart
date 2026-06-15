import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/api_errors.dart';
import 'package:sharework_mockup/data/repositories/application_repository.dart';
import 'package:sharework_mockup/screens/giver/applicants/applicants_screen.dart';

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

ApplicationRepository _repoWithStub(_Stub stub) {
  final dio = Dio()..httpClientAdapter = stub;
  dio.interceptors.add(_TestErrorInterceptor());
  return ApplicationRepository(dio);
}

const _listAllBody = '''
{"data":{"items":[
  {"id":"a1","job_id":"j1","status":"applied","cover_note":"잘 부탁드립니다","rejected_reason":null,
   "applied_at":"2026-05-18T10:00:00Z","hired_at":null,"rejected_at":null,"withdrawn_at":null,
   "worker":{"public_id":"PUB001","name":"김알바"}},
  {"id":"a2","job_id":"j1","status":"applied","cover_note":null,"rejected_reason":null,
   "applied_at":"2026-05-18T09:00:00Z","hired_at":null,"rejected_at":null,"withdrawn_at":null,
   "worker":{"public_id":"PUB002","name":"이워커"}}
],"has_more":false,"next_cursor":null,"counts":{"applied":2,"hired":0}}}
''';

const _listHiredBody = '''
{"data":{"items":[],"has_more":false,"next_cursor":null,"counts":{"applied":0,"hired":0}}}
''';

const _decideHiredBody =
    '{"data":{"id":"a1","status":"hired","hired_at":"2026-05-19T08:00:00Z","rejected_at":null,"rejected_reason":null}}';

String _routeBody(RequestOptions o) {
  if (o.method == 'PATCH' && o.path.startsWith('/api/jobs/j1/applications/')) {
    return _decideHiredBody;
  }
  if (o.method == 'GET' && o.path == '/api/jobs/j1/applications') {
    final status = o.queryParameters['status'];
    return status == 'hired' ? _listHiredBody : _listAllBody;
  }
  return '{}';
}

void main() {
  testWidgets('renders pending applicants from BFF', (tester) async {
    final stub = _Stub()..bodyBuilder = _routeBody;
    final repo = _repoWithStub(stub);

    await tester.pumpWidget(MaterialApp(
      home: ApplicantsScreen(jobId: 'j1', repository: repo),
    ));
    await tester.pumpAndSettle();

    expect(find.text('김알바'), findsOneWidget);
    expect(find.text('이워커'), findsOneWidget);
    expect(find.text('잘 부탁드립니다'), findsOneWidget);
    expect(find.text('대기 2'), findsOneWidget);
    expect(find.text('채용 0'), findsOneWidget);
  });

  testWidgets('tap "채용 확정" sends PATCH with status:hired', (tester) async {
    final stub = _Stub()..bodyBuilder = _routeBody;
    final repo = _repoWithStub(stub);

    await tester.pumpWidget(MaterialApp(
      home: ApplicantsScreen(jobId: 'j1', repository: repo),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('채용 확정').first);
    await tester.pumpAndSettle();

    final patches = stub.requests.where((r) => r.method == 'PATCH').toList();
    expect(patches, hasLength(1));
    expect(patches.first.path, '/api/jobs/j1/applications/a1');
    expect(patches.first.data, {'status': 'hired'});
  });

  testWidgets('VALIDATION-shaped error surfaces friendly snackbar', (tester) async {
    final stub = _Stub();
    stub.statusBuilder = (o) => o.method == 'GET' ? 200 : 401;
    stub.bodyBuilder = (o) {
      if (o.method == 'PATCH') {
        return '{"error":{"code":"AUTH_REQUIRED","message":"login required"}}';
      }
      return _routeBody(o);
    };
    final repo = _repoWithStub(stub);

    await tester.pumpWidget(MaterialApp(
      home: ApplicantsScreen(jobId: 'j1', repository: repo),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('채용 확정').first);
    await tester.pump(); // start async
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('다시 로그인'), findsOneWidget);
  });
}
