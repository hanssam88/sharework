import 'package:dio/dio.dart';
import '../api_client.dart';
import '../../models/api_models/application.dart';

class ApplicationRepository {
  final Dio _dio;
  ApplicationRepository(this._dio);
  factory ApplicationRepository.fromApi() =>
      ApplicationRepository(ApiClient.instance.auth);

  /// GET /api/jobs/:id/applications — Giver view, cursor pagination.
  /// status: 'applied' | 'hired' | 'rejected' | null(all).
  Future<ApplicationListPage> listForJob(
    String jobId, {
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    final qp = <String, dynamic>{
      'limit': limit.toString(),
      if (status != null) 'status': status,
      if (cursor != null) 'cursor': cursor,
    };
    final res =
        await _dio.get('/api/jobs/$jobId/applications', queryParameters: qp);
    final data = ((res.data as Map)['data'] as Map).cast<String, dynamic>();
    return ApplicationListPage.fromJson(data);
  }

  /// PATCH /api/jobs/:id/applications/:applicationId — Giver decision.
  /// status: 'hired' | 'rejected'. Returns new status echoed by BFF.
  /// rejected_reason is server-determined (giver_rejected). Client cannot set.
  Future<String> decide(
    String jobId,
    String applicationId, {
    required String status,
  }) async {
    final res = await _dio.patch(
      '/api/jobs/$jobId/applications/$applicationId',
      data: {'status': status},
    );
    final data = ((res.data as Map)['data'] as Map).cast<String, dynamic>();
    return data['status'] as String;
  }
}
