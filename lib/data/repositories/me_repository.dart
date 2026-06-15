import 'package:dio/dio.dart';
import '../api_client.dart';
import '../../models/api_models/application.dart';
import '../../models/api_models/profile.dart';

class MeRepository {
  final Dio _dio;
  MeRepository(this._dio);
  factory MeRepository.fromApi() => MeRepository(ApiClient.instance.auth);

  Future<Profile> getMe() async {
    final res = await _dio.get('/api/me');
    final data = (res.data as Map)['data'] as Map<String, Object?>;
    return Profile.fromJson(data);
  }
}

extension MeApplicationsApi on MeRepository {
  /// GET /api/me/applications — Worker view, cursor pagination, no counts.
  Future<({List<Application> items, bool hasMore, String? nextCursor})>
      listMyApplications({
    String? status,
    String? jobId,
    String? cursor,
    int limit = 20,
  }) async {
    final qp = <String, dynamic>{
      'limit': limit.toString(),
      if (status != null) 'status': status,
      if (jobId != null) 'job_id': jobId,
      if (cursor != null) 'cursor': cursor,
    };
    final res = await _dio.get('/api/me/applications', queryParameters: qp);
    final data = ((res.data as Map)['data'] as Map).cast<String, dynamic>();
    final items = (data['items'] as List)
        .cast<Map<String, Object?>>()
        .map(Application.fromJson)
        .toList();
    return (
      items: items,
      hasMore: data['has_more'] as bool,
      nextCursor: data['next_cursor'] as String?,
    );
  }

  /// PATCH /api/me/applications/:id — Worker withdraw (only valid from 'applied').
  Future<void> withdrawApplication(String applicationId) async {
    await _dio.patch(
      '/api/me/applications/$applicationId',
      data: {'status': 'withdrawn'},
    );
  }
}
