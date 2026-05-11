import 'dart:typed_data';

import 'package:dio/dio.dart';
// flutter_image_compress re-exports XFile from cross_file, so we don't
// import image_picker here. Callers of uploadPhoto() will already have
// an XFile in hand from ImagePicker.pickImage().
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../data/api_client.dart';
import '../data/repositories/job_repository.dart';
import '../models/api_models/job_photo.dart';

/// Throws when the signed-URL PUT to storage fails or returns a non-2xx
/// status. The caller (UI layer) is responsible for surfacing retry —
/// per V2 spec, a new upload-url must be requested on each retry, never
/// reuse the previous one.
class PhotoUploadException implements Exception {
  final String message;
  final int? statusCode;
  PhotoUploadException(this.message, {this.statusCode});
  @override
  String toString() => 'PhotoUploadException($statusCode, $message)';
}

/// Throws when the compressed payload exceeds the 10 MB ceiling. The
/// signed-URL request is skipped to avoid burning an upload slot.
class PhotoFileTooLargeException implements Exception {
  final int sizeBytes;
  PhotoFileTooLargeException(this.sizeBytes);
  @override
  String toString() => 'PhotoFileTooLargeException($sizeBytes bytes)';
}

/// Compresses a picked image and uploads it via the signed-URL flow.
///
/// The compress step is injected as a callback so tests can stub it
/// without touching the platform channel (`FlutterImageCompress` static
/// methods rely on a method channel that is unavailable in unit tests).
typedef PhotoCompressor = Future<Uint8List?> Function(
  String path, {
  int minWidth,
  int minHeight,
  int quality,
  CompressFormat format,
});

Future<Uint8List?> _defaultCompressor(
  String path, {
  int minWidth = 1600,
  int minHeight = 1600,
  int quality = 85,
  CompressFormat format = CompressFormat.jpeg,
}) {
  return FlutterImageCompress.compressWithFile(
    path,
    minWidth: minWidth,
    minHeight: minHeight,
    quality: quality,
    format: format,
  );
}

class PhotoUploadService {
  final JobRepository _repo;
  final Dio _dioPlain;
  final PhotoCompressor _compress;

  /// Hard ceiling (BFF mirrors this — see api spec). Compressed bytes that
  /// exceed this are rejected before requesting an upload URL.
  static const int maxBytes = 10 * 1024 * 1024;

  PhotoUploadService({
    JobRepository? repo,
    Dio? dioPlain,
    PhotoCompressor? compress,
  })  : _repo = repo ?? JobRepository.fromApi(),
        _dioPlain = dioPlain ?? ApiClient.instance.plain,
        _compress = compress ?? _defaultCompressor;

  /// Pipeline:
  ///   1. Client-side compress (long-edge 1600 px, jpeg quality 85)
  ///   2. POST /api/jobs/:id/photos/upload-url (auth Dio)
  ///   3. PUT signed URL with the compressed bytes (plain Dio — no auth)
  ///   4. POST /api/jobs/:id/photos/confirm (auth Dio)
  ///
  /// Throws [PhotoFileTooLargeException] when the compressed payload is
  /// > 10 MB. Throws [PhotoUploadException] when compression yields null
  /// or the signed PUT returns non-2xx / throws. Repo-layer failures
  /// surface their own [ApiError] via Dio interceptors.
  Future<JobPhoto> uploadPhoto({
    required String jobId,
    required XFile picked,
  }) async {
    // 1. Compress
    final compressed = await _compress(
      picked.path,
      minWidth: 1600,
      minHeight: 1600,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) {
      throw PhotoUploadException('compression failed (returned null)');
    }
    final size = compressed.length;
    if (size > maxBytes) {
      throw PhotoFileTooLargeException(size);
    }
    const mime = 'image/jpeg';

    // 2. Signed URL
    final info = await _repo.requestPhotoUploadUrl(
      jobId,
      mimeType: mime,
      fileSizeBytes: size,
    );

    // 3. PUT signed URL — plain Dio, no Authorization header.
    //    V2: on failure we throw, never reuse the URL. Caller must request
    //    a fresh upload-url before retrying.
    try {
      final res = await _dioPlain.put(
        info.uploadUrl,
        data: Stream.value(compressed),
        options: Options(
          headers: {
            'content-type': mime,
            'content-length': size,
            'x-upsert': 'false',
          },
          contentType: mime,
        ),
      );
      final code = res.statusCode;
      if (code != 200 && code != 204) {
        throw PhotoUploadException(
          'signed PUT non-2xx',
          statusCode: code,
        );
      }
    } on DioException catch (e) {
      throw PhotoUploadException(
        'signed PUT failed: ${e.message ?? e.type.name}',
        statusCode: e.response?.statusCode,
      );
    }

    // 4. Confirm
    return _repo.confirmPhoto(
      jobId,
      storagePath: info.storagePath,
      mimeType: mime,
      fileSizeBytes: size,
    );
  }
}
