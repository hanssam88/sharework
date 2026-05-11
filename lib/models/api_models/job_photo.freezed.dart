// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_photo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

JobPhoto _$JobPhotoFromJson(Map<String, dynamic> json) {
  return _JobPhoto.fromJson(json);
}

/// @nodoc
mixin _$JobPhoto {
  String get id => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  @JsonKey(name: 'signed_url')
  String get signedUrl => throw _privateConstructorUsedError;

  /// Serializes this JobPhoto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JobPhoto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JobPhotoCopyWith<JobPhoto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobPhotoCopyWith<$Res> {
  factory $JobPhotoCopyWith(JobPhoto value, $Res Function(JobPhoto) then) =
      _$JobPhotoCopyWithImpl<$Res, JobPhoto>;
  @useResult
  $Res call(
      {String id, int position, @JsonKey(name: 'signed_url') String signedUrl});
}

/// @nodoc
class _$JobPhotoCopyWithImpl<$Res, $Val extends JobPhoto>
    implements $JobPhotoCopyWith<$Res> {
  _$JobPhotoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JobPhoto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? position = null,
    Object? signedUrl = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      signedUrl: null == signedUrl
          ? _value.signedUrl
          : signedUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JobPhotoImplCopyWith<$Res>
    implements $JobPhotoCopyWith<$Res> {
  factory _$$JobPhotoImplCopyWith(
          _$JobPhotoImpl value, $Res Function(_$JobPhotoImpl) then) =
      __$$JobPhotoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, int position, @JsonKey(name: 'signed_url') String signedUrl});
}

/// @nodoc
class __$$JobPhotoImplCopyWithImpl<$Res>
    extends _$JobPhotoCopyWithImpl<$Res, _$JobPhotoImpl>
    implements _$$JobPhotoImplCopyWith<$Res> {
  __$$JobPhotoImplCopyWithImpl(
      _$JobPhotoImpl _value, $Res Function(_$JobPhotoImpl) _then)
      : super(_value, _then);

  /// Create a copy of JobPhoto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? position = null,
    Object? signedUrl = null,
  }) {
    return _then(_$JobPhotoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      signedUrl: null == signedUrl
          ? _value.signedUrl
          : signedUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JobPhotoImpl implements _JobPhoto {
  const _$JobPhotoImpl(
      {required this.id,
      required this.position,
      @JsonKey(name: 'signed_url') required this.signedUrl});

  factory _$JobPhotoImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobPhotoImplFromJson(json);

  @override
  final String id;
  @override
  final int position;
  @override
  @JsonKey(name: 'signed_url')
  final String signedUrl;

  @override
  String toString() {
    return 'JobPhoto(id: $id, position: $position, signedUrl: $signedUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobPhotoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.signedUrl, signedUrl) ||
                other.signedUrl == signedUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, position, signedUrl);

  /// Create a copy of JobPhoto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JobPhotoImplCopyWith<_$JobPhotoImpl> get copyWith =>
      __$$JobPhotoImplCopyWithImpl<_$JobPhotoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JobPhotoImplToJson(
      this,
    );
  }
}

abstract class _JobPhoto implements JobPhoto {
  const factory _JobPhoto(
          {required final String id,
          required final int position,
          @JsonKey(name: 'signed_url') required final String signedUrl}) =
      _$JobPhotoImpl;

  factory _JobPhoto.fromJson(Map<String, dynamic> json) =
      _$JobPhotoImpl.fromJson;

  @override
  String get id;
  @override
  int get position;
  @override
  @JsonKey(name: 'signed_url')
  String get signedUrl;

  /// Create a copy of JobPhoto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JobPhotoImplCopyWith<_$JobPhotoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
