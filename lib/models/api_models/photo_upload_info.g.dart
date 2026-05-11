// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_upload_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PhotoUploadInfoImpl _$$PhotoUploadInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$PhotoUploadInfoImpl(
      photoId: json['photo_id'] as String,
      storagePath: json['storage_path'] as String,
      uploadUrl: json['upload_url'] as String,
      expiresAtMs: (json['expires_at'] as num).toInt(),
    );

Map<String, dynamic> _$$PhotoUploadInfoImplToJson(
        _$PhotoUploadInfoImpl instance) =>
    <String, dynamic>{
      'photo_id': instance.photoId,
      'storage_path': instance.storagePath,
      'upload_url': instance.uploadUrl,
      'expires_at': instance.expiresAtMs,
    };
