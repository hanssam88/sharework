// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_upload_info.freezed.dart';
part 'photo_upload_info.g.dart';

@freezed
class PhotoUploadInfo with _$PhotoUploadInfo {
  const factory PhotoUploadInfo({
    @JsonKey(name: 'photo_id') required String photoId,
    @JsonKey(name: 'storage_path') required String storagePath,
    @JsonKey(name: 'upload_url') required String uploadUrl,
    @JsonKey(name: 'expires_at') required int expiresAtMs,
  }) = _PhotoUploadInfo;

  factory PhotoUploadInfo.fromJson(Map<String, dynamic> json) =>
      _$PhotoUploadInfoFromJson(json);
}
