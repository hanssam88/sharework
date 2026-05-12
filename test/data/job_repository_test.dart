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

  group('JobRepository M2', () {
    late _StubAdapter adapter;
    late JobRepository repo;

    setUp(() {
      adapter = _StubAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = adapter;
      repo = JobRepository(dio);
    });

    test('listMine() returns own jobs across statuses', () async {
      adapter.setResponse('{"data":{"items":[$_sampleJob]}}');

      final items = await repo.listMine();

      expect(items, hasLength(1));
      expect(items[0].id, 'j1');
      expect(adapter.lastRequest!.path, '/api/me/jobs');
      expect(adapter.lastRequest!.method, 'GET');
    });

    test('listMine() passes status query when provided', () async {
      adapter.setResponse('{"data":{"items":[]}}');

      final items = await repo.listMine(status: 'paused');

      expect(items, isEmpty);
      expect(adapter.lastRequest!.queryParameters['status'], 'paused');
    });

    test('createJob() POSTs to /api/jobs', () async {
      adapter.setResponse(_detailBody);

      final created = await repo.createJob(
        title: 't',
        description: 'd',
        wageWon: 1000,
        categoryId: 'c-1',
        locationAddress: 'S',
      );

      expect(created.id, isNotEmpty);
      expect(created.id, 'j1');
      expect(adapter.lastRequest!.path, '/api/jobs');
      expect(adapter.lastRequest!.method, 'POST');
      final body = adapter.lastRequest!.data as Map;
      expect(body['title'], 't');
      expect(body['description'], 'd');
      expect(body['wage_won'], 1000);
      expect(body['category_id'], 'c-1');
      expect(body['location_address'], 'S');
      expect(body.containsKey('schedule_text'), isFalse);
      expect(body.containsKey('location_lat'), isFalse);
    });

    test('createJob() includes optional schedule_text and lat/lng when set',
        () async {
      adapter.setResponse(_detailBody);

      await repo.createJob(
        title: 't',
        description: 'd',
        wageWon: 1000,
        scheduleText: '평일 9-18',
        categoryId: 'c-1',
        locationAddress: 'S',
        locationLat: 37.5,
        locationLng: 127.0,
      );

      final body = adapter.lastRequest!.data as Map;
      expect(body['schedule_text'], '평일 9-18');
      expect(body['location_lat'], 37.5);
      expect(body['location_lng'], 127.0);
    });

    test('updateJob() PATCHes /api/jobs/:id with status', () async {
      const pausedJob =
          '{"id":"j-1","title":"카페 알바","description":"d","wage_won":12000,"schedule_text":null,"status":"paused","category_id":"c1","location_address":"서울시","giver":{"public_id":"GVR001","name":"Hong"},"photos":[],"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}';
      adapter.setResponse('{"data":$pausedJob}');

      final updated = await repo.updateJob('j-1', status: 'paused');

      expect(updated.status, 'paused');
      expect(adapter.lastRequest!.path, '/api/jobs/j-1');
      expect(adapter.lastRequest!.method, 'PATCH');
      final body = adapter.lastRequest!.data as Map;
      expect(body['status'], 'paused');
      // partial update: only status set, no other fields included
      expect(body.containsKey('title'), isFalse);
      expect(body.containsKey('wage_won'), isFalse);
    });

    // Sprint 3 CR-M3: clearScheduleText=true는 명시 null 전송.
    test('updateJob(clearScheduleText: true) sends schedule_text: null',
        () async {
      const cleared =
          '{"id":"j-1","title":"t","description":"d","wage_won":12000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울시","giver":{"public_id":"GVR001","name":"Hong"},"photos":[],"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}';
      adapter.setResponse('{"data":$cleared}');

      await repo.updateJob('j-1', clearScheduleText: true);

      final body = adapter.lastRequest!.data as Map;
      expect(body.containsKey('schedule_text'), isTrue);
      expect(body['schedule_text'], isNull);
    });

    test('updateJob() with multiple fields includes only set fields', () async {
      const editedJob =
          '{"id":"j-1","title":"t","description":"d","wage_won":5000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울시","location_lat":37.5,"giver":{"public_id":"GVR001","name":"Hong"},"photos":[],"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}';
      adapter.setResponse('{"data":$editedJob}');

      await repo.updateJob(
        'j-1',
        title: 't',
        wageWon: 5000,
        locationLat: 37.5,
      );

      final body = adapter.lastRequest!.data as Map;
      expect(body['title'], 't');
      expect(body['wage_won'], 5000);
      expect(body['location_lat'], 37.5);
      // other 6 fields must be absent
      expect(body.containsKey('description'), isFalse);
      expect(body.containsKey('schedule_text'), isFalse);
      expect(body.containsKey('category_id'), isFalse);
      expect(body.containsKey('location_address'), isFalse);
      expect(body.containsKey('location_lng'), isFalse);
      expect(body.containsKey('status'), isFalse);
    });

    test('requestPhotoUploadUrl returns photo_id + storage_path + upload_url',
        () async {
      adapter.setResponse(
        '{"data":{"photo_id":"p-1","storage_path":"j-1/p-1.jpg","upload_url":"https://storage.example/sig","expires_at":1715000000000}}',
      );

      final res = await repo.requestPhotoUploadUrl(
        'j-1',
        mimeType: 'image/jpeg',
        fileSizeBytes: 1000,
      );

      expect(res.photoId, 'p-1');
      expect(res.storagePath, 'j-1/p-1.jpg');
      expect(res.uploadUrl, startsWith('https://'));
      expect(res.expiresAtMs, 1715000000000);
      expect(adapter.lastRequest!.path, '/api/jobs/j-1/photos/upload-url');
      expect(adapter.lastRequest!.method, 'POST');
      final body = adapter.lastRequest!.data as Map;
      expect(body['mime_type'], 'image/jpeg');
      expect(body['file_size_bytes'], 1000);
    });

    test('confirmPhoto POSTs storage_path from prior upload-url response',
        () async {
      adapter.setResponse(
        '{"data":{"id":"p-1","position":1,"signed_url":"https://example/sig"}}',
      );

      final photo = await repo.confirmPhoto(
        'j-1',
        storagePath: 'j-1/p-1.jpg',
        mimeType: 'image/jpeg',
        fileSizeBytes: 1000,
      );

      expect(photo.id, 'p-1');
      expect(photo.position, 1);
      expect(photo.signedUrl, 'https://example/sig');
      expect(adapter.lastRequest!.path, '/api/jobs/j-1/photos/confirm');
      expect(adapter.lastRequest!.method, 'POST');
      final body = adapter.lastRequest!.data as Map;
      expect(body['storage_path'], 'j-1/p-1.jpg');
      expect(body['mime_type'], 'image/jpeg');
      expect(body['file_size_bytes'], 1000);
      expect(body.containsKey('width'), isFalse);
      expect(body.containsKey('height'), isFalse);
    });

    test('deletePhoto returns deleted=true', () async {
      adapter.setResponse('{"data":{"deleted":true}}');

      final ok = await repo.deletePhoto('j-1', 'p-1');

      expect(ok, true);
      expect(adapter.lastRequest!.path, '/api/jobs/j-1/photos/p-1');
      expect(adapter.lastRequest!.method, 'DELETE');
    });

    test(
        'deletePhoto throws StateError when contract violated (deleted missing)',
        () async {
      adapter.setResponse('{"data":{}}');

      expect(
        () => repo.deletePhoto('j-1', 'p-1'),
        throwsA(isA<StateError>()),
      );
    });

    test('reorderPhotos PATCHes new order', () async {
      adapter.setResponse(
        '{"data":['
        '{"id":"p2","position":1,"signed_url":"https://example/2"},'
        '{"id":"p1","position":2,"signed_url":"https://example/1"},'
        '{"id":"p3","position":3,"signed_url":"https://example/3"}'
        ']}',
      );

      final photos = await repo.reorderPhotos('j-1', ['p2', 'p1', 'p3']);

      expect(photos, hasLength(3));
      expect(photos[0].id, 'p2');
      expect(photos[0].position, 1);
      expect(adapter.lastRequest!.path, '/api/jobs/j-1/photos/reorder');
      expect(adapter.lastRequest!.method, 'PATCH');
      final body = adapter.lastRequest!.data as Map;
      expect(body['order'], ['p2', 'p1', 'p3']);
    });
  });
}
