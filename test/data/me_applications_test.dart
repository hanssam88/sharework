import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/me_repository.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;
  RequestOptions? lastRequest;
  Object? lastRequestBody;

  _StubAdapter({required this.statusCode, required this.body});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    lastRequestBody = options.data;
    return ResponseBody.fromString(body, statusCode, headers: {
      'content-type': ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _meApplicationsBody = '''
{"data":{"items":[
  {"id":"a1","job_id":"j1","status":"applied","cover_note":null,"rejected_reason":null,
   "applied_at":"2026-05-18T10:00:00Z","hired_at":null,"rejected_at":null,"withdrawn_at":null,
   "worker":{"public_id":"PUBW","name":"내이름"}},
  {"id":"a2","job_id":"j2","status":"hired","cover_note":"잘 부탁","rejected_reason":null,
   "applied_at":"2026-05-17T10:00:00Z","hired_at":"2026-05-18T08:00:00Z","rejected_at":null,"withdrawn_at":null,
   "worker":{"public_id":"PUBW","name":"내이름"}}
],"has_more":true,"next_cursor":"CURSOR_NEXT"}}
''';

const _withdrawBody =
    '{"data":{"id":"a1","status":"withdrawn","withdrawn_at":"2026-05-19T08:00:00Z"}}';

const _applyBody =
    '{"data":{"id":"new-app-id","status":"applied","applied_at":"2026-05-19T08:00:00Z"}}';

void main() {
  group('MeRepository.listMyApplications', () {
    test('parses items + pagination', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter =
          _StubAdapter(statusCode: 200, body: _meApplicationsBody);
      final repo = MeRepository(dio);

      final page = await repo.listMyApplications();

      expect(page.items, hasLength(2));
      expect(page.items[0].id, 'a1');
      expect(page.items[0].status, 'applied');
      expect(page.items[1].status, 'hired');
      expect(page.hasMore, true);
      expect(page.nextCursor, 'CURSOR_NEXT');
    });

    test('propagates status + job_id + cursor + limit as query params',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      final adapter = _StubAdapter(
        statusCode: 200,
        body:
            '{"data":{"items":[],"has_more":false,"next_cursor":null}}',
      );
      dio.httpClientAdapter = adapter;
      final repo = MeRepository(dio);

      await repo.listMyApplications(
        status: 'applied',
        jobId: 'job-123',
        cursor: 'CURSOR_X',
        limit: 5,
      );

      expect(adapter.lastRequest!.path, '/api/me/applications');
      final qp = adapter.lastRequest!.queryParameters;
      expect(qp['status'], 'applied');
      expect(qp['job_id'], 'job-123');
      expect(qp['cursor'], 'CURSOR_X');
      expect(qp['limit'], '5');
    });
  });

  group('MeRepository.withdrawApplication', () {
    test('sends PATCH with status:withdrawn', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      final adapter = _StubAdapter(statusCode: 200, body: _withdrawBody);
      dio.httpClientAdapter = adapter;
      final repo = MeRepository(dio);

      await repo.withdrawApplication('a1');

      expect(adapter.lastRequest!.method, 'PATCH');
      expect(adapter.lastRequest!.path, '/api/me/applications/a1');
      expect(adapter.lastRequestBody, {'status': 'withdrawn'});
    });
  });

  group('JobRepository.applyToJob', () {
    test('returns new application id', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      final adapter = _StubAdapter(statusCode: 201, body: _applyBody);
      dio.httpClientAdapter = adapter;
      final repo = JobRepository(dio);

      final id = await repo.applyToJob('j1', coverNote: '잘 부탁드립니다');

      expect(id, 'new-app-id');
      expect(adapter.lastRequest!.method, 'POST');
      expect(adapter.lastRequest!.path, '/api/jobs/j1/applications');
      expect(adapter.lastRequestBody, {'cover_note': '잘 부탁드립니다'});
    });

    test('omits cover_note when null or empty', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      final adapter = _StubAdapter(statusCode: 201, body: _applyBody);
      dio.httpClientAdapter = adapter;
      final repo = JobRepository(dio);

      await repo.applyToJob('j1');
      expect(adapter.lastRequestBody, <String, dynamic>{});

      await repo.applyToJob('j1', coverNote: '');
      expect(adapter.lastRequestBody, <String, dynamic>{});
    });
  });
}
