// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_segment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkoutSegment {

 SegmentKind get kind; int get reps; double? get distanceKm; int? get durationSec;/// Target pace for this block, seconds per km (null = easy/by-feel).
 double? get targetPaceSecPerKm; String? get label;
/// Create a copy of WorkoutSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutSegmentCopyWith<WorkoutSegment> get copyWith => _$WorkoutSegmentCopyWithImpl<WorkoutSegment>(this as WorkoutSegment, _$identity);

  /// Serializes this WorkoutSegment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutSegment&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.targetPaceSecPerKm, targetPaceSecPerKm) || other.targetPaceSecPerKm == targetPaceSecPerKm)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,reps,distanceKm,durationSec,targetPaceSecPerKm,label);

@override
String toString() {
  return 'WorkoutSegment(kind: $kind, reps: $reps, distanceKm: $distanceKm, durationSec: $durationSec, targetPaceSecPerKm: $targetPaceSecPerKm, label: $label)';
}


}

/// @nodoc
abstract mixin class $WorkoutSegmentCopyWith<$Res>  {
  factory $WorkoutSegmentCopyWith(WorkoutSegment value, $Res Function(WorkoutSegment) _then) = _$WorkoutSegmentCopyWithImpl;
@useResult
$Res call({
 SegmentKind kind, int reps, double? distanceKm, int? durationSec, double? targetPaceSecPerKm, String? label
});




}
/// @nodoc
class _$WorkoutSegmentCopyWithImpl<$Res>
    implements $WorkoutSegmentCopyWith<$Res> {
  _$WorkoutSegmentCopyWithImpl(this._self, this._then);

  final WorkoutSegment _self;
  final $Res Function(WorkoutSegment) _then;

/// Create a copy of WorkoutSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? reps = null,Object? distanceKm = freezed,Object? durationSec = freezed,Object? targetPaceSecPerKm = freezed,Object? label = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SegmentKind,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,targetPaceSecPerKm: freezed == targetPaceSecPerKm ? _self.targetPaceSecPerKm : targetPaceSecPerKm // ignore: cast_nullable_to_non_nullable
as double?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutSegment].
extension WorkoutSegmentPatterns on WorkoutSegment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutSegment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutSegment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutSegment value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutSegment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutSegment value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutSegment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SegmentKind kind,  int reps,  double? distanceKm,  int? durationSec,  double? targetPaceSecPerKm,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutSegment() when $default != null:
return $default(_that.kind,_that.reps,_that.distanceKm,_that.durationSec,_that.targetPaceSecPerKm,_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SegmentKind kind,  int reps,  double? distanceKm,  int? durationSec,  double? targetPaceSecPerKm,  String? label)  $default,) {final _that = this;
switch (_that) {
case _WorkoutSegment():
return $default(_that.kind,_that.reps,_that.distanceKm,_that.durationSec,_that.targetPaceSecPerKm,_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SegmentKind kind,  int reps,  double? distanceKm,  int? durationSec,  double? targetPaceSecPerKm,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutSegment() when $default != null:
return $default(_that.kind,_that.reps,_that.distanceKm,_that.durationSec,_that.targetPaceSecPerKm,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutSegment extends WorkoutSegment {
  const _WorkoutSegment({required this.kind, this.reps = 1, this.distanceKm, this.durationSec, this.targetPaceSecPerKm, this.label}): super._();
  factory _WorkoutSegment.fromJson(Map<String, dynamic> json) => _$WorkoutSegmentFromJson(json);

@override final  SegmentKind kind;
@override@JsonKey() final  int reps;
@override final  double? distanceKm;
@override final  int? durationSec;
/// Target pace for this block, seconds per km (null = easy/by-feel).
@override final  double? targetPaceSecPerKm;
@override final  String? label;

/// Create a copy of WorkoutSegment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutSegmentCopyWith<_WorkoutSegment> get copyWith => __$WorkoutSegmentCopyWithImpl<_WorkoutSegment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutSegmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutSegment&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.targetPaceSecPerKm, targetPaceSecPerKm) || other.targetPaceSecPerKm == targetPaceSecPerKm)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,reps,distanceKm,durationSec,targetPaceSecPerKm,label);

@override
String toString() {
  return 'WorkoutSegment(kind: $kind, reps: $reps, distanceKm: $distanceKm, durationSec: $durationSec, targetPaceSecPerKm: $targetPaceSecPerKm, label: $label)';
}


}

/// @nodoc
abstract mixin class _$WorkoutSegmentCopyWith<$Res> implements $WorkoutSegmentCopyWith<$Res> {
  factory _$WorkoutSegmentCopyWith(_WorkoutSegment value, $Res Function(_WorkoutSegment) _then) = __$WorkoutSegmentCopyWithImpl;
@override @useResult
$Res call({
 SegmentKind kind, int reps, double? distanceKm, int? durationSec, double? targetPaceSecPerKm, String? label
});




}
/// @nodoc
class __$WorkoutSegmentCopyWithImpl<$Res>
    implements _$WorkoutSegmentCopyWith<$Res> {
  __$WorkoutSegmentCopyWithImpl(this._self, this._then);

  final _WorkoutSegment _self;
  final $Res Function(_WorkoutSegment) _then;

/// Create a copy of WorkoutSegment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? reps = null,Object? distanceKm = freezed,Object? durationSec = freezed,Object? targetPaceSecPerKm = freezed,Object? label = freezed,}) {
  return _then(_WorkoutSegment(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SegmentKind,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,targetPaceSecPerKm: freezed == targetPaceSecPerKm ? _self.targetPaceSecPerKm : targetPaceSecPerKm // ignore: cast_nullable_to_non_nullable
as double?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
