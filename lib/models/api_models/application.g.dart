// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApplicationWorkerImpl _$$ApplicationWorkerImplFromJson(
        Map<String, dynamic> json) =>
    _$ApplicationWorkerImpl(
      publicId: json['public_id'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$$ApplicationWorkerImplToJson(
        _$ApplicationWorkerImpl instance) =>
    <String, dynamic>{
      'public_id': instance.publicId,
      'name': instance.name,
      'phone': instance.phone,
    };

_$ApplicationImpl _$$ApplicationImplFromJson(Map<String, dynamic> json) =>
    _$ApplicationImpl(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      coverNote: json['cover_note'] as String?,
      rejectedReason: json['rejected_reason'] as String?,
      appliedAt: json['applied_at'] as String,
      hiredAt: json['hired_at'] as String?,
      rejectedAt: json['rejected_at'] as String?,
      withdrawnAt: json['withdrawn_at'] as String?,
      worker:
          ApplicationWorker.fromJson(json['worker'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ApplicationImplToJson(_$ApplicationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'job_id': instance.jobId,
      'status': instance.status,
      'cover_note': instance.coverNote,
      'rejected_reason': instance.rejectedReason,
      'applied_at': instance.appliedAt,
      'hired_at': instance.hiredAt,
      'rejected_at': instance.rejectedAt,
      'withdrawn_at': instance.withdrawnAt,
      'worker': instance.worker,
    };

_$ApplicationCountsImpl _$$ApplicationCountsImplFromJson(
        Map<String, dynamic> json) =>
    _$ApplicationCountsImpl(
      applied: (json['applied'] as num).toInt(),
      hired: (json['hired'] as num).toInt(),
    );

Map<String, dynamic> _$$ApplicationCountsImplToJson(
        _$ApplicationCountsImpl instance) =>
    <String, dynamic>{
      'applied': instance.applied,
      'hired': instance.hired,
    };

_$ApplicationListPageImpl _$$ApplicationListPageImplFromJson(
        Map<String, dynamic> json) =>
    _$ApplicationListPageImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => Application.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool,
      nextCursor: json['next_cursor'] as String?,
      counts:
          ApplicationCounts.fromJson(json['counts'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ApplicationListPageImplToJson(
        _$ApplicationListPageImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'has_more': instance.hasMore,
      'next_cursor': instance.nextCursor,
      'counts': instance.counts,
    };
