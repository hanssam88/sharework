// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ApplicationWorker _$ApplicationWorkerFromJson(Map<String, dynamic> json) {
  return _ApplicationWorker.fromJson(json);
}

/// @nodoc
mixin _$ApplicationWorker {
  @JsonKey(name: 'public_id')
  String? get publicId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;

  /// Serializes this ApplicationWorker to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApplicationWorker
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApplicationWorkerCopyWith<ApplicationWorker> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApplicationWorkerCopyWith<$Res> {
  factory $ApplicationWorkerCopyWith(
          ApplicationWorker value, $Res Function(ApplicationWorker) then) =
      _$ApplicationWorkerCopyWithImpl<$Res, ApplicationWorker>;
  @useResult
  $Res call(
      {@JsonKey(name: 'public_id') String? publicId,
      String name,
      String? phone});
}

/// @nodoc
class _$ApplicationWorkerCopyWithImpl<$Res, $Val extends ApplicationWorker>
    implements $ApplicationWorkerCopyWith<$Res> {
  _$ApplicationWorkerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApplicationWorker
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicId = freezed,
    Object? name = null,
    Object? phone = freezed,
  }) {
    return _then(_value.copyWith(
      publicId: freezed == publicId
          ? _value.publicId
          : publicId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApplicationWorkerImplCopyWith<$Res>
    implements $ApplicationWorkerCopyWith<$Res> {
  factory _$$ApplicationWorkerImplCopyWith(_$ApplicationWorkerImpl value,
          $Res Function(_$ApplicationWorkerImpl) then) =
      __$$ApplicationWorkerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'public_id') String? publicId,
      String name,
      String? phone});
}

/// @nodoc
class __$$ApplicationWorkerImplCopyWithImpl<$Res>
    extends _$ApplicationWorkerCopyWithImpl<$Res, _$ApplicationWorkerImpl>
    implements _$$ApplicationWorkerImplCopyWith<$Res> {
  __$$ApplicationWorkerImplCopyWithImpl(_$ApplicationWorkerImpl _value,
      $Res Function(_$ApplicationWorkerImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApplicationWorker
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicId = freezed,
    Object? name = null,
    Object? phone = freezed,
  }) {
    return _then(_$ApplicationWorkerImpl(
      publicId: freezed == publicId
          ? _value.publicId
          : publicId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApplicationWorkerImpl implements _ApplicationWorker {
  const _$ApplicationWorkerImpl(
      {@JsonKey(name: 'public_id') this.publicId,
      required this.name,
      this.phone});

  factory _$ApplicationWorkerImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApplicationWorkerImplFromJson(json);

  @override
  @JsonKey(name: 'public_id')
  final String? publicId;
  @override
  final String name;
  @override
  final String? phone;

  @override
  String toString() {
    return 'ApplicationWorker(publicId: $publicId, name: $name, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplicationWorkerImpl &&
            (identical(other.publicId, publicId) ||
                other.publicId == publicId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, publicId, name, phone);

  /// Create a copy of ApplicationWorker
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplicationWorkerImplCopyWith<_$ApplicationWorkerImpl> get copyWith =>
      __$$ApplicationWorkerImplCopyWithImpl<_$ApplicationWorkerImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApplicationWorkerImplToJson(
      this,
    );
  }
}

abstract class _ApplicationWorker implements ApplicationWorker {
  const factory _ApplicationWorker(
      {@JsonKey(name: 'public_id') final String? publicId,
      required final String name,
      final String? phone}) = _$ApplicationWorkerImpl;

  factory _ApplicationWorker.fromJson(Map<String, dynamic> json) =
      _$ApplicationWorkerImpl.fromJson;

  @override
  @JsonKey(name: 'public_id')
  String? get publicId;
  @override
  String get name;
  @override
  String? get phone;

  /// Create a copy of ApplicationWorker
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApplicationWorkerImplCopyWith<_$ApplicationWorkerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Application _$ApplicationFromJson(Map<String, dynamic> json) {
  return _Application.fromJson(json);
}

/// @nodoc
mixin _$Application {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'job_id')
  String get jobId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_note')
  String? get coverNote => throw _privateConstructorUsedError;
  @JsonKey(name: 'rejected_reason')
  String? get rejectedReason => throw _privateConstructorUsedError;
  @JsonKey(name: 'applied_at')
  String get appliedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'hired_at')
  String? get hiredAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'rejected_at')
  String? get rejectedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'withdrawn_at')
  String? get withdrawnAt => throw _privateConstructorUsedError;
  ApplicationWorker get worker => throw _privateConstructorUsedError;

  /// Serializes this Application to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Application
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApplicationCopyWith<Application> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApplicationCopyWith<$Res> {
  factory $ApplicationCopyWith(
          Application value, $Res Function(Application) then) =
      _$ApplicationCopyWithImpl<$Res, Application>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'job_id') String jobId,
      String status,
      @JsonKey(name: 'cover_note') String? coverNote,
      @JsonKey(name: 'rejected_reason') String? rejectedReason,
      @JsonKey(name: 'applied_at') String appliedAt,
      @JsonKey(name: 'hired_at') String? hiredAt,
      @JsonKey(name: 'rejected_at') String? rejectedAt,
      @JsonKey(name: 'withdrawn_at') String? withdrawnAt,
      ApplicationWorker worker});

  $ApplicationWorkerCopyWith<$Res> get worker;
}

/// @nodoc
class _$ApplicationCopyWithImpl<$Res, $Val extends Application>
    implements $ApplicationCopyWith<$Res> {
  _$ApplicationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Application
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? jobId = null,
    Object? status = null,
    Object? coverNote = freezed,
    Object? rejectedReason = freezed,
    Object? appliedAt = null,
    Object? hiredAt = freezed,
    Object? rejectedAt = freezed,
    Object? withdrawnAt = freezed,
    Object? worker = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      jobId: null == jobId
          ? _value.jobId
          : jobId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      coverNote: freezed == coverNote
          ? _value.coverNote
          : coverNote // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectedReason: freezed == rejectedReason
          ? _value.rejectedReason
          : rejectedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      appliedAt: null == appliedAt
          ? _value.appliedAt
          : appliedAt // ignore: cast_nullable_to_non_nullable
              as String,
      hiredAt: freezed == hiredAt
          ? _value.hiredAt
          : hiredAt // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectedAt: freezed == rejectedAt
          ? _value.rejectedAt
          : rejectedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      withdrawnAt: freezed == withdrawnAt
          ? _value.withdrawnAt
          : withdrawnAt // ignore: cast_nullable_to_non_nullable
              as String?,
      worker: null == worker
          ? _value.worker
          : worker // ignore: cast_nullable_to_non_nullable
              as ApplicationWorker,
    ) as $Val);
  }

  /// Create a copy of Application
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ApplicationWorkerCopyWith<$Res> get worker {
    return $ApplicationWorkerCopyWith<$Res>(_value.worker, (value) {
      return _then(_value.copyWith(worker: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ApplicationImplCopyWith<$Res>
    implements $ApplicationCopyWith<$Res> {
  factory _$$ApplicationImplCopyWith(
          _$ApplicationImpl value, $Res Function(_$ApplicationImpl) then) =
      __$$ApplicationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'job_id') String jobId,
      String status,
      @JsonKey(name: 'cover_note') String? coverNote,
      @JsonKey(name: 'rejected_reason') String? rejectedReason,
      @JsonKey(name: 'applied_at') String appliedAt,
      @JsonKey(name: 'hired_at') String? hiredAt,
      @JsonKey(name: 'rejected_at') String? rejectedAt,
      @JsonKey(name: 'withdrawn_at') String? withdrawnAt,
      ApplicationWorker worker});

  @override
  $ApplicationWorkerCopyWith<$Res> get worker;
}

/// @nodoc
class __$$ApplicationImplCopyWithImpl<$Res>
    extends _$ApplicationCopyWithImpl<$Res, _$ApplicationImpl>
    implements _$$ApplicationImplCopyWith<$Res> {
  __$$ApplicationImplCopyWithImpl(
      _$ApplicationImpl _value, $Res Function(_$ApplicationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Application
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? jobId = null,
    Object? status = null,
    Object? coverNote = freezed,
    Object? rejectedReason = freezed,
    Object? appliedAt = null,
    Object? hiredAt = freezed,
    Object? rejectedAt = freezed,
    Object? withdrawnAt = freezed,
    Object? worker = null,
  }) {
    return _then(_$ApplicationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      jobId: null == jobId
          ? _value.jobId
          : jobId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      coverNote: freezed == coverNote
          ? _value.coverNote
          : coverNote // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectedReason: freezed == rejectedReason
          ? _value.rejectedReason
          : rejectedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      appliedAt: null == appliedAt
          ? _value.appliedAt
          : appliedAt // ignore: cast_nullable_to_non_nullable
              as String,
      hiredAt: freezed == hiredAt
          ? _value.hiredAt
          : hiredAt // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectedAt: freezed == rejectedAt
          ? _value.rejectedAt
          : rejectedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      withdrawnAt: freezed == withdrawnAt
          ? _value.withdrawnAt
          : withdrawnAt // ignore: cast_nullable_to_non_nullable
              as String?,
      worker: null == worker
          ? _value.worker
          : worker // ignore: cast_nullable_to_non_nullable
              as ApplicationWorker,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApplicationImpl implements _Application {
  const _$ApplicationImpl(
      {required this.id,
      @JsonKey(name: 'job_id') required this.jobId,
      required this.status,
      @JsonKey(name: 'cover_note') this.coverNote,
      @JsonKey(name: 'rejected_reason') this.rejectedReason,
      @JsonKey(name: 'applied_at') required this.appliedAt,
      @JsonKey(name: 'hired_at') this.hiredAt,
      @JsonKey(name: 'rejected_at') this.rejectedAt,
      @JsonKey(name: 'withdrawn_at') this.withdrawnAt,
      required this.worker});

  factory _$ApplicationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApplicationImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'job_id')
  final String jobId;
  @override
  final String status;
  @override
  @JsonKey(name: 'cover_note')
  final String? coverNote;
  @override
  @JsonKey(name: 'rejected_reason')
  final String? rejectedReason;
  @override
  @JsonKey(name: 'applied_at')
  final String appliedAt;
  @override
  @JsonKey(name: 'hired_at')
  final String? hiredAt;
  @override
  @JsonKey(name: 'rejected_at')
  final String? rejectedAt;
  @override
  @JsonKey(name: 'withdrawn_at')
  final String? withdrawnAt;
  @override
  final ApplicationWorker worker;

  @override
  String toString() {
    return 'Application(id: $id, jobId: $jobId, status: $status, coverNote: $coverNote, rejectedReason: $rejectedReason, appliedAt: $appliedAt, hiredAt: $hiredAt, rejectedAt: $rejectedAt, withdrawnAt: $withdrawnAt, worker: $worker)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplicationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.jobId, jobId) || other.jobId == jobId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.coverNote, coverNote) ||
                other.coverNote == coverNote) &&
            (identical(other.rejectedReason, rejectedReason) ||
                other.rejectedReason == rejectedReason) &&
            (identical(other.appliedAt, appliedAt) ||
                other.appliedAt == appliedAt) &&
            (identical(other.hiredAt, hiredAt) || other.hiredAt == hiredAt) &&
            (identical(other.rejectedAt, rejectedAt) ||
                other.rejectedAt == rejectedAt) &&
            (identical(other.withdrawnAt, withdrawnAt) ||
                other.withdrawnAt == withdrawnAt) &&
            (identical(other.worker, worker) || other.worker == worker));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, jobId, status, coverNote,
      rejectedReason, appliedAt, hiredAt, rejectedAt, withdrawnAt, worker);

  /// Create a copy of Application
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplicationImplCopyWith<_$ApplicationImpl> get copyWith =>
      __$$ApplicationImplCopyWithImpl<_$ApplicationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApplicationImplToJson(
      this,
    );
  }
}

abstract class _Application implements Application {
  const factory _Application(
      {required final String id,
      @JsonKey(name: 'job_id') required final String jobId,
      required final String status,
      @JsonKey(name: 'cover_note') final String? coverNote,
      @JsonKey(name: 'rejected_reason') final String? rejectedReason,
      @JsonKey(name: 'applied_at') required final String appliedAt,
      @JsonKey(name: 'hired_at') final String? hiredAt,
      @JsonKey(name: 'rejected_at') final String? rejectedAt,
      @JsonKey(name: 'withdrawn_at') final String? withdrawnAt,
      required final ApplicationWorker worker}) = _$ApplicationImpl;

  factory _Application.fromJson(Map<String, dynamic> json) =
      _$ApplicationImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'job_id')
  String get jobId;
  @override
  String get status;
  @override
  @JsonKey(name: 'cover_note')
  String? get coverNote;
  @override
  @JsonKey(name: 'rejected_reason')
  String? get rejectedReason;
  @override
  @JsonKey(name: 'applied_at')
  String get appliedAt;
  @override
  @JsonKey(name: 'hired_at')
  String? get hiredAt;
  @override
  @JsonKey(name: 'rejected_at')
  String? get rejectedAt;
  @override
  @JsonKey(name: 'withdrawn_at')
  String? get withdrawnAt;
  @override
  ApplicationWorker get worker;

  /// Create a copy of Application
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApplicationImplCopyWith<_$ApplicationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ApplicationCounts _$ApplicationCountsFromJson(Map<String, dynamic> json) {
  return _ApplicationCounts.fromJson(json);
}

/// @nodoc
mixin _$ApplicationCounts {
  int get applied => throw _privateConstructorUsedError;
  int get hired => throw _privateConstructorUsedError;

  /// Serializes this ApplicationCounts to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApplicationCounts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApplicationCountsCopyWith<ApplicationCounts> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApplicationCountsCopyWith<$Res> {
  factory $ApplicationCountsCopyWith(
          ApplicationCounts value, $Res Function(ApplicationCounts) then) =
      _$ApplicationCountsCopyWithImpl<$Res, ApplicationCounts>;
  @useResult
  $Res call({int applied, int hired});
}

/// @nodoc
class _$ApplicationCountsCopyWithImpl<$Res, $Val extends ApplicationCounts>
    implements $ApplicationCountsCopyWith<$Res> {
  _$ApplicationCountsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApplicationCounts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? applied = null,
    Object? hired = null,
  }) {
    return _then(_value.copyWith(
      applied: null == applied
          ? _value.applied
          : applied // ignore: cast_nullable_to_non_nullable
              as int,
      hired: null == hired
          ? _value.hired
          : hired // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApplicationCountsImplCopyWith<$Res>
    implements $ApplicationCountsCopyWith<$Res> {
  factory _$$ApplicationCountsImplCopyWith(_$ApplicationCountsImpl value,
          $Res Function(_$ApplicationCountsImpl) then) =
      __$$ApplicationCountsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int applied, int hired});
}

/// @nodoc
class __$$ApplicationCountsImplCopyWithImpl<$Res>
    extends _$ApplicationCountsCopyWithImpl<$Res, _$ApplicationCountsImpl>
    implements _$$ApplicationCountsImplCopyWith<$Res> {
  __$$ApplicationCountsImplCopyWithImpl(_$ApplicationCountsImpl _value,
      $Res Function(_$ApplicationCountsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApplicationCounts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? applied = null,
    Object? hired = null,
  }) {
    return _then(_$ApplicationCountsImpl(
      applied: null == applied
          ? _value.applied
          : applied // ignore: cast_nullable_to_non_nullable
              as int,
      hired: null == hired
          ? _value.hired
          : hired // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApplicationCountsImpl implements _ApplicationCounts {
  const _$ApplicationCountsImpl({required this.applied, required this.hired});

  factory _$ApplicationCountsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApplicationCountsImplFromJson(json);

  @override
  final int applied;
  @override
  final int hired;

  @override
  String toString() {
    return 'ApplicationCounts(applied: $applied, hired: $hired)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplicationCountsImpl &&
            (identical(other.applied, applied) || other.applied == applied) &&
            (identical(other.hired, hired) || other.hired == hired));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, applied, hired);

  /// Create a copy of ApplicationCounts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplicationCountsImplCopyWith<_$ApplicationCountsImpl> get copyWith =>
      __$$ApplicationCountsImplCopyWithImpl<_$ApplicationCountsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApplicationCountsImplToJson(
      this,
    );
  }
}

abstract class _ApplicationCounts implements ApplicationCounts {
  const factory _ApplicationCounts(
      {required final int applied,
      required final int hired}) = _$ApplicationCountsImpl;

  factory _ApplicationCounts.fromJson(Map<String, dynamic> json) =
      _$ApplicationCountsImpl.fromJson;

  @override
  int get applied;
  @override
  int get hired;

  /// Create a copy of ApplicationCounts
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApplicationCountsImplCopyWith<_$ApplicationCountsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ApplicationListPage _$ApplicationListPageFromJson(Map<String, dynamic> json) {
  return _ApplicationListPage.fromJson(json);
}

/// @nodoc
mixin _$ApplicationListPage {
  List<Application> get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_more')
  bool get hasMore => throw _privateConstructorUsedError;
  @JsonKey(name: 'next_cursor')
  String? get nextCursor => throw _privateConstructorUsedError;
  ApplicationCounts get counts => throw _privateConstructorUsedError;

  /// Serializes this ApplicationListPage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApplicationListPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApplicationListPageCopyWith<ApplicationListPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApplicationListPageCopyWith<$Res> {
  factory $ApplicationListPageCopyWith(
          ApplicationListPage value, $Res Function(ApplicationListPage) then) =
      _$ApplicationListPageCopyWithImpl<$Res, ApplicationListPage>;
  @useResult
  $Res call(
      {List<Application> items,
      @JsonKey(name: 'has_more') bool hasMore,
      @JsonKey(name: 'next_cursor') String? nextCursor,
      ApplicationCounts counts});

  $ApplicationCountsCopyWith<$Res> get counts;
}

/// @nodoc
class _$ApplicationListPageCopyWithImpl<$Res, $Val extends ApplicationListPage>
    implements $ApplicationListPageCopyWith<$Res> {
  _$ApplicationListPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApplicationListPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? hasMore = null,
    Object? nextCursor = freezed,
    Object? counts = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Application>,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      nextCursor: freezed == nextCursor
          ? _value.nextCursor
          : nextCursor // ignore: cast_nullable_to_non_nullable
              as String?,
      counts: null == counts
          ? _value.counts
          : counts // ignore: cast_nullable_to_non_nullable
              as ApplicationCounts,
    ) as $Val);
  }

  /// Create a copy of ApplicationListPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ApplicationCountsCopyWith<$Res> get counts {
    return $ApplicationCountsCopyWith<$Res>(_value.counts, (value) {
      return _then(_value.copyWith(counts: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ApplicationListPageImplCopyWith<$Res>
    implements $ApplicationListPageCopyWith<$Res> {
  factory _$$ApplicationListPageImplCopyWith(_$ApplicationListPageImpl value,
          $Res Function(_$ApplicationListPageImpl) then) =
      __$$ApplicationListPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Application> items,
      @JsonKey(name: 'has_more') bool hasMore,
      @JsonKey(name: 'next_cursor') String? nextCursor,
      ApplicationCounts counts});

  @override
  $ApplicationCountsCopyWith<$Res> get counts;
}

/// @nodoc
class __$$ApplicationListPageImplCopyWithImpl<$Res>
    extends _$ApplicationListPageCopyWithImpl<$Res, _$ApplicationListPageImpl>
    implements _$$ApplicationListPageImplCopyWith<$Res> {
  __$$ApplicationListPageImplCopyWithImpl(_$ApplicationListPageImpl _value,
      $Res Function(_$ApplicationListPageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApplicationListPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? hasMore = null,
    Object? nextCursor = freezed,
    Object? counts = null,
  }) {
    return _then(_$ApplicationListPageImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Application>,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      nextCursor: freezed == nextCursor
          ? _value.nextCursor
          : nextCursor // ignore: cast_nullable_to_non_nullable
              as String?,
      counts: null == counts
          ? _value.counts
          : counts // ignore: cast_nullable_to_non_nullable
              as ApplicationCounts,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApplicationListPageImpl implements _ApplicationListPage {
  const _$ApplicationListPageImpl(
      {required final List<Application> items,
      @JsonKey(name: 'has_more') required this.hasMore,
      @JsonKey(name: 'next_cursor') this.nextCursor,
      required this.counts})
      : _items = items;

  factory _$ApplicationListPageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApplicationListPageImplFromJson(json);

  final List<Application> _items;
  @override
  List<Application> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey(name: 'has_more')
  final bool hasMore;
  @override
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;
  @override
  final ApplicationCounts counts;

  @override
  String toString() {
    return 'ApplicationListPage(items: $items, hasMore: $hasMore, nextCursor: $nextCursor, counts: $counts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplicationListPageImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.nextCursor, nextCursor) ||
                other.nextCursor == nextCursor) &&
            (identical(other.counts, counts) || other.counts == counts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), hasMore, nextCursor, counts);

  /// Create a copy of ApplicationListPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplicationListPageImplCopyWith<_$ApplicationListPageImpl> get copyWith =>
      __$$ApplicationListPageImplCopyWithImpl<_$ApplicationListPageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApplicationListPageImplToJson(
      this,
    );
  }
}

abstract class _ApplicationListPage implements ApplicationListPage {
  const factory _ApplicationListPage(
      {required final List<Application> items,
      @JsonKey(name: 'has_more') required final bool hasMore,
      @JsonKey(name: 'next_cursor') final String? nextCursor,
      required final ApplicationCounts counts}) = _$ApplicationListPageImpl;

  factory _ApplicationListPage.fromJson(Map<String, dynamic> json) =
      _$ApplicationListPageImpl.fromJson;

  @override
  List<Application> get items;
  @override
  @JsonKey(name: 'has_more')
  bool get hasMore;
  @override
  @JsonKey(name: 'next_cursor')
  String? get nextCursor;
  @override
  ApplicationCounts get counts;

  /// Create a copy of ApplicationListPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApplicationListPageImplCopyWith<_$ApplicationListPageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
