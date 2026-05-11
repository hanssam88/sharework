// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_upload_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PhotoUploadInfo _$PhotoUploadInfoFromJson(Map<String, dynamic> json) {
  return _PhotoUploadInfo.fromJson(json);
}

/// @nodoc
mixin _$PhotoUploadInfo {
  @JsonKey(name: 'photo_id')
  String get photoId => throw _privateConstructorUsedError;
  @JsonKey(name: 'storage_path')
  String get storagePath => throw _privateConstructorUsedError;
  @JsonKey(name: 'upload_url')
  String get uploadUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_at')
  int get expiresAtMs => throw _privateConstructorUsedError;

  /// Serializes this PhotoUploadInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PhotoUploadInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PhotoUploadInfoCopyWith<PhotoUploadInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PhotoUploadInfoCopyWith<$Res> {
  factory $PhotoUploadInfoCopyWith(
          PhotoUploadInfo value, $Res Function(PhotoUploadInfo) then) =
      _$PhotoUploadInfoCopyWithImpl<$Res, PhotoUploadInfo>;
  @useResult
  $Res call(
      {@JsonKey(name: 'photo_id') String photoId,
      @JsonKey(name: 'storage_path') String storagePath,
      @JsonKey(name: 'upload_url') String uploadUrl,
      @JsonKey(name: 'expires_at') int expiresAtMs});
}

/// @nodoc
class _$PhotoUploadInfoCopyWithImpl<$Res, $Val extends PhotoUploadInfo>
    implements $PhotoUploadInfoCopyWith<$Res> {
  _$PhotoUploadInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PhotoUploadInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? photoId = null,
    Object? storagePath = null,
    Object? uploadUrl = null,
    Object? expiresAtMs = null,
  }) {
    return _then(_value.copyWith(
      photoId: null == photoId
          ? _value.photoId
          : photoId // ignore: cast_nullable_to_non_nullable
              as String,
      storagePath: null == storagePath
          ? _value.storagePath
          : storagePath // ignore: cast_nullable_to_non_nullable
              as String,
      uploadUrl: null == uploadUrl
          ? _value.uploadUrl
          : uploadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAtMs: null == expiresAtMs
          ? _value.expiresAtMs
          : expiresAtMs // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PhotoUploadInfoImplCopyWith<$Res>
    implements $PhotoUploadInfoCopyWith<$Res> {
  factory _$$PhotoUploadInfoImplCopyWith(_$PhotoUploadInfoImpl value,
          $Res Function(_$PhotoUploadInfoImpl) then) =
      __$$PhotoUploadInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'photo_id') String photoId,
      @JsonKey(name: 'storage_path') String storagePath,
      @JsonKey(name: 'upload_url') String uploadUrl,
      @JsonKey(name: 'expires_at') int expiresAtMs});
}

/// @nodoc
class __$$PhotoUploadInfoImplCopyWithImpl<$Res>
    extends _$PhotoUploadInfoCopyWithImpl<$Res, _$PhotoUploadInfoImpl>
    implements _$$PhotoUploadInfoImplCopyWith<$Res> {
  __$$PhotoUploadInfoImplCopyWithImpl(
      _$PhotoUploadInfoImpl _value, $Res Function(_$PhotoUploadInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of PhotoUploadInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? photoId = null,
    Object? storagePath = null,
    Object? uploadUrl = null,
    Object? expiresAtMs = null,
  }) {
    return _then(_$PhotoUploadInfoImpl(
      photoId: null == photoId
          ? _value.photoId
          : photoId // ignore: cast_nullable_to_non_nullable
              as String,
      storagePath: null == storagePath
          ? _value.storagePath
          : storagePath // ignore: cast_nullable_to_non_nullable
              as String,
      uploadUrl: null == uploadUrl
          ? _value.uploadUrl
          : uploadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAtMs: null == expiresAtMs
          ? _value.expiresAtMs
          : expiresAtMs // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PhotoUploadInfoImpl implements _PhotoUploadInfo {
  const _$PhotoUploadInfoImpl(
      {@JsonKey(name: 'photo_id') required this.photoId,
      @JsonKey(name: 'storage_path') required this.storagePath,
      @JsonKey(name: 'upload_url') required this.uploadUrl,
      @JsonKey(name: 'expires_at') required this.expiresAtMs});

  factory _$PhotoUploadInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PhotoUploadInfoImplFromJson(json);

  @override
  @JsonKey(name: 'photo_id')
  final String photoId;
  @override
  @JsonKey(name: 'storage_path')
  final String storagePath;
  @override
  @JsonKey(name: 'upload_url')
  final String uploadUrl;
  @override
  @JsonKey(name: 'expires_at')
  final int expiresAtMs;

  @override
  String toString() {
    return 'PhotoUploadInfo(photoId: $photoId, storagePath: $storagePath, uploadUrl: $uploadUrl, expiresAtMs: $expiresAtMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PhotoUploadInfoImpl &&
            (identical(other.photoId, photoId) || other.photoId == photoId) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            (identical(other.uploadUrl, uploadUrl) ||
                other.uploadUrl == uploadUrl) &&
            (identical(other.expiresAtMs, expiresAtMs) ||
                other.expiresAtMs == expiresAtMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, photoId, storagePath, uploadUrl, expiresAtMs);

  /// Create a copy of PhotoUploadInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PhotoUploadInfoImplCopyWith<_$PhotoUploadInfoImpl> get copyWith =>
      __$$PhotoUploadInfoImplCopyWithImpl<_$PhotoUploadInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PhotoUploadInfoImplToJson(
      this,
    );
  }
}

abstract class _PhotoUploadInfo implements PhotoUploadInfo {
  const factory _PhotoUploadInfo(
          {@JsonKey(name: 'photo_id') required final String photoId,
          @JsonKey(name: 'storage_path') required final String storagePath,
          @JsonKey(name: 'upload_url') required final String uploadUrl,
          @JsonKey(name: 'expires_at') required final int expiresAtMs}) =
      _$PhotoUploadInfoImpl;

  factory _PhotoUploadInfo.fromJson(Map<String, dynamic> json) =
      _$PhotoUploadInfoImpl.fromJson;

  @override
  @JsonKey(name: 'photo_id')
  String get photoId;
  @override
  @JsonKey(name: 'storage_path')
  String get storagePath;
  @override
  @JsonKey(name: 'upload_url')
  String get uploadUrl;
  @override
  @JsonKey(name: 'expires_at')
  int get expiresAtMs;

  /// Create a copy of PhotoUploadInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PhotoUploadInfoImplCopyWith<_$PhotoUploadInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
