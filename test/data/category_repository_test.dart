import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/category_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  final String body;
  final int statusCode;

  _StubAdapter({required this.body, required this.statusCode});

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

const _sampleCategory = '{"id":"c1","slug":"cafe","name":"카페","emoji":"☕"}';
const _sampleCategoryNoEmoji = '{"id":"c2","slug":"retail","name":"마트"}';

void main() {
  group('CategoryRepository', () {
    test('list returns categories from /api/categories', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _StubAdapter(
        body: '{"data":[$_sampleCategory]}',
        statusCode: 200,
      );
      final repo = CategoryRepository(dio);

      final categories = await repo.list();

      expect(categories, hasLength(1));
      expect(categories[0].id, 'c1');
      expect(categories[0].slug, 'cafe');
      expect(categories[0].name, '카페');
      expect(categories[0].emoji, '☕');
    });

    test('list parses emoji null when missing', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _StubAdapter(
        body: '{"data":[$_sampleCategoryNoEmoji]}',
        statusCode: 200,
      );
      final repo = CategoryRepository(dio);

      final categories = await repo.list();

      expect(categories, hasLength(1));
      expect(categories[0].id, 'c2');
      expect(categories[0].emoji, isNull);
    });
  });
}
