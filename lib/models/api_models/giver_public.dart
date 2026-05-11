// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'giver_public.freezed.dart';
part 'giver_public.g.dart';

@freezed
class GiverPublic with _$GiverPublic {
  const factory GiverPublic({
    @JsonKey(name: 'public_id') required String publicId,
    required String name,
  }) = _GiverPublic;

  factory GiverPublic.fromJson(Map<String, dynamic> json) => _$GiverPublicFromJson(json);
}
