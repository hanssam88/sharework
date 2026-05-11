// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobCategoryImpl _$$JobCategoryImplFromJson(Map<String, dynamic> json) =>
    _$JobCategoryImpl(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String?,
    );

Map<String, dynamic> _$$JobCategoryImplToJson(_$JobCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'emoji': instance.emoji,
    };
