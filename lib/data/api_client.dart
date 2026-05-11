import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_errors.dart';
import 'env.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio auth = _buildAuth();
  late final Dio plain = _buildPlain();

  Dio _buildAuth() {
    final dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'content-type': 'application/json'},
    ));
    dio.interceptors.add(_AuthInterceptor());
    dio.interceptors.add(_ErrorInterceptor());
    return dio;
  }

  Dio _buildPlain() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
    // No interceptors — plain Dio for pre-signed S3/GCS uploads
    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (token != null) options.headers['authorization'] = 'Bearer $token';
    handler.next(options);
  }
}

// Callers must unwrap ApiError from DioException:
//   try { await ApiClient.instance.auth.get(...); }
//   on DioException catch (e) { final api = e.error is ApiError ? e.error as ApiError : null; ... }
// Dio re-wraps any exception thrown inside an interceptor as DioException(type: unknown, error: <thrown>).
class _ErrorInterceptor extends Interceptor {
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
