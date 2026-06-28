// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planned_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlannedRun {

 int get id; int get planId;/// Current scheduled date (mutable — the engine reschedules this).
 DateTime get scheduledDate;/// Where the run originally sat — for showing original → new moves.
 DateTime get originalDate;/// 1-based training week index.
 int get weekIndex; RunType get type;/// Target distance in km. Null for rest/strength.
 double? get targetDistanceKm;/// Optional target duration in minutes.
 int? get targetDurationMin;/// Optional run/walk ratio, e.g. "4:1" (run 4 / walk 1).
 String? get runWalkRatio;/// Target average pace for the whole session, seconds per km (null = by feel).
 double? get targetPaceSecPerKm;/// Structured breakdown for quality sessions (intervals/tempo). Null for
/// simple continuous runs.
 List<WorkoutSegment>? get segments; RunStatus get status; String? get notes;
/// Create a copy of PlannedRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannedRunCopyWith<PlannedRun> get copyWith => _$PlannedRunCopyWithImpl<PlannedRun>(this as PlannedRun, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedRun&&(identical(other.id, id) || other.id == id)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.originalDate, originalDate) || other.originalDate == originalDate)&&(identical(other.weekIndex, weekIndex) || other.weekIndex == weekIndex)&&(identical(other.type, type) || other.type == type)&&(identical(other.targetDistanceKm, targetDistanceKm) || other.targetDistanceKm == targetDistanceKm)&&(identical(other.targetDurationMin, targetDurationMin) || other.targetDurationMin == targetDurationMin)&&(identical(other.runWalkRatio, runWalkRatio) || other.runWalkRatio == runWalkRatio)&&(identical(other.targetPaceSecPerKm, targetPaceSecPerKm) || other.targetPaceSecPerKm == targetPaceSecPerKm)&&const DeepCollectionEquality().equals(other.segments, segments)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,planId,scheduledDate,originalDate,weekIndex,type,targetDistanceKm,targetDurationMin,runWalkRatio,targetPaceSecPerKm,const DeepCollectionEquality().hash(segments),status,notes);

@override
String toString() {
  return 'PlannedRun(id: $id, planId: $planId, scheduledDate: $scheduledDate, originalDate: $originalDate, weekIndex: $weekIndex, type: $type, targetDistanceKm: $targetDistanceKm, targetDurationMin: $targetDurationMin, runWalkRatio: $runWalkRatio, targetPaceSecPerKm: $targetPaceSecPerKm, segments: $segments, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $PlannedRunCopyWith<$Res>  {
  factory $PlannedRunCopyWith(PlannedRun value, $Res Function(PlannedRun) _then) = _$PlannedRunCopyWithImpl;
@useResult
$Res call({
 int id, int planId, DateTime scheduledDate, DateTime originalDate, int weekIndex, RunType type, double? targetDistanceKm, int? targetDurationMin, String? runWalkRatio, double? targetPaceSecPerKm, List<WorkoutSegment>? segments, RunStatus status, String? notes
});




}
/// @nodoc
class _$PlannedRunCopyWithImpl<$Res>
    implements $PlannedRunCopyWith<$Res> {
  _$PlannedRunCopyWithImpl(this._self, this._then);

  final PlannedRun _self;
  final $Res Function(PlannedRun) _then;

/// Create a copy of PlannedRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? planId = null,Object? scheduledDate = null,Object? originalDate = null,Object? weekIndex = null,Object? type = null,Object? targetDistanceKm = freezed,Object? targetDurationMin = freezed,Object? runWalkRatio = freezed,Object? targetPaceSecPerKm = freezed,Object? segments = freezed,Object? status = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as int,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime,originalDate: null == originalDate ? _self.originalDate : originalDate // ignore: cast_nullable_to_non_nullable
as DateTime,weekIndex: null == weekIndex ? _self.weekIndex : weekIndex // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RunType,targetDistanceKm: freezed == targetDistanceKm ? _self.targetDistanceKm : targetDistanceKm // ignore: cast_nullable_to_non_nullable
as double?,targetDurationMin: freezed == targetDurationMin ? _self.targetDurationMin : targetDurationMin // ignore: cast_nullable_to_non_nullable
as int?,runWalkRatio: freezed == runWalkRatio ? _self.runWalkRatio : runWalkRatio // ignore: cast_nullable_to_non_nullable
as String?,targetPaceSecPerKm: freezed == targetPaceSecPerKm ? _self.targetPaceSecPerKm : targetPaceSecPerKm // ignore: cast_nullable_to_non_nullable
as double?,segments: freezed == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as List<WorkoutSegment>?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RunStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlannedRun].
extension PlannedRunPatterns on PlannedRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlannedRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlannedRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlannedRun value)  $default,){
final _that = this;
switch (_that) {
case _PlannedRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlannedRun value)?  $default,){
final _that = this;
switch (_that) {
case _PlannedRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int planId,  DateTime scheduledDate,  DateTime originalDate,  int weekIndex,  RunType type,  double? targetDistanceKm,  int? targetDurationMin,  String? runWalkRatio,  double? targetPaceSecPerKm,  List<WorkoutSegment>? segments,  RunStatus status,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlannedRun() when $default != null:
return $default(_that.id,_that.planId,_that.scheduledDate,_that.originalDate,_that.weekIndex,_that.type,_that.targetDistanceKm,_that.targetDurationMin,_that.runWalkRatio,_that.targetPaceSecPerKm,_that.segments,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int planId,  DateTime scheduledDate,  DateTime originalDate,  int weekIndex,  RunType type,  double? targetDistanceKm,  int? targetDurationMin,  String? runWalkRatio,  double? targetPaceSecPerKm,  List<WorkoutSegment>? segments,  RunStatus status,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _PlannedRun():
return $default(_that.id,_that.planId,_that.scheduledDate,_that.originalDate,_that.weekIndex,_that.type,_that.targetDistanceKm,_that.targetDurationMin,_that.runWalkRatio,_that.targetPaceSecPerKm,_that.segments,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int planId,  DateTime scheduledDate,  DateTime originalDate,  int weekIndex,  RunType type,  double? targetDistanceKm,  int? targetDurationMin,  String? runWalkRatio,  double? targetPaceSecPerKm,  List<WorkoutSegment>? segments,  RunStatus status,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _PlannedRun() when $default != null:
return $default(_that.id,_that.planId,_that.scheduledDate,_that.originalDate,_that.weekIndex,_that.type,_that.targetDistanceKm,_that.targetDurationMin,_that.runWalkRatio,_that.targetPaceSecPerKm,_that.segments,_that.status,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _PlannedRun extends PlannedRun {
  const _PlannedRun({required this.id, required this.planId, required this.scheduledDate, required this.originalDate, required this.weekIndex, required this.type, this.targetDistanceKm, this.targetDurationMin, this.runWalkRatio, this.targetPaceSecPerKm, final  List<WorkoutSegment>? segments, required this.status, this.notes}): _segments = segments,super._();
  

@override final  int id;
@override final  int planId;
/// Current scheduled date (mutable — the engine reschedules this).
@override final  DateTime scheduledDate;
/// Where the run originally sat — for showing original → new moves.
@override final  DateTime originalDate;
/// 1-based training week index.
@override final  int weekIndex;
@override final  RunType type;
/// Target distance in km. Null for rest/strength.
@override final  double? targetDistanceKm;
/// Optional target duration in minutes.
@override final  int? targetDurationMin;
/// Optional run/walk ratio, e.g. "4:1" (run 4 / walk 1).
@override final  String? runWalkRatio;
/// Target average pace for the whole session, seconds per km (null = by feel).
@override final  double? targetPaceSecPerKm;
/// Structured breakdown for quality sessions (intervals/tempo). Null for
/// simple continuous runs.
 final  List<WorkoutSegment>? _segments;
/// Structured breakdown for quality sessions (intervals/tempo). Null for
/// simple continuous runs.
@override List<WorkoutSegment>? get segments {
  final value = _segments;
  if (value == null) return null;
  if (_segments is EqualUnmodifiableListView) return _segments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  RunStatus status;
@override final  String? notes;

/// Create a copy of PlannedRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlannedRunCopyWith<_PlannedRun> get copyWith => __$PlannedRunCopyWithImpl<_PlannedRun>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlannedRun&&(identical(other.id, id) || other.id == id)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.originalDate, originalDate) || other.originalDate == originalDate)&&(identical(other.weekIndex, weekIndex) || other.weekIndex == weekIndex)&&(identical(other.type, type) || other.type == type)&&(identical(other.targetDistanceKm, targetDistanceKm) || other.targetDistanceKm == targetDistanceKm)&&(identical(other.targetDurationMin, targetDurationMin) || other.targetDurationMin == targetDurationMin)&&(identical(other.runWalkRatio, runWalkRatio) || other.runWalkRatio == runWalkRatio)&&(identical(other.targetPaceSecPerKm, targetPaceSecPerKm) || other.targetPaceSecPerKm == targetPaceSecPerKm)&&const DeepCollectionEquality().equals(other._segments, _segments)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,id,planId,scheduledDate,originalDate,weekIndex,type,targetDistanceKm,targetDurationMin,runWalkRatio,targetPaceSecPerKm,const DeepCollectionEquality().hash(_segments),status,notes);

@override
String toString() {
  return 'PlannedRun(id: $id, planId: $planId, scheduledDate: $scheduledDate, originalDate: $originalDate, weekIndex: $weekIndex, type: $type, targetDistanceKm: $targetDistanceKm, targetDurationMin: $targetDurationMin, runWalkRatio: $runWalkRatio, targetPaceSecPerKm: $targetPaceSecPerKm, segments: $segments, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$PlannedRunCopyWith<$Res> implements $PlannedRunCopyWith<$Res> {
  factory _$PlannedRunCopyWith(_PlannedRun value, $Res Function(_PlannedRun) _then) = __$PlannedRunCopyWithImpl;
@override @useResult
$Res call({
 int id, int planId, DateTime scheduledDate, DateTime originalDate, int weekIndex, RunType type, double? targetDistanceKm, int? targetDurationMin, String? runWalkRatio, double? targetPaceSecPerKm, List<WorkoutSegment>? segments, RunStatus status, String? notes
});




}
/// @nodoc
class __$PlannedRunCopyWithImpl<$Res>
    implements _$PlannedRunCopyWith<$Res> {
  __$PlannedRunCopyWithImpl(this._self, this._then);

  final _PlannedRun _self;
  final $Res Function(_PlannedRun) _then;

/// Create a copy of PlannedRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? planId = null,Object? scheduledDate = null,Object? originalDate = null,Object? weekIndex = null,Object? type = null,Object? targetDistanceKm = freezed,Object? targetDurationMin = freezed,Object? runWalkRatio = freezed,Object? targetPaceSecPerKm = freezed,Object? segments = freezed,Object? status = null,Object? notes = freezed,}) {
  return _then(_PlannedRun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as int,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime,originalDate: null == originalDate ? _self.originalDate : originalDate // ignore: cast_nullable_to_non_nullable
as DateTime,weekIndex: null == weekIndex ? _self.weekIndex : weekIndex // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RunType,targetDistanceKm: freezed == targetDistanceKm ? _self.targetDistanceKm : targetDistanceKm // ignore: cast_nullable_to_non_nullable
as double?,targetDurationMin: freezed == targetDurationMin ? _self.targetDurationMin : targetDurationMin // ignore: cast_nullable_to_non_nullable
as int?,runWalkRatio: freezed == runWalkRatio ? _self.runWalkRatio : runWalkRatio // ignore: cast_nullable_to_non_nullable
as String?,targetPaceSecPerKm: freezed == targetPaceSecPerKm ? _self.targetPaceSecPerKm : targetPaceSecPerKm // ignore: cast_nullable_to_non_nullable
as double?,segments: freezed == segments ? _self._segments : segments // ignore: cast_nullable_to_non_nullable
as List<WorkoutSegment>?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RunStatus,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
