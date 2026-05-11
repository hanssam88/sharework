import 'package:dio/dio.dart';
import '../api_client.dart';
import '../../models/api_models/job.dart';

class JobRepository {
  final Dio _dio;
  JobRepository(this._dio);
  factory JobRepository.fromApi() => JobRepository(ApiClient.instance.auth);

  Future<({List<Job> items, int total})> listJobs({
    String? category,
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    final qp = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null) qp['category'] = category;
    if (q != null && q.isNotEmpty) qp['q'] = q;

    final res = await _dio.get('/api/jobs', queryParameters: qp);
    final body = res.data as Map;
    final dataList = (body['data'] as List).cast<Map<String, Object?>>();
    final pageMeta = body['page'] as Map?;
    return (
      items: dataList.map(Job.fromJson).toList(),
      total: (pageMeta?['total'] ?? dataList.length) as int,
    );
  }

  Future<Job> fetchJob(String id) async {
    final res = await _dio.get('/api/jobs/$id');
    final data = (res.data as Map)['data'] as Map<String, Object?>;
    return Job.fromJson(data);
  }
}
