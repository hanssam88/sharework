import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  String? _fixedBody;
  int _fixedStatus = 200;
  RequestOptions? lastRequest;

  _StubAdapter({String? body, int status = 200})
      : _fixedBody = body,
        _fixedStatus = status;

  void setResponse(String body, {int status = 200}) {
    _fixedBody = body;
    _fixedStatus = status;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      _fixedBody ?? '{"data":[],"page":{"total":0}}',
      _fixedStatus,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _sampleJob =
    '{"id":"j1","title":"카페 알바","description":"d","wage_won":12000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울시","giver":{"public_id":"GVR001","name":"Hong"},"photos":[{"id":"p1","position":1,"signed_url":"https://example/sig"}],"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}';

const _listBody =
    '{"data":[$_sampleJob],"page":{"total":42,"page":1,"limit":20}}';

const _detailBody = '{"data":$_sampleJob}';

void main() {
  group('JobRepository', () {
    late _StubAdapter adapter;
    late JobRepository repo;

    setUp(() {
      adapter = _StubAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = adapter;
      repo = JobRepository(dio);
    });

    test('listJobs without filters returns items + total', () async {
      adapter.setResponse(_listBody);

      final result = await repo.listJobs();

      expect(result.items, hasLength(1));
      expect(result.items[0].id, 'j1');
      expect(result.items[0].title, '카페 알바');
      expect(result.total, 42);
    });

    test('listJobs passes category, q, page, limit as query params', () async {
      adapter.setResponse(_listBody);

      await repo.listJobs(category: 'cafe', q: 'barista', page: 2, limit: 10);

      final qp = adapter.lastRequest!.queryParameters;
      expect(qp['category'], 'cafe');
      expect(qp['q'], 'barista');
      expect(qp['page'], '2');
      expect(qp['limit'], '10');
    });

    test('fetchJob returns Job by id (path /api/jobs/j1)', () async {
      adapter.setResponse(_detailBody);

      final job = await repo.fetchJob('j1');

      expect(job.id, 'j1');
      expect(job.wageWon, 12000);
      expect(job.locationAddress, '서울시');
      expect(adapter.lastRequest!.path, '/api/jobs/j1');
    });

    test('listJobs parses giver and photos from M2 schema', () async {
      adapter.setResponse(_listBody);

      final result = await repo.listJobs();

      expect(result.items[0].giver?.publicId, 'GVR001');
      expect(result.items[0].giver?.name, 'Hong');
      expect(result.items[0].photos, hasLength(1));
      expect(result.items[0].photos[0].signedUrl, 'https://example/sig');
      expect(result.items[0].photos[0].position, 1);
    });
  });
}
