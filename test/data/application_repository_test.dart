import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/application_repository.dart';

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

const _listBody = '''
{"data":{"items":[
  {"id":"a1","job_id":"j1","status":"applied","cover_note":null,"rejected_reason":null,
   "applied_at":"2026-05-18T10:00:00Z","hired_at":null,"rejected_at":null,"withdrawn_at":null,
   "worker":{"public_id":"PUB001","name":"김알바"}},
  {"id":"a2","job_id":"j1","status":"applied","cover_note":"잘 부탁드립니다","rejected_reason":null,
   "applied_at":"2026-05-18T09:00:00Z","hired_at":null,"rejected_at":null,"withdrawn_at":null,
   "worker":{"public_id":"PUB002","name":"이워커"}}
],"has_more":false,"next_cursor":null,"counts":{"applied":2,"hired":0}}}
''';

const _decideBody =
    '{"data":{"id":"a1","status":"hired","hired_at":"2026-05-19T08:00:00Z","rejected_at":null,"rejected_reason":null}}';

const _decideRejectBody =
    '{"data":{"id":"a1","status":"rejected","hired_at":null,"rejected_at":"2026-05-19T08:00:00Z","rejected_reason":"giver_rejected"}}';

const _hiredBody = '''
{"data":{"items":[
  {"id":"a3","job_id":"j1","status":"hired","cover_note":null,"rejected_reason":null,
   "applied_at":"2026-05-18T10:00:00Z","hired_at":"2026-05-19T08:00:00Z","rejected_at":null,"withdrawn_at":null,
   "worker":{"public_id":"PUB003","name":"채용자","phone":"+821011112222"}}
],"has_more":false,"next_cursor":null,"counts":{"applied":0,"hired":1}}}
''';

void main() {
  group('ApplicationRepository', () {
    test('listForJob parses items + counts + pagination', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _StubAdapter(statusCode: 200, body: _listBody);
      final repo = ApplicationRepository(dio);

      final page = await repo.listForJob('j1');

      expect(page.items, hasLength(2));
      expect(page.items[0].id, 'a1');
      expect(page.items[0].worker.name, '김알바');
      expect(page.items[0].worker.phone, isNull);
      expect(page.items[1].coverNote, '잘 부탁드립니다');
      expect(page.hasMore, false);
      expect(page.nextCursor, isNull);
      expect(page.counts.applied, 2);
      expect(page.counts.hired, 0);
    });

    test('listForJob hired view includes worker.phone', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _StubAdapter(statusCode: 200, body: _hiredBody);
      final repo = ApplicationRepository(dio);

      final page = await repo.listForJob('j1', status: 'hired');

      expect(page.items, hasLength(1));
      expect(page.items[0].worker.phone, '+821011112222');
      expect(page.counts.hired, 1);
    });

    test('listForJob propagates status + limit + cursor as query params',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      final adapter = _StubAdapter(statusCode: 200, body: _listBody);
      dio.httpClientAdapter = adapter;
      final repo = ApplicationRepository(dio);

      await repo.listForJob(
        'j1',
        status: 'applied',
        cursor: 'CURSOR_X',
        limit: 5,
      );

      expect(adapter.lastRequest!.path, '/api/jobs/j1/applications');
      final qp = adapter.lastRequest!.queryParameters;
      expect(qp['status'], 'applied');
      expect(qp['cursor'], 'CURSOR_X');
      expect(qp['limit'], '5');
    });

    test('decide hired sends status:hired and returns echoed status',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      final adapter = _StubAdapter(statusCode: 200, body: _decideBody);
      dio.httpClientAdapter = adapter;
      final repo = ApplicationRepository(dio);

      final status = await repo.decide('j1', 'a1', status: 'hired');

      expect(status, 'hired');
      expect(adapter.lastRequest!.method, 'PATCH');
      expect(adapter.lastRequest!.path, '/api/jobs/j1/applications/a1');
      expect(adapter.lastRequestBody, {'status': 'hired'});
    });

    test('decide rejected returns rejected — rejected_reason is server-set',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      final adapter = _StubAdapter(statusCode: 200, body: _decideRejectBody);
      dio.httpClientAdapter = adapter;
      final repo = ApplicationRepository(dio);

      final status = await repo.decide('j1', 'a1', status: 'rejected');

      expect(status, 'rejected');
      // body must not include client-supplied rejected_reason
      expect(adapter.lastRequestBody, {'status': 'rejected'});
    });
  });
}
