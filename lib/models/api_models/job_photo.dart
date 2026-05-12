// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_photo.freezed.dart';
part 'job_photo.g.dart';

@freezed
class JobPhoto with _$JobPhoto {
  const factory JobPhoto({
    required String id,
    required int position,
    @JsonKey(name: 'signed_url') required String signedUrl,
  }) = _JobPhoto;

  factory JobPhoto.fromJson(Map<String, dynamic> json) =>
      _$JobPhotoFromJson(json);
}
