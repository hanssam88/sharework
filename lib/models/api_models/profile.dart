// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String phone,
    required String name,
    required String role,
    @JsonKey(name: 'public_id') required String publicId,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
