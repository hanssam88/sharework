import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/models/api_models/job_photo.dart';
import 'package:sharework_mockup/widgets/photo_upload_grid.dart';

/// 1x1 투명 PNG (Image.network이 widget test 환경에서 HTTP 호출 실패하지 않도록).
final _transparentPngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// 위젯 테스트 동안 모든 HTTP 요청에 1x1 PNG를 반환하는 가짜 HttpClient.
class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  // 본 테스트에서는 getUrl만 사용 — 나머지는 noSuchMethod로 위임.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  Future<HttpClientResponse> get done async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPngBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_transparentPngBytes])
        .listen(onData,
            onError: onError,
            onDone: onDone,
            cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// HTTP 오버라이드 zone에서 위젯 테스트를 실행.
void _testWithMockNetwork(
  String description,
  Future<void> Function(WidgetTester) callback,
) {
  testWidgets(description, (tester) async {
    await HttpOverrides.runZoned<Future<void>>(
      () => callback(tester),
      createHttpClient: (context) => _FakeHttpClient(),
    );
  });
}

void main() {
  group('PhotoUploadGrid', () {
    _testWithMockNetwork(
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

    _testWithMockNetwork('hides add button at 5 photos', (tester) async {
      final photos = List.generate(
        5,
        (i) =>
            JobPhoto(id: 'p$i', position: i + 1, signedUrl: 'https://$i'),
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

    _testWithMockNetwork(
      'renders ReorderableListView for drag-to-reorder',
      (tester) async {
        final photos = List.generate(
          3,
          (i) =>
              JobPhoto(id: 'p$i', position: i + 1, signedUrl: 'https://$i'),
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

    _testWithMockNetwork(
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
  });
}
