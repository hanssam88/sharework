import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/models/api_models/job.dart' as api;
import 'package:sharework_mockup/widgets/api_job_card.dart';

api.Job _job({String? schedule}) => api.Job(
      id: 'j1',
      title: '카페 주말 알바',
      description: 'd',
      wageWon: 12000,
      scheduleText: schedule,
      status: 'active',
      categoryId: 'c1',
      locationAddress: '서울시 강남구',
      createdAt: '2026-05-11T00:00:00Z',
      updatedAt: '2026-05-11T00:00:00Z',
    );

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('renders title, location and formatted wage', (tester) async {
    await _pump(tester, ApiJobCard(job: _job()));
    expect(find.text('카페 주말 알바'), findsOneWidget);
    expect(find.text('서울시 강남구'), findsOneWidget);
    expect(find.text('12,000원'), findsOneWidget);
  });

  testWidgets('hides schedule row when scheduleText is null', (tester) async {
    await _pump(tester, ApiJobCard(job: _job()));
    expect(find.byIcon(Icons.access_time), findsNothing);
  });

  testWidgets('shows schedule row when scheduleText is present',
      (tester) async {
    await _pump(tester, ApiJobCard(job: _job(schedule: '매주 토/일 09:00~18:00')));
    expect(find.byIcon(Icons.access_time), findsOneWidget);
    expect(find.text('매주 토/일 09:00~18:00'), findsOneWidget);
  });

  testWidgets('fires onTap', (tester) async {
    var tapped = false;
    await _pump(tester, ApiJobCard(job: _job(), onTap: () => tapped = true));
    await tester.tap(find.byType(ApiJobCard));
    expect(tapped, isTrue);
  });
}
