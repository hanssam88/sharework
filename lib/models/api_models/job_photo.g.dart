// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobPhotoImpl _$$JobPhotoImplFromJson(Map<String, dynamic> json) =>
    _$JobPhotoImpl(
      id: json['id'] as String,
      position: (json['position'] as num).toInt(),
      signedUrl: json['signed_url'] as String,
    );

Map<String, dynamic> _$$JobPhotoImplToJson(_$JobPhotoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'position': instance.position,
      'signed_url': instance.signedUrl,
    };
