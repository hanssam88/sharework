import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/models/api_models/job_photo.dart';
import 'package:sharework_mockup/widgets/photo_upload_grid.dart';

import '../helpers/network_mock.dart';

void main() {
  group('PhotoUploadGrid', () {
    testWithMockNetwork(
      'renders thumbnails + add button when < 5 photos',
      (tester) async {
        final photos = [
          const JobPhoto(id: 'p1', position: 1, signedUrl: 'https://1'),
          const JobPhoto(id: 'p2', position: 2, signedUrl: 'https://2'),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoUploadGrid(
                photos: photos,
                onAdd: () {},
                onRemove: (_) {},
                onReorder: (_) {},
              ),
            ),
          ),
        );
        expect(find.text('+ 사진 추가'), findsOneWidget);
        expect(find.text('사진 2/5'), findsOneWidget);
      },
    );

    testWithMockNetwork('hides add button at 5 photos', (tester) async {
      final photos = List.generate(
        5,
        (i) => JobPhoto(id: 'p$i', position: i + 1, signedUrl: 'https://$i'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoUploadGrid(
              photos: photos,
              onAdd: () {},
              onRemove: (_) {},
              onReorder: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('+ 사진 추가'), findsNothing);
      expect(find.text('사진 5/5'), findsOneWidget);
    });

    testWithMockNetwork(
      'renders ReorderableListView for drag-to-reorder',
      (tester) async {
        final photos = List.generate(
          3,
          (i) => JobPhoto(id: 'p$i', position: i + 1, signedUrl: 'https://$i'),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoUploadGrid(
                photos: photos,
                onAdd: () {},
                onRemove: (_) {},
                onReorder: (_) {},
              ),
            ),
          ),
        );
        expect(find.byType(ReorderableListView), findsOneWidget);
      },
    );

    testWithMockNetwork(
      'tap remove button calls onRemove with photo id',
      (tester) async {
        String? removed;
        final photos = [
          const JobPhoto(id: 'p1', position: 1, signedUrl: 'https://1'),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoUploadGrid(
                photos: photos,
                onAdd: () {},
                onRemove: (id) => removed = id,
                onReorder: (_) {},
              ),
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pump();
        expect(removed, 'p1');
      },
    );

    testWithMockNetwork(
      'onReorder passes new id order with off-by-one correction',
      (tester) async {
        List<String>? result;
        final photos = List.generate(
          3,
          (i) => JobPhoto(id: 'p$i', position: i + 1, signedUrl: 'https://$i'),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoUploadGrid(
                photos: photos,
                onAdd: () {},
                onRemove: (_) {},
                onReorder: (order) => result = order,
              ),
            ),
          ),
        );
        final w = tester.widget<ReorderableListView>(
          find.byType(ReorderableListView),
        );
        // move first (idx 0) to end → newIdx=3 > oldIdx=0, corrected to 2.
        w.onReorder(0, 3);
        expect(result, ['p1', 'p2', 'p0']);
      },
    );
  });
}
