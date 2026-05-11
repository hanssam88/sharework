import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sharework_mockup/data/api_errors.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/models/api_models/job_photo.dart';
import 'package:sharework_mockup/screens/giver/job_create/job_create_screen.dart';
import 'package:sharework_mockup/services/photo_upload_service.dart';

class _Stub implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  String Function(RequestOptions)? bodyBuilder;
  int Function(RequestOptions)? statusBuilder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    requests.add(o);
    final body = bodyBuilder?.call(o) ?? '{}';
    final status = statusBuilder?.call(o) ?? 200;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _createdJobBody =
    '{"data":{"id":"42","title":"테스트공고","description":"d","wage_won":12000,'
    '"schedule_text":"주3일","status":"active","category_id":"cafe",'
    '"location_address":"서울","photos":[],'
    '"created_at":"2026-05-12T00:00:00Z","updated_at":"2026-05-12T00:00:00Z"}}';

/// Replicates ApiClient's _ErrorInterceptor — needed so widget tests exercise
/// the real production code path where ApiError is unwrapped from
/// `DioException.error`. JobRepository(rawDio) bypasses ApiClient.instance,
/// so we install the same interceptor manually here.
class _TestErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final res = err.response;
    if (res != null) {
      final body = res.data;
      String? rawCode;
      String message = err.message ?? 'unknown';
      if (body is Map && body['error'] is Map) {
        rawCode = body['error']['code'] as String?;
        message = (body['error']['message'] as String?) ?? message;
      }
      int? retryAfter;
      if (res.statusCode == 429) {
        retryAfter = int.tryParse(res.headers.value('retry-after') ?? '');
      }
      throw ApiError(
        statusCode: res.statusCode ?? 0,
        code: parseErrorCode(rawCode),
        message: message,
        retryAfterSec: retryAfter,
      );
    }
    handler.next(err);
  }
}

JobRepository _repoWithStub(_Stub stub) {
  final dio = Dio()..httpClientAdapter = stub;
  dio.interceptors.add(_TestErrorInterceptor());
  return JobRepository(dio);
}

/// Fake PhotoUploadService — returns deterministic JobPhoto without HTTP /
/// platform channels (the real service uses flutter_image_compress).
class _FakePhotoUploadService implements PhotoUploadService {
  int callCount = 0;
  Object? throwOnCall;

  @override
  Future<JobPhoto> uploadPhoto({
    required String jobId,
    required XFile picked,
  }) async {
    callCount++;
    if (throwOnCall != null) {
      // ignore: only_throw_errors
      throw throwOnCall!;
    }
    return JobPhoto(
      id: 'p$callCount',
      position: callCount,
      signedUrl: 'https://example/sig$callCount',
    );
  }

  @override
  dynamic noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

class _FakeImagePicker implements ImagePicker {
  XFile? Function()? pickImageImpl;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return pickImageImpl?.call();
  }

  @override
  dynamic noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  // Title — non-colliding string so dropdown '카페' tap is unambiguous.
  await tester.enterText(find.byKey(const Key('field-title')), '테스트공고');

  // Category dropdown.
  await tester.tap(find.byKey(const Key('field-category')));
  await tester.pumpAndSettle();
  // Pick the menu item explicitly (descendant of DropdownMenuItem).
  await tester.tap(
    find
        .descendant(
          of: find.byType(DropdownMenuItem<String>),
          matching: find.text('카페'),
        )
        .last,
  );
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('field-wage')), '12000');
  await tester.enterText(find.byKey(const Key('field-address')), '서울');
  await tester.enterText(find.byKey(const Key('field-desc')), 'desc');

  // Scroll the submit button into view (form is taller than 600px test viewport).
  await tester.ensureVisible(find.byKey(const Key('btn-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('btn-submit')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'form validates title required — empty submit shows error',
    (tester) async {
      final stub = _Stub();
      final repo = _repoWithStub(stub);
      await tester.pumpWidget(
        MaterialApp(home: JobCreateScreen(jobRepository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('btn-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn-submit')));
      await tester.pumpAndSettle();

      expect(find.text('제목을 입력하세요'), findsOneWidget);
      // No API call should have been made.
      expect(stub.requests, isEmpty);
    },
  );

  testWidgets('successful create → photo step visible', (tester) async {
    final stub = _Stub()..bodyBuilder = (o) => _createdJobBody;
    final repo = _repoWithStub(stub);
    await tester.pumpWidget(
      MaterialApp(home: JobCreateScreen(jobRepository: repo)),
    );
    await tester.pumpAndSettle();

    await _fillAndSubmit(tester);

    expect(find.textContaining('공고가 등록되었습니다'), findsOneWidget);
    expect(find.text('미리보기'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
  });

  testWidgets(
    'photo add tap with null pickImage → no upload (권한 거부 silent no-op)',
    (tester) async {
      final stub = _Stub()..bodyBuilder = (o) => _createdJobBody;
      final repo = _repoWithStub(stub);
      final fakeSvc = _FakePhotoUploadService();
      final fakePicker = _FakeImagePicker()..pickImageImpl = () => null;

      await tester.pumpWidget(
        MaterialApp(
          home: JobCreateScreen(
            jobRepository: repo,
            photoUploadService: fakeSvc,
            imagePicker: fakePicker,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _fillAndSubmit(tester);

      // PhotoUploadGrid uses Icons.add_photo_alternate with label '+ 사진 추가'.
      final addButton = find.byIcon(Icons.add_photo_alternate);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // pickImage returned null → uploadPhoto must not have been called.
      expect(fakeSvc.callCount, 0);
    },
  );

  testWidgets('PHOTO_LIMIT_EXCEEDED snackbar', (tester) async {
    final stub = _Stub()
      ..bodyBuilder = (o) {
        if (o.path == '/api/jobs' && o.method == 'POST') return _createdJobBody;
        return '{"error":{"code":"PHOTO_LIMIT_EXCEEDED","message":"limit"}}';
      }
      ..statusBuilder = (o) {
        if (o.path == '/api/jobs' && o.method == 'POST') return 200;
        return 409;
      };
    final repo = _repoWithStub(stub);
    final fakeSvc = _FakePhotoUploadService()
      ..throwOnCall = DioException(
        requestOptions: RequestOptions(path: '/'),
        error: ApiError(
          statusCode: 409,
          code: ApiErrorCode.photoLimitExceeded,
          message: 'limit',
        ),
      );
    final fakePicker = _FakeImagePicker()
      ..pickImageImpl = () => XFile('/tmp/fake.jpg');

    await tester.pumpWidget(
      MaterialApp(
        home: JobCreateScreen(
          jobRepository: repo,
          photoUploadService: fakeSvc,
          imagePicker: fakePicker,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _fillAndSubmit(tester);

    final addButton = find.byIcon(Icons.add_photo_alternate);
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // 'pre-step text "사진을 추가하세요. (선택, 최대 5장)"' 와 충돌 — 명시적으로 snackbar 메시지만 매칭.
    expect(find.text('최대 5장까지 등록할 수 있어요'), findsOneWidget);
  });

  testWidgets('완료 button is rendered after successful create', (tester) async {
    // go_router 컨텍스트 없이는 navigation 검증 어려움 — 본 테스트는 버튼 노출만 확인.
    final stub = _Stub()..bodyBuilder = (o) => _createdJobBody;
    final repo = _repoWithStub(stub);
    await tester.pumpWidget(
      MaterialApp(home: JobCreateScreen(jobRepository: repo)),
    );
    await tester.pumpAndSettle();

    await _fillAndSubmit(tester);

    expect(find.text('완료'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '완료'), findsOneWidget);
  });

  testWidgets('VALIDATION error from BFF → 입력값 확인 snackbar', (tester) async {
    final stub = _Stub();
    stub.bodyBuilder =
        (o) => '{"error":{"code":"VALIDATION","message":"invalid"}}';
    stub.statusBuilder = (o) => 400;
    final repo = _repoWithStub(stub);
    await tester.pumpWidget(
      MaterialApp(home: JobCreateScreen(jobRepository: repo)),
    );
    await tester.pumpAndSettle();

    // Inline fill+submit (no _fillAndSubmit) to control pumps explicitly —
    // SnackBar auto-dismiss after 4s would cause pumpAndSettle() to time out
    // or strip the widget. We pump just long enough for the snack frame.
    await tester.enterText(find.byKey(const Key('field-title')), '테스트공고');
    await tester.tap(find.byKey(const Key('field-category')));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(DropdownMenuItem<String>),
            matching: find.text('카페'),
          )
          .last,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-wage')), '12000');
    await tester.enterText(find.byKey(const Key('field-address')), '서울');
    await tester.enterText(find.byKey(const Key('field-desc')), 'desc');
    await tester.ensureVisible(find.byKey(const Key('btn-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn-submit')));
    // Pump once to schedule the async error path, then a few short pumps to
    // let the SnackBar enter the tree without waiting for its 4s auto-dismiss.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final snacks = find.byType(SnackBar);
    expect(snacks, findsOneWidget);
    expect(
      find.descendant(of: snacks, matching: find.text('입력값을 확인해주세요')),
      findsOneWidget,
    );
  });
}
