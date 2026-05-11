import 'package:dio/dio.dart';
import '../api_client.dart';
import '../../models/api_models/job_category.dart';

class CategoryRepository {
  final Dio _dio;
  CategoryRepository(this._dio);
  factory CategoryRepository.fromApi() =>
      CategoryRepository(ApiClient.instance.auth);

  Future<List<JobCategory>> list() async {
    final res = await _dio.get('/api/categories');
    final dataList =
        ((res.data as Map)['data'] as List).cast<Map<String, Object?>>();
    return dataList.map(JobCategory.fromJson).toList();
  }
}
