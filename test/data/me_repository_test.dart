import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/api_client.dart';
import 'package:sharework_mockup/data/api_errors.dart';
import 'package:sharework_mockup/data/repositories/me_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _StubAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;

  _StubAdapter({
    required this.statusCode,
    required this.body,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(body, statusCode, headers: {
        'content-type': ['application/json'],
      });

  @override
  void close({bool force = false}) {}
}

const _meBody =
    '{"data":{"id":"u1","phone":"+821012345678","name":"5678","role":"worker","public_id":"PUB001","created_at":"2026-05-11T00:00:00Z","updated_at":"2026-05-11T00:00:00Z"}}';

Future<void> _initSupabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  try {
    Supabase.instance;
  } catch (_) {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon',
    );
  }
}

void main() {
  group('MeRepository', () {
    test('getMe returns Profile on 200', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _StubAdapter(statusCode: 200, body: _meBody);
      final repo = MeRepository(dio);

      final profile = await repo.getMe();

      expect(profile.id, 'u1');
      expect(profile.phone, '+821012345678');
      expect(profile.role, 'worker');
      expect(profile.publicId, 'PUB001');
    });

    test('getMe surfaces ApiError when 401 AUTH_REQUIRED', () async {
      await _initSupabase();

      ApiClient.instance.auth.httpClientAdapter = _StubAdapter(
        statusCode: 401,
        body:
            '{"error":{"code":"AUTH_REQUIRED","message":"login required"}}',
      );

      final repo = MeRepository(ApiClient.instance.auth);

      await expectLater(
        () => repo.getMe(),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<ApiError>()
                .having((a) => a.code, 'code', ApiErrorCode.authRequired)
                .having((a) => a.statusCode, 'statusCode', 401),
          ),
        ),
      );
    });
  });
}
