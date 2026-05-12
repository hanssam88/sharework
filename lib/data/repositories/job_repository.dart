import 'package:dio/dio.dart';
import '../api_client.dart';
import '../../models/api_models/job.dart';
import '../../models/api_models/job_photo.dart';
import '../../models/api_models/photo_upload_info.dart';

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

extension JobRepositoryM2 on JobRepository {
  Future<List<Job>> listMine({String? status}) async {
    final res = await _dio.get(
      '/api/me/jobs',
      queryParameters: {if (status != null) 'status': status},
    );
    final items = ((res.data as Map)['data'] as Map)['items'] as List;
    return items.cast<Map<String, Object?>>().map(Job.fromJson).toList();
  }

  Future<Job> createJob({
    required String title,
    required String description,
    required int wageWon,
    String? scheduleText,
    required String categoryId,
    required String locationAddress,
    double? locationLat,
    double? locationLng,
  }) async {
    final res = await _dio.post('/api/jobs', data: {
      'title': title,
      'description': description,
      'wage_won': wageWon,
      if (scheduleText != null) 'schedule_text': scheduleText,
      'category_id': categoryId,
      'location_address': locationAddress,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
    });
    return Job.fromJson(
      ((res.data as Map)['data'] as Map).cast<String, Object?>(),
    );
  }

  Future<Job> updateJob(
    String jobId, {
    String? title,
    String? description,
    int? wageWon,
    String? scheduleText,
    String? categoryId,
    String? locationAddress,
    double? locationLat,
    double? locationLng,
    String? status,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (wageWon != null) 'wage_won': wageWon,
      if (scheduleText != null) 'schedule_text': scheduleText,
      if (categoryId != null) 'category_id': categoryId,
      if (locationAddress != null) 'location_address': locationAddress,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
      if (status != null) 'status': status,
    };
    final res = await _dio.patch('/api/jobs/$jobId', data: body);
    return Job.fromJson(
      ((res.data as Map)['data'] as Map).cast<String, Object?>(),
    );
  }

  Future<PhotoUploadInfo> requestPhotoUploadUrl(
    String jobId, {
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    final res = await _dio.post(
      '/api/jobs/$jobId/photos/upload-url',
      data: {
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
      },
    );
    final d = ((res.data as Map)['data'] as Map).cast<String, dynamic>();
    return PhotoUploadInfo.fromJson(d);
  }

  Future<JobPhoto> confirmPhoto(
    String jobId, {
    required String storagePath,
    required String mimeType,
    required int fileSizeBytes,
    int? width,
    int? height,
  }) async {
    final res = await _dio.post(
      '/api/jobs/$jobId/photos/confirm',
      data: {
        'storage_path': storagePath,
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      },
    );
    return JobPhoto.fromJson(
      ((res.data as Map)['data'] as Map).cast<String, Object?>(),
    );
  }

  Future<bool> deletePhoto(String jobId, String photoId) async {
    final res = await _dio.delete('/api/jobs/$jobId/photos/$photoId');
    final d = ((res.data as Map)['data'] as Map).cast<String, Object?>();
    final deleted = d['deleted'];
    if (deleted is! bool) {
      throw StateError(
        'deletePhoto contract violation: data.deleted missing or not bool, got: $deleted',
      );
    }
    return deleted;
  }

  Future<List<JobPhoto>> reorderPhotos(String jobId, List<String> order) async {
    final res = await _dio.patch(
      '/api/jobs/$jobId/photos/reorder',
      data: {'order': order},
    );
    final items = (res.data as Map)['data'] as List;
    return items.cast<Map<String, Object?>>().map(JobPhoto.fromJson).toList();
  }
}
