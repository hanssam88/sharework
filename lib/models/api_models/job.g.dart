// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobImpl _$$JobImplFromJson(Map<String, dynamic> json) => _$JobImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      wageWon: (json['wage_won'] as num).toInt(),
      scheduleText: json['schedule_text'] as String?,
      status: json['status'] as String,
      categoryId: json['category_id'] as String,
      locationAddress: json['location_address'] as String,
      giver: json['giver'] == null
          ? null
          : GiverPublic.fromJson(json['giver'] as Map<String, dynamic>),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => JobPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <JobPhoto>[],
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$$JobImplToJson(_$JobImpl instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'wage_won': instance.wageWon,
      'schedule_text': instance.scheduleText,
      'status': instance.status,
      'category_id': instance.categoryId,
      'location_address': instance.locationAddress,
      'giver': instance.giver,
      'photos': instance.photos,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
