// test/integration/m2_giver_smoke_test.dart
//
// M2 Giver smoke flow: GiverHome list → JobCreate (form → photo) → JobEdit
// (load → status toggle active→paused→closed → JOB_STATE_INVALID on edit).
//
// Mock-driven widget integration (no integration_test/ Flutter framework —
// see plan §F9). Each screen is directly pumped via MaterialApp (no router)
// because go_router context.push/go is unavailable in widget tests.
//
// References:
//   - M1 baseline: test/integration/m1_smoke_test.dart (_RouteMockAdapter +
//     _MockAuth + multi-screen pump pattern).
//   - B.8 / B.10 unit tests: test/screens/job_create_screen_test.dart and
//     test/screens/job_edit_screen_test.dart (Key-based finders + descendant
//     dropdown selection + SnackBar pump-without-settle).
//
// Adapter is stateful — PATCH status:closed flips `currentJob.status` so
// subsequent PATCH with non-status fields returns 409 JOB_STATE_INVALID,
// exercising the spec §6 evidence row.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sharework_mockup/data/api_errors.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/models/api_models/job.dart';
import 'package:sharework_mockup/models/api_models/job_photo.dart';
import 'package:sharework_mockup/screens/giver/home/giver_home_screen.dart';
import 'package:sharework_mockup/screens/giver/job_create/job_create_screen.dart';
import 'package:sharework_mockup/screens/giver/job_edit/job_edit_screen.dart';
import 'package:sharework_mockup/services/photo_upload_service.dart';
import 'package:sharework_mockup/widgets/job_status_toggle.dart';

// ---------------------------------------------------------------------------
// _M2Adapter — stateful, multi-endpoint route dispatch
// ---------------------------------------------------------------------------
// Holds a single `currentJob` (id=42). PATCH /api/jobs/42:
//   - if currentJob.status == 'closed' and body has title/description/wage_won
//     → 409 JOB_STATE_INVALID (the closed-edit guard branch).
//   - else if body.status present → mutate currentJob.status, return Job.
//   - else if body.title present → mutate currentJob.title, return Job.
// All non-mutation responses echo current state.
class _M2Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  Job currentJob = const Job(
    id: '42',
    title: '카페 알바',
    description: '디테일',
    wageWon: 12000,
    scheduleText: '주3일',
    status: 'active',
    categoryId: 'cafe',
    locationAddress: '서울',
    createdAt: '2026-05-12T00:00:00Z',
    updatedAt: '2026-05-12T00:00:00Z',
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestBodyStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(o);
    final m = o.method;
    final p = o.path;

    // GET /api/me/jobs → list of {items: [job]}
    if (m == 'GET' && p == '/api/me/jobs') {
      return _ok({
        'data': {
          'items': [_jobJson(currentJob)],
        },
      });
    }

    // POST /api/jobs → create. Body discarded — return currentJob as-is
    // (the test only asserts the post-create UI state, not echoed fields).
    if (m == 'POST' && p == '/api/jobs') {
      return _ok({'data': _jobJson(currentJob)});
    }

    // GET /api/jobs/:id → fetch
    if (m == 'GET' && RegExp(r'^/api/jobs/\d+$').hasMatch(p)) {
      return _ok({'data': _jobJson(currentJob)});
    }

    // PATCH /api/jobs/:id → update (status + fields)
    if (m == 'PATCH' && RegExp(r'^/api/jobs/\d+$').hasMatch(p)) {
      final data = (o.data is Map) ? o.data as Map : const {};

      // 409 guard: closed jobs cannot have non-status fields modified.
      // This branch must come BEFORE the status-update branch so it can fire
      // after a previous PATCH flipped status to 'closed'.
      final hasContentEdit = data.containsKey('title') ||
          data.containsKey('description') ||
          data.containsKey('wage_won');
      if (currentJob.status == 'closed' && hasContentEdit) {
        return _err(409, 'JOB_STATE_INVALID', '마감된 공고는 수정할 수 없어요');
      }

      // Status mutation (active|paused|closed) — mutate then echo.
      if (data['status'] is String) {
        currentJob = currentJob.copyWith(status: data['status'] as String);
      }
      // Title mutation — mutate then echo.
      if (data['title'] is String) {
        currentJob = currentJob.copyWith(title: data['title'] as String);
      }
      return _ok({'data': _jobJson(currentJob)});
    }

    return _ok(const {});
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _jobJson(Job j) => {
      'id': j.id,
      'title': j.title,
      'description': j.description,
      'wage_won': j.wageWon,
      if (j.scheduleText != null) 'schedule_text': j.scheduleText,
      'status': j.status,
      'category_id': j.categoryId,
      'location_address': j.locationAddress,
      'photos': j.photos
          .map((p) => {
                'id': p.id,
                'position': p.position,
                'signed_url': p.signedUrl,
              })
          .toList(),
      'created_at': j.createdAt,
      'updated_at': j.updatedAt,
    };

ResponseBody _ok(Map<String, dynamic> body) => ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

ResponseBody _err(int status, String code, String message) =>
    ResponseBody.fromString(
      jsonEncode({
        'error': {'code': code, 'message': message},
      }),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

// ---------------------------------------------------------------------------
// _TestErrorInterceptor — same as B.8/B.10 test pattern.
// Re-wraps response error as ApiError so screens can unwrap from DioException.
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Fakes — PhotoUploadService + ImagePicker (replicates B.8/B.10 patterns).
// ---------------------------------------------------------------------------
class _FakePhotoUploadService implements PhotoUploadService {
  int callCount = 0;

  @override
  Future<JobPhoto> uploadPhoto({
    required String jobId,
    required XFile picked,
  }) async {
    callCount++;
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

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------
void main() {
  testWidgets(
    'M2 Giver E2E: list → create → photo → edit → status toggle → JOB_STATE_INVALID',
    (tester) async {
      final adapter = _M2Adapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(_TestErrorInterceptor());
      final repo = JobRepository(dio);

      final fakeSvc = _FakePhotoUploadService();
      final fakePicker = _FakeImagePicker()
        ..pickImageImpl = () => XFile('/tmp/fake.jpg');

      // ------------------------------------------------------------------
      // Stage 1: GiverHomeScreen — listMine() renders existing job card
      // ------------------------------------------------------------------
      await tester.pumpWidget(
        MaterialApp(home: GiverHomeScreen(jobRepository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('카페 알바'), findsOneWidget,
          reason: 'GiverHome must show listMine() result');
      expect(find.text('전체'), findsOneWidget,
          reason: '4-status tab bar must render');

      // ------------------------------------------------------------------
      // Stage 2: JobCreateScreen — fill form, submit, photo step visible
      // ------------------------------------------------------------------
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

      // Form fill — Key-based finders only (B.8 pattern).
      await tester.enterText(find.byKey(const Key('field-title')), '신규 공고');

      // Dropdown — descendant pattern for unambiguous menu-item selection.
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

      await tester.enterText(find.byKey(const Key('field-wage')), '15000');
      await tester.enterText(find.byKey(const Key('field-address')), '서울 강남');
      await tester.enterText(find.byKey(const Key('field-desc')), '오전 알바');

      // Submit button below 600px viewport — ensureVisible before tap.
      await tester.ensureVisible(find.byKey(const Key('btn-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn-submit')));
      await tester.pumpAndSettle();

      // Post-create UI state (photo step).
      expect(find.textContaining('공고가 등록되었습니다'), findsOneWidget,
          reason: 'photo step header must appear after create');

      // Add a photo via fake picker → fakeSvc.uploadPhoto called once.
      final addBtn = find.byIcon(Icons.add_photo_alternate);
      expect(addBtn, findsOneWidget,
          reason: 'photo add button must render in photo step');
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(fakeSvc.callCount, 1,
          reason: 'pickImage returned XFile → uploadPhoto must fire once');

      // '완료' button rendered (do NOT tap — context.go without GoRouter throws).
      expect(find.text('완료'), findsOneWidget,
          reason: 'photo step must show 완료 button');

      // ------------------------------------------------------------------
      // Stage 3: JobEditScreen — load, status toggle active → paused
      // ------------------------------------------------------------------
      await tester.pumpWidget(
        MaterialApp(
          home: JobEditScreen(
            jobId: '42',
            jobRepository: repo,
            photoUploadService: fakeSvc,
            imagePicker: fakePicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(JobStatusToggle), findsOneWidget,
          reason: 'JobStatusToggle must render after load');

      // active → paused: immediate PATCH (no dialog).
      await tester.tap(find.text('일시중지'));
      await tester.pumpAndSettle();

      // ------------------------------------------------------------------
      // Stage 4: paused → closed: confirm dialog → PATCH status:closed
      // ------------------------------------------------------------------
      // 토글 '마감' tap (dialog 뜨기 전 단일 매칭).
      await tester.tap(find.text('마감'));
      await tester.pumpAndSettle();

      expect(find.text('공고 마감'), findsOneWidget,
          reason: 'confirm dialog title must appear');
      // Disambiguate dialog '마감' from toggle '마감' label — AlertDialog scope.
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, '마감'),
      ));
      await tester.pumpAndSettle();

      // ------------------------------------------------------------------
      // Stage 5: closed status, attempt title edit → 409 JOB_STATE_INVALID
      // ------------------------------------------------------------------
      // _job.status == 'closed' now (mutated by adapter). Form remains
      // editable; the save attempt is what triggers BFF's 409 guard.
      await tester.enterText(
        find.byKey(const Key('field-title')),
        '변경 시도',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('btn-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn-save')));
      // SnackBar pump-without-settle (B.10 pattern) — avoids 4s auto-dismiss
      // stripping the widget before our assertion.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      final snacks = find.byType(SnackBar);
      expect(snacks, findsOneWidget,
          reason: 'SnackBar must appear for 409 JOB_STATE_INVALID');
      expect(
        find.descendant(
          of: snacks,
          matching: find.text('마감된 공고는 수정할 수 없어요'),
        ),
        findsOneWidget,
        reason: '_showError must map JOB_STATE_INVALID → "마감된 공고…" message',
      );

      // ------------------------------------------------------------------
      // Stage 6: Request-count evidence (spec §6)
      // ------------------------------------------------------------------
      final listMine = adapter.requests
          .where((r) => r.method == 'GET' && r.path == '/api/me/jobs')
          .length;
      final create = adapter.requests
          .where((r) => r.method == 'POST' && r.path == '/api/jobs')
          .length;
      final fetch = adapter.requests
          .where((r) => r.method == 'GET' && r.path == '/api/jobs/42')
          .length;
      final patches = adapter.requests
          .where((r) => r.method == 'PATCH' && r.path == '/api/jobs/42')
          .toList();

      expect(listMine, 1,
          reason: 'GiverHome.listMine() must call GET /api/me/jobs once');
      expect(create, 1,
          reason: 'JobCreate._submitJob must call POST /api/jobs once');
      expect(fetch, 1,
          reason: 'JobEditScreen._load must call GET /api/jobs/42 once');
      expect(patches.length, 3,
          reason: 'three PATCHes: status:paused, status:closed, title (409)');

      // Verify the three PATCH bodies match the expected sequence.
      final body0 = patches[0].data as Map;
      expect(body0['status'], 'paused',
          reason: 'first PATCH must be status:paused');

      final body1 = patches[1].data as Map;
      expect(body1['status'], 'closed',
          reason: 'second PATCH must be status:closed');

      final body2 = patches[2].data as Map;
      expect(body2['title'], '변경 시도',
          reason: 'third PATCH (rejected) must include the title edit');
    },
  );
}
