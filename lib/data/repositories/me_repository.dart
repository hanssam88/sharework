import 'package:dio/dio.dart';
import '../api_client.dart';
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
