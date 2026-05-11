import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/common/search_screen.dart';

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

void main() {
  testWidgets('searching by q triggers JobRepository.listJobs(q=...)',
      (tester) async {
    final adapter = _Stub(
        '{"data":[],"page":{"total":0,"page":1,"limit":20}}');
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = JobRepository(dio);
    await tester
        .pumpWidget(MaterialApp(home: SearchScreen(jobRepository: repo)));
    await tester.enterText(find.byKey(const Key('search-field')), '강남');
    await tester.tap(find.byKey(const Key('search-submit')));
    await tester.pumpAndSettle();
    expect(adapter.lastQuery!['q'], ['강남']);
    expect(find.textContaining('검색 결과가 없'), findsOneWidget);
  });
}
