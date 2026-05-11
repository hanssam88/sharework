import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/models/api_models/job.dart';
import 'package:sharework_mockup/models/api_models/job_photo.dart';
import 'package:sharework_mockup/screens/giver/job_create/job_preview_screen.dart';

const _job = Job(
  id: '42',
  title: '카페 알바',
  description: '오전 알바 모집',
  wageWon: 12000,
  scheduleText: '주3일 9-13시',
  status: 'active',
  categoryId: 'cafe',
  locationAddress: '서울시 강남구',
  createdAt: '2026-05-12T00:00:00Z',
  updatedAt: '2026-05-12T00:00:00Z',
);

const _photo1 = JobPhoto(id: 'p1', position: 1, signedUrl: 'https://example/sig1');
const _photo2 = JobPhoto(id: 'p2', position: 2, signedUrl: 'https://example/sig2');

void main() {
  testWidgets('renders job title + wage + description from constructor args', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: JobPreviewScreen(job: _job, photos: [])),
    );
    await tester.pumpAndSettle();
    expect(find.text('카페 알바'), findsOneWidget);
    expect(find.textContaining('12000'), findsOneWidget);
    expect(find.text('오전 알바 모집'), findsOneWidget);
  });

  testWidgets('renders schedule + location', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: JobPreviewScreen(job: _job, photos: [])),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('주3일 9-13시'), findsOneWidget);
    expect(find.textContaining('서울시 강남구'), findsOneWidget);
  });

  testWidgets('schedule null → "협의"로 표시', (tester) async {
    const jobNoSchedule = Job(
      id: '42',
      title: '카페',
      description: 'd',
      wageWon: 12000,
      scheduleText: null,
      status: 'active',
      categoryId: 'cafe',
      locationAddress: '서울',
      createdAt: '2026-05-12T00:00:00Z',
      updatedAt: '2026-05-12T00:00:00Z',
    );
    await tester.pumpWidget(
      const MaterialApp(home: JobPreviewScreen(job: jobNoSchedule, photos: [])),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('일정: 협의'), findsOneWidget);
  });

  testWidgets('photos empty → placeholder Icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: JobPreviewScreen(job: _job, photos: [])),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('photos provided → PageView carousel rendered', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: JobPreviewScreen(job: _job, photos: [_photo1, _photo2])),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);
  });
}
