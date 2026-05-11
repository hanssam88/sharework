import 'dart:typed_data';

import 'package:dio/dio.dart';
// flutter_image_compress re-exports XFile from cross_file, so we don't
// import image_picker here. Callers of uploadPhoto() will already have
// an XFile in hand from ImagePicker.pickImage().
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../data/api_client.dart';
import '../data/repositories/job_repository.dart';
import '../models/api_models/job_photo.dart';
import '../models/api_models/photo_upload_info.dart';

/// Throws on any failure across the upload pipeline — upload-url request,
/// signed PUT, or confirm. The caller (UI layer) is responsible for
/// surfacing retry — per V2 spec, a new upload-url must be requested on
/// each retry, never reuse the previous one.
class PhotoUploadException implements Exception {
  final String message;
  final int? statusCode;
  PhotoUploadException(this.message, {this.statusCode});
  @override
  String toString() => statusCode == null
      ? 'PhotoUploadException($message)'
      : 'PhotoUploadException($statusCode, $message)';
}

/// Distinct from PhotoUploadException by design — UI surfaces a size-specific message
/// ("사진이 너무 큽니다") rather than "다시 시도해주세요". Caller must catch both types separately.
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

/// Compression parameters — single source of truth for both the default
/// compressor and the uploadPhoto call site (avoids drift). Top-level so
/// `_defaultCompressor`'s default-parameter expressions (which must be
/// compile-time constants) can reference them.
const int _kCompressLongEdge = 1600;
const int _kCompressQuality = 85;
const CompressFormat _kCompressFormat = CompressFormat.jpeg;

Future<Uint8List?> _defaultCompressor(
  String path, {
  int minWidth = _kCompressLongEdge,
  int minHeight = _kCompressLongEdge,
  int quality = _kCompressQuality,
  CompressFormat format = _kCompressFormat,
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
  /// > 10 MB. Throws [PhotoUploadException] for ALL other pipeline
  /// failures — compression returning null, upload-url request failing,
  /// signed PUT returning non-2xx / throwing, or confirm failing. UI layer
  /// catches a single exception type to surface "다시 시도해주세요".
  Future<JobPhoto> uploadPhoto({
    required String jobId,
    required XFile picked,
  }) async {
    // 1. Compress
    final compressed = await _compress(
      picked.path,
      minWidth: _kCompressLongEdge,
      minHeight: _kCompressLongEdge,
      quality: _kCompressQuality,
      format: _kCompressFormat,
    );
    if (compressed == null) {
      throw PhotoUploadException('compression failed (returned null)');
    }
    final size = compressed.length;
    if (size > maxBytes) {
      throw PhotoFileTooLargeException(size);
    }
    const mime = 'image/jpeg';

    // 2. Signed URL — wrap DioException as PhotoUploadException so UI can
    //    catch a single type across the whole pipeline.
    final PhotoUploadInfo info;
    try {
      info = await _repo.requestPhotoUploadUrl(
        jobId,
        mimeType: mime,
        fileSizeBytes: size,
      );
    } on DioException catch (e) {
      throw PhotoUploadException(
        'upload-url request failed: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }

    // 3. PUT signed URL — plain Dio, no Authorization header.
    //    V2: on failure we throw, never reuse the URL. Caller must request
    //    a fresh upload-url before retrying.
    try {
      final res = await _dioPlain.put(
        info.uploadUrl,
        data: Stream.value(compressed),
        options: Options(
          // content-type set in both headers (for raw HTTP) and contentType
          // (for Dio's transformer); Supabase signed PUT needs the wire header.
          headers: {
            'content-type': mime,
            'content-length': size,
            'x-upsert': 'false',
          },
          contentType: mime,
        ),
      );
      final code = res.statusCode;
      if (code == null || code < 200 || code >= 300) {
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

    // 4. Confirm — wrap DioException so caller has one type to catch.
    //    Note: if confirm fails AFTER a successful PUT, the blob is
    //    stranded in storage (BFF reconciler must clean). UI just surfaces
    //    the exception; user retries with a fresh upload-url.
    try {
      final photo = await _repo.confirmPhoto(
        jobId,
        storagePath: info.storagePath,
        mimeType: mime,
        fileSizeBytes: size,
      );
      return photo;
    } on DioException catch (e) {
      throw PhotoUploadException(
        'confirm failed: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
