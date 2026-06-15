// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'application.freezed.dart';
part 'application.g.dart';

@freezed
class ApplicationWorker with _$ApplicationWorker {
  const factory ApplicationWorker({
    @JsonKey(name: 'public_id') String? publicId,
    required String name,
    String? phone,
  }) = _ApplicationWorker;

  factory ApplicationWorker.fromJson(Map<String, dynamic> json) =>
      _$ApplicationWorkerFromJson(json);
}

@freezed
class Application with _$Application {
  const factory Application({
    required String id,
    @JsonKey(name: 'job_id') required String jobId,
    required String status,
    @JsonKey(name: 'cover_note') String? coverNote,
    @JsonKey(name: 'rejected_reason') String? rejectedReason,
    @JsonKey(name: 'applied_at') required String appliedAt,
    @JsonKey(name: 'hired_at') String? hiredAt,
    @JsonKey(name: 'rejected_at') String? rejectedAt,
    @JsonKey(name: 'withdrawn_at') String? withdrawnAt,
    required ApplicationWorker worker,
  }) = _Application;

  factory Application.fromJson(Map<String, dynamic> json) =>
      _$ApplicationFromJson(json);
}

@freezed
class ApplicationCounts with _$ApplicationCounts {
  const factory ApplicationCounts({
    required int applied,
    required int hired,
  }) = _ApplicationCounts;

  factory ApplicationCounts.fromJson(Map<String, dynamic> json) =>
      _$ApplicationCountsFromJson(json);
}

@freezed
class ApplicationListPage with _$ApplicationListPage {
  const factory ApplicationListPage({
    required List<Application> items,
    @JsonKey(name: 'has_more') required bool hasMore,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    required ApplicationCounts counts,
  }) = _ApplicationListPage;

  factory ApplicationListPage.fromJson(Map<String, dynamic> json) =>
      _$ApplicationListPageFromJson(json);
}
