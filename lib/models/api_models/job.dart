// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'giver_public.dart';
import 'job_photo.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    required String title,
    required String description,
    @JsonKey(name: 'wage_won') required int wageWon,
    @JsonKey(name: 'schedule_text') String? scheduleText,
    required String status,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'location_address') required String locationAddress,
    GiverPublic? giver,
    @Default(<JobPhoto>[]) List<JobPhoto> photos,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
