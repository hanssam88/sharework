// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'giver_public.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GiverPublic _$GiverPublicFromJson(Map<String, dynamic> json) {
  return _GiverPublic.fromJson(json);
}

/// @nodoc
mixin _$GiverPublic {
  @JsonKey(name: 'public_id')
  String get publicId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this GiverPublic to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GiverPublic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GiverPublicCopyWith<GiverPublic> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GiverPublicCopyWith<$Res> {
  factory $GiverPublicCopyWith(
          GiverPublic value, $Res Function(GiverPublic) then) =
      _$GiverPublicCopyWithImpl<$Res, GiverPublic>;
  @useResult
  $Res call({@JsonKey(name: 'public_id') String publicId, String name});
}

/// @nodoc
class _$GiverPublicCopyWithImpl<$Res, $Val extends GiverPublic>
    implements $GiverPublicCopyWith<$Res> {
  _$GiverPublicCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GiverPublic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicId = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      publicId: null == publicId
          ? _value.publicId
          : publicId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GiverPublicImplCopyWith<$Res>
    implements $GiverPublicCopyWith<$Res> {
  factory _$$GiverPublicImplCopyWith(
          _$GiverPublicImpl value, $Res Function(_$GiverPublicImpl) then) =
      __$$GiverPublicImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'public_id') String publicId, String name});
}

/// @nodoc
class __$$GiverPublicImplCopyWithImpl<$Res>
    extends _$GiverPublicCopyWithImpl<$Res, _$GiverPublicImpl>
    implements _$$GiverPublicImplCopyWith<$Res> {
  __$$GiverPublicImplCopyWithImpl(
      _$GiverPublicImpl _value, $Res Function(_$GiverPublicImpl) _then)
      : super(_value, _then);

  /// Create a copy of GiverPublic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicId = null,
    Object? name = null,
  }) {
    return _then(_$GiverPublicImpl(
      publicId: null == publicId
          ? _value.publicId
          : publicId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GiverPublicImpl implements _GiverPublic {
  const _$GiverPublicImpl(
      {@JsonKey(name: 'public_id') required this.publicId, required this.name});

  factory _$GiverPublicImpl.fromJson(Map<String, dynamic> json) =>
      _$$GiverPublicImplFromJson(json);

  @override
  @JsonKey(name: 'public_id')
  final String publicId;
  @override
  final String name;

  @override
  String toString() {
    return 'GiverPublic(publicId: $publicId, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GiverPublicImpl &&
            (identical(other.publicId, publicId) ||
                other.publicId == publicId) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, publicId, name);

  /// Create a copy of GiverPublic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GiverPublicImplCopyWith<_$GiverPublicImpl> get copyWith =>
      __$$GiverPublicImplCopyWithImpl<_$GiverPublicImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GiverPublicImplToJson(
      this,
    );
  }
}

abstract class _GiverPublic implements GiverPublic {
  const factory _GiverPublic(
      {@JsonKey(name: 'public_id') required final String publicId,
      required final String name}) = _$GiverPublicImpl;

  factory _GiverPublic.fromJson(Map<String, dynamic> json) =
      _$GiverPublicImpl.fromJson;

  @override
  @JsonKey(name: 'public_id')
  String get publicId;
  @override
  String get name;

  /// Create a copy of GiverPublic
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GiverPublicImplCopyWith<_$GiverPublicImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
