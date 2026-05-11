import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/api_client.dart';
import 'package:sharework_mockup/data/api_errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAdapter implements HttpClientAdapter {
  ResponseBody? respond;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return respond ??
        ResponseBody.fromString('{"data":{}}', 200, headers: {
          'content-type': ['application/json'],
        });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _initSupabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Stub shared_preferences channel used by supabase_flutter's local storage.
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (call.method == 'getAll') return <String, Object>{};
    if (call.method == 'setBool' ||
        call.method == 'setString' ||
        call.method == 'remove' ||
        call.method == 'clear') {
      return true;
    }
    return null;
  });

  dotenv.testLoad(
    fileInput:
        'SUPABASE_URL=https://test.supabase.co\nSUPABASE_ANON_KEY=test-anon\nAPI_BASE_URL=http://test\n',
  );

  // Only initialize if not already done
  try {
    Supabase.instance;
  } catch (_) {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon',
    );
  }
}

/// Matcher that succeeds when a [DioException] wraps an [ApiError]
/// satisfying [innerMatcher].
///
/// Dio wraps exceptions thrown inside interceptor [onError] as
/// DioException (type=unknown) with the original as [DioException.error].
/// This helper unwraps that envelope for clean assertions.
Matcher _throwsApiError(Matcher innerMatcher) =>
    throwsA(isA<DioException>().having(
      (e) => e.error,
      'error',
      isA<ApiError>().having(
        (a) => a,
        'apiError',
        innerMatcher,
      ),
    ));

void main() {
  setUpAll(() async => _initSupabase());

  group('ApiClient.auth (dioAuth)', () {
    test('does NOT attach Authorization when no session', () async {
      final adapter = _FakeAdapter();
      ApiClient.instance.auth.httpClientAdapter = adapter;
      try {
        await ApiClient.instance.auth.get('/api/me');
      } catch (_) {/* ok */}
      expect(adapter.lastRequest?.headers['authorization'], isNull);
    });

    test(
        'error 401 AUTH_REQUIRED throws ApiError with correct code and statusCode',
        () async {
      final adapter = _FakeAdapter()
        ..respond = ResponseBody.fromString(
          '{"error":{"code":"AUTH_REQUIRED","message":"login required"}}',
          401,
          headers: {
            'content-type': ['application/json'],
          },
        );
      ApiClient.instance.auth.httpClientAdapter = adapter;
      await expectLater(
        () => ApiClient.instance.auth.get('/api/me'),
        _throwsApiError(
          isA<ApiError>()
              .having((e) => e.code, 'code', ApiErrorCode.authRequired)
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('error 401 AUTH_INVALID throws ApiError with authInvalid code',
        () async {
      final adapter = _FakeAdapter()
        ..respond = ResponseBody.fromString(
          '{"error":{"code":"AUTH_INVALID","message":"invalid token"}}',
          401,
          headers: {
            'content-type': ['application/json'],
          },
        );
      ApiClient.instance.auth.httpClientAdapter = adapter;
      await expectLater(
        () => ApiClient.instance.auth.get('/api/me'),
        _throwsApiError(
          isA<ApiError>()
              .having((e) => e.code, 'code', ApiErrorCode.authInvalid)
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('error 429 RATE_LIMITED parses retry-after header as retryAfterSec',
        () async {
      final adapter = _FakeAdapter()
        ..respond = ResponseBody.fromString(
          '{"error":{"code":"RATE_LIMITED","message":"slow down"}}',
          429,
          headers: {
            'content-type': ['application/json'],
            'retry-after': ['30'],
          },
        );
      ApiClient.instance.auth.httpClientAdapter = adapter;
      await expectLater(
        () => ApiClient.instance.auth.get('/api/jobs'),
        _throwsApiError(
          isA<ApiError>()
              .having((e) => e.code, 'code', ApiErrorCode.rateLimited)
              .having((e) => e.retryAfterSec, 'retryAfterSec', 30),
        ),
      );
    });

    test('error 404 NOT_FOUND throws ApiError with notFound code', () async {
      final adapter = _FakeAdapter()
        ..respond = ResponseBody.fromString(
          '{"error":{"code":"NOT_FOUND","message":"not found"}}',
          404,
          headers: {
            'content-type': ['application/json'],
          },
        );
      ApiClient.instance.auth.httpClientAdapter = adapter;
      await expectLater(
        () => ApiClient.instance.auth.get('/api/jobs/999'),
        _throwsApiError(
          isA<ApiError>()
              .having((e) => e.code, 'code', ApiErrorCode.notFound)
              .having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('error with unknown BFF code falls back to ApiErrorCode.unknown',
        () async {
      final adapter = _FakeAdapter()
        ..respond = ResponseBody.fromString(
          '{"error":{"code":"SOMETHING_NEW","message":"future error"}}',
          500,
          headers: {
            'content-type': ['application/json'],
          },
        );
      ApiClient.instance.auth.httpClientAdapter = adapter;
      await expectLater(
        () => ApiClient.instance.auth.get('/api/foo'),
        _throwsApiError(
          isA<ApiError>()
              .having((e) => e.code, 'code', ApiErrorCode.unknown)
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('error 403 FORBIDDEN throws ApiError with forbidden code', () async {
      final adapter = _FakeAdapter()
        ..respond = ResponseBody.fromString(
          '{"error":{"code":"FORBIDDEN","message":"forbidden"}}',
          403,
          headers: {
            'content-type': ['application/json'],
          },
        );
      ApiClient.instance.auth.httpClientAdapter = adapter;
      await expectLater(
        () => ApiClient.instance.auth.get('/api/admin'),
        _throwsApiError(
          isA<ApiError>()
              .having((e) => e.code, 'code', ApiErrorCode.forbidden)
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('ApiClient.plain (dioPlain — F1 정정)', () {
    test('plain has no AuthInterceptor — Authorization header never attached',
        () async {
      final adapter = _FakeAdapter();
      ApiClient.instance.plain.httpClientAdapter = adapter;
      try {
        await ApiClient.instance.plain
            .put('https://signed.example.com/upload', data: [1, 2, 3]);
      } catch (_) {/* network host doesn't matter, we just check headers */}
      expect(adapter.lastRequest?.headers['authorization'], isNull);
    });

    test('plain has no custom interceptors (no AuthInterceptor, no ErrorInterceptor)',
        () {
      // Dio may have 1 built-in interceptor; we verify no _AuthInterceptor type
      // and no _ErrorInterceptor. The structural invariant is zero *custom* interceptors.
      final interceptors = ApiClient.instance.plain.interceptors;
      final hasAuth = interceptors.any((i) => i.runtimeType.toString().contains('Auth'));
      final hasError = interceptors.any((i) => i.runtimeType.toString().contains('Error'));
      expect(hasAuth, isFalse, reason: 'plain must not have AuthInterceptor');
      expect(hasError, isFalse, reason: 'plain must not have ErrorInterceptor');
    });
  });

  group('parseErrorCode', () {
    test('maps all 12 BFF error codes correctly', () {
      expect(parseErrorCode('AUTH_REQUIRED'), ApiErrorCode.authRequired);
      expect(parseErrorCode('AUTH_INVALID'), ApiErrorCode.authInvalid);
      expect(parseErrorCode('FORBIDDEN'), ApiErrorCode.forbidden);
      expect(parseErrorCode('NOT_FOUND'), ApiErrorCode.notFound);
      expect(parseErrorCode('VALIDATION'), ApiErrorCode.validation);
      expect(parseErrorCode('INTERNAL'), ApiErrorCode.internal);
      expect(parseErrorCode('STORAGE_FAIL'), ApiErrorCode.storageFail);
      expect(parseErrorCode('RATE_LIMITED'), ApiErrorCode.rateLimited);
      expect(parseErrorCode('PHOTO_LIMIT_EXCEEDED'), ApiErrorCode.photoLimitExceeded);
      expect(parseErrorCode('PHOTO_FILE_INVALID'), ApiErrorCode.photoFileInvalid);
      expect(parseErrorCode('PHOTO_NOT_UPLOADED'), ApiErrorCode.photoNotUploaded);
      expect(parseErrorCode('JOB_STATE_INVALID'), ApiErrorCode.jobStateInvalid);
      expect(parseErrorCode(null), ApiErrorCode.unknown);
      expect(parseErrorCode('MADE_UP'), ApiErrorCode.unknown);
    });
  });

  group('ApiError', () {
    test('toString includes statusCode, code, and message', () {
      final err = ApiError(
        statusCode: 401,
        code: ApiErrorCode.authRequired,
        message: 'login required',
      );
      expect(err.toString(), contains('401'));
      expect(err.toString(), contains('authRequired'));
      expect(err.toString(), contains('login required'));
    });

    test('retryAfterSec is null by default', () {
      final err = ApiError(
        statusCode: 404,
        code: ApiErrorCode.notFound,
        message: 'not found',
      );
      expect(err.retryAfterSec, isNull);
    });
  });
}
