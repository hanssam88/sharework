import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/categories/category_jobs_screen.dart';

class _Stub implements HttpClientAdapter {
  Map<String, List<String>>? lastQuery;
  String body;
  _Stub(this.body);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async {
    lastQuery = o.uri.queryParametersAll;
    return ResponseBody.fromString(body, 200,
        headers: {Headers.contentTypeHeader: ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

const _job =
    '{"id":"j1","title":"카페 알바","description":"d","wage_won":12000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울","giver":{"public_id":"GVR1","name":"홍길동"},"photos":[],"created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}';

void main() {
  testWidgets('passes categoryId to listJobs', (tester) async {
    final adapter = _Stub(
        '{"data":[$_job],"page":{"total":1,"page":1,"limit":20}}');
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = JobRepository(dio);
    await tester.pumpWidget(MaterialApp(
      home: CategoryJobsScreen(
          categoryId: 'c1', categoryName: '카페', jobRepository: repo),
    ));
    await tester.pumpAndSettle();
    expect(adapter.lastQuery!['category'], ['c1']);
    expect(find.text('카페 알바'), findsOneWidget);
  });
}
