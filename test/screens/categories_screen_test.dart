import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/category_repository.dart';
import 'package:sharework_mockup/screens/categories/categories_screen.dart';

class _Stub implements HttpClientAdapter {
  String body;
  _Stub(this.body);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async =>
      ResponseBody.fromString(body, 200,
          headers: {Headers.contentTypeHeader: ['application/json']});

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('renders categories from CategoryRepository', (tester) async {
    final dio = Dio()
      ..httpClientAdapter = _Stub(
        '{"data":[{"id":"c1","name":"카페","slug":"cafe","emoji":"☕"},{"id":"c2","name":"식당","slug":"restaurant","emoji":"🍽"}]}',
      );
    final repo = CategoryRepository(dio);
    await tester.pumpWidget(
        MaterialApp(home: CategoriesScreen(categoryRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('카페'), findsOneWidget);
    expect(find.text('식당'), findsOneWidget);
  });

  testWidgets('shows empty state when categories empty', (tester) async {
    final dio = Dio()..httpClientAdapter = _Stub('{"data":[]}');
    final repo = CategoryRepository(dio);
    await tester.pumpWidget(
        MaterialApp(home: CategoriesScreen(categoryRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('카테고리가 비어'), findsOneWidget);
  });
}
