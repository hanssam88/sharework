import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/me_repository.dart';
import 'package:sharework_mockup/data/role_routing.dart';

class _StubAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;

  _StubAdapter({required this.statusCode, required this.body});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(body, statusCode, headers: {
        'content-type': ['application/json'],
      });

  @override
  void close({bool force = false}) {}
}

String _profileBody(String role) =>
    '{"data":{"id":"u1","phone":"+821012345678","name":"5678","role":"$role","public_id":"PUB001","created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}}';

MeRepository _repoWith({required int status, required String body}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.httpClientAdapter = _StubAdapter(statusCode: status, body: body);
  return MeRepository(dio);
}

void main() {
  group('homeRouteForCurrentUser', () {
    test('giver → /giver', () async {
      final route = await homeRouteForCurrentUser(
        _repoWith(status: 200, body: _profileBody('giver')),
      );
      expect(route, '/giver');
    });

    test('worker → /worker', () async {
      final route = await homeRouteForCurrentUser(
        _repoWith(status: 200, body: _profileBody('worker')),
      );
      expect(route, '/worker');
    });

    test('getMe failure falls back to /worker', () async {
      final route = await homeRouteForCurrentUser(
        _repoWith(status: 500, body: '{"error":{"code":"INTERNAL"}}'),
      );
      expect(route, '/worker');
    });
  });
}
