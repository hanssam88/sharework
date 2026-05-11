import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
// flutter_image_compress re-exports XFile from cross_file, matching
// what the service consumes. We mirror its import surface here.
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/services/photo_upload_service.dart';

/// Records every request and returns canned responses in order.
///
/// JobRepository's photo methods are defined in an extension
/// (`JobRepositoryM2 on JobRepository`), and extension methods are
/// statically dispatched in Dart — they cannot be intercepted by
/// mocktail. So we stub at the HttpClientAdapter layer instead, the
/// same pattern B.1's `job_repository_test.dart` uses.
class _StubAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<({String body, int status, String contentType})> _queue = [];

  void enqueue(
    String body, {
    int status = 200,
    String contentType = 'application/json',
  }) {
    _queue.add((body: body, status: status, contentType: contentType));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_queue.isEmpty) {
      return ResponseBody.fromString('{}', 200,
          headers: {
            'content-type': ['application/json'],
          });
    }
    final r = _queue.removeAt(0);
    return ResponseBody.fromString(r.body, r.status,
        headers: {
          'content-type': [r.contentType],
        });
  }

  @override
  void close({bool force = false}) {}
}

/// Stub compressor that records the path argument and returns a fixed
/// byte payload. Bypasses the platform channel (unavailable in unit
/// tests).
class _StubCompressor {
  Uint8List bytes;
  String? capturedPath;
  int callCount = 0;

  _StubCompressor(this.bytes);

  Future<Uint8List?> call(
    String path, {
    int minWidth = 1600,
    int minHeight = 1600,
    int quality = 85,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    callCount += 1;
    capturedPath = path;
    return bytes;
  }
}

void main() {
  group('PhotoUploadService', () {
    late _StubAdapter authAdapter;
    late _StubAdapter plainAdapter;
    late JobRepository repo;
    late Dio plainDio;
    late _StubCompressor compress;
    late PhotoUploadService service;
    late XFile picked;

    setUp(() {
      authAdapter = _StubAdapter();
      plainAdapter = _StubAdapter();

      final authDio = Dio(BaseOptions(baseUrl: 'http://test'));
      authDio.httpClientAdapter = authAdapter;
      repo = JobRepository(authDio);

      plainDio = Dio(BaseOptions());
      plainDio.httpClientAdapter = plainAdapter;

      compress = _StubCompressor(Uint8List.fromList(List.filled(1024, 7)));
      picked = XFile('/tmp/test.jpg');
      service = PhotoUploadService(
        repo: repo,
        dioPlain: plainDio,
        compress: compress.call,
      );
    });

    test(
        'compresses image + requests upload-url + PUT to signed URL + confirms',
        () async {
      // Auth side: upload-url then confirm.
      authAdapter.enqueue(
        '{"data":{"photo_id":"p-1","storage_path":"j-1/p-1.jpg",'
        '"upload_url":"https://storage.example/sig?token=abc",'
        '"expires_at":1715000000000}}',
      );
      authAdapter.enqueue(
        '{"data":{"id":"p-1","position":1,'
        '"signed_url":"https://storage.example/read?token=xyz"}}',
      );
      // Plain side: 200 on PUT (storage typically returns empty body /
      // text — not JSON, so set content-type accordingly).
      plainAdapter.enqueue('', status: 200, contentType: 'text/plain');

      final result =
          await service.uploadPhoto(jobId: 'j-1', picked: picked);

      expect(result.id, 'p-1');
      expect(result.position, 1);
      expect(result.signedUrl, 'https://storage.example/read?token=xyz');

      // Compress was invoked once with the picked path.
      expect(compress.callCount, 1);
      expect(compress.capturedPath, '/tmp/test.jpg');

      // 4-step pipeline order:
      //   auth[0] = POST upload-url
      //   plain[0] = PUT signed URL
      //   auth[1] = POST confirm
      expect(authAdapter.requests, hasLength(2));
      expect(plainAdapter.requests, hasLength(1));

      final uploadUrlReq = authAdapter.requests[0];
      expect(uploadUrlReq.method, 'POST');
      expect(uploadUrlReq.path, '/api/jobs/j-1/photos/upload-url');
      final uploadUrlBody = uploadUrlReq.data as Map;
      expect(uploadUrlBody['mime_type'], 'image/jpeg');
      expect(uploadUrlBody['file_size_bytes'], 1024);

      final putReq = plainAdapter.requests[0];
      expect(putReq.method, 'PUT');
      expect(putReq.uri.toString(),
          'https://storage.example/sig?token=abc');
      // Plain Dio MUST NOT carry an Authorization header (F1).
      expect(putReq.headers.containsKey('authorization'), isFalse);
      expect(putReq.headers['content-type'], 'image/jpeg');
      expect(putReq.headers['x-upsert'], 'false');

      final confirmReq = authAdapter.requests[1];
      expect(confirmReq.method, 'POST');
      expect(confirmReq.path, '/api/jobs/j-1/photos/confirm');
      final confirmBody = confirmReq.data as Map;
      expect(confirmBody['storage_path'], 'j-1/p-1.jpg');
      expect(confirmBody['mime_type'], 'image/jpeg');
      expect(confirmBody['file_size_bytes'], 1024);
    });

    test('PUT 5xx response throws PhotoUploadException (no confirm call)',
        () async {
      authAdapter.enqueue(
        '{"data":{"photo_id":"p-1","storage_path":"j-1/p-1.jpg",'
        '"upload_url":"https://storage.example/sig",'
        '"expires_at":1715000000000}}',
      );
      // Plain side: 500 — should surface as PhotoUploadException.
      // Use text/plain so Dio's transformer doesn't choke trying to
      // parse the error body as JSON (which would mask the statusCode).
      plainAdapter.enqueue('boom', status: 500, contentType: 'text/plain');

      await expectLater(
        () => service.uploadPhoto(jobId: 'j-1', picked: picked),
        throwsA(isA<PhotoUploadException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );

      // upload-url + PUT ran, but confirm must NOT have been called
      // — V2 spec: a retry must request a fresh upload-url, never reuse.
      expect(authAdapter.requests, hasLength(1));
      expect(authAdapter.requests[0].path,
          '/api/jobs/j-1/photos/upload-url');
      expect(plainAdapter.requests, hasLength(1));
    });

    test('rejects file > 10 MB after compression', () async {
      compress.bytes = Uint8List(11 * 1024 * 1024);

      await expectLater(
        () => service.uploadPhoto(jobId: 'j-1', picked: picked),
        throwsA(isA<PhotoFileTooLargeException>()
            .having((e) => e.sizeBytes, 'sizeBytes', 11 * 1024 * 1024)),
      );

      // Compress ran, but no HTTP traffic should have left the client.
      expect(compress.callCount, 1);
      expect(authAdapter.requests, isEmpty);
      expect(plainAdapter.requests, isEmpty);
    });

    test('compression returning null throws PhotoUploadException', () async {
      service = PhotoUploadService(
        repo: repo,
        dioPlain: plainDio,
        compress: (
          String path, {
          int minWidth = 1600,
          int minHeight = 1600,
          int quality = 85,
          CompressFormat format = CompressFormat.jpeg,
        }) async =>
            null,
      );

      await expectLater(
        () => service.uploadPhoto(jobId: 'j-1', picked: picked),
        throwsA(isA<PhotoUploadException>()),
      );

      expect(authAdapter.requests, isEmpty);
      expect(plainAdapter.requests, isEmpty);
    });

    test(
        'requestPhotoUploadUrl 4xx → throws PhotoUploadException (no PUT attempted)',
        () async {
      // Auth side: upload-url returns 400 — repo throws DioException
      // (interceptor wraps body as ApiError). Service must wrap as
      // PhotoUploadException so UI catches a single type.
      // Use text/plain so Dio's transformer doesn't choke on error body.
      authAdapter.enqueue(
        '{"error":{"code":"bad_request","message":"bad mime"}}',
        status: 400,
        contentType: 'application/json',
      );

      await expectLater(
        () => service.uploadPhoto(jobId: 'j-1', picked: picked),
        throwsA(isA<PhotoUploadException>()),
      );

      // upload-url was attempted, but PUT must NOT have been called —
      // a failed upload-url request means we never had a URL to PUT to.
      expect(authAdapter.requests, hasLength(1));
      expect(authAdapter.requests[0].path,
          '/api/jobs/j-1/photos/upload-url');
      expect(plainAdapter.requests, isEmpty);
    });

    test(
        'confirmPhoto 4xx → throws PhotoUploadException (PUT happened, blob stranded)',
        () async {
      // Auth side: upload-url 200 (valid PhotoUploadInfo) then confirm 400.
      authAdapter.enqueue(
        '{"data":{"photo_id":"p-1","storage_path":"j-1/p-1.jpg",'
        '"upload_url":"https://storage.example/sig?token=abc",'
        '"expires_at":1715000000000}}',
      );
      authAdapter.enqueue(
        '{"error":{"code":"conflict","message":"already confirmed"}}',
        status: 400,
        contentType: 'application/json',
      );
      // Plain side: PUT 200 — upload succeeded.
      plainAdapter.enqueue('', status: 200, contentType: 'text/plain');

      await expectLater(
        () => service.uploadPhoto(jobId: 'j-1', picked: picked),
        throwsA(isA<PhotoUploadException>()),
      );

      // PUT WAS called — upload happened but confirm failed. Blob is
      // stranded in storage (real production concern). UI catches the
      // single PhotoUploadException type and surfaces retry.
      expect(authAdapter.requests, hasLength(2));
      expect(authAdapter.requests[0].path,
          '/api/jobs/j-1/photos/upload-url');
      expect(authAdapter.requests[1].path,
          '/api/jobs/j-1/photos/confirm');
      expect(plainAdapter.requests, hasLength(1));
      expect(plainAdapter.requests[0].method, 'PUT');
    });
  });
}
