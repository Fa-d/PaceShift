// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'completed_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CompletedRun {

 int get id;/// Linked planned run, or null for an unplanned/extra run.
 int? get plannedRunId; DateTime get date; double get actualDistanceKm; int get durationSec;/// Average pace in seconds per km (computed at ingest).
 double get avgPaceSecPerKm; int? get avgHr; int? get maxHr; double? get calories; RunSource get source;/// What kind of activity this was. Defaults to [ActivityType.run] for
/// manually entered runs and pre-`activityType` rows.
 ActivityType get activityType;/// Health Connect record id, used to dedup repeated syncs.
 String? get externalId;
/// Create a copy of CompletedRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletedRunCopyWith<CompletedRun> get copyWith => _$CompletedRunCopyWithImpl<CompletedRun>(this as CompletedRun, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletedRun&&(identical(other.id, id) || other.id == id)&&(identical(other.plannedRunId, plannedRunId) || other.plannedRunId == plannedRunId)&&(identical(other.date, date) || other.date == date)&&(identical(other.actualDistanceKm, actualDistanceKm) || other.actualDistanceKm == actualDistanceKm)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.avgPaceSecPerKm, avgPaceSecPerKm) || other.avgPaceSecPerKm == avgPaceSecPerKm)&&(identical(other.avgHr, avgHr) || other.avgHr == avgHr)&&(identical(other.maxHr, maxHr) || other.maxHr == maxHr)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.source, source) || other.source == source)&&(identical(other.activityType, activityType) || other.activityType == activityType)&&(identical(other.externalId, externalId) || other.externalId == externalId));
}


@override
int get hashCode => Object.hash(runtimeType,id,plannedRunId,date,actualDistanceKm,durationSec,avgPaceSecPerKm,avgHr,maxHr,calories,source,activityType,externalId);

@override
String toString() {
  return 'CompletedRun(id: $id, plannedRunId: $plannedRunId, date: $date, actualDistanceKm: $actualDistanceKm, durationSec: $durationSec, avgPaceSecPerKm: $avgPaceSecPerKm, avgHr: $avgHr, maxHr: $maxHr, calories: $calories, source: $source, activityType: $activityType, externalId: $externalId)';
}


}

/// @nodoc
abstract mixin class $CompletedRunCopyWith<$Res>  {
  factory $CompletedRunCopyWith(CompletedRun value, $Res Function(CompletedRun) _then) = _$CompletedRunCopyWithImpl;
@useResult
$Res call({
 int id, int? plannedRunId, DateTime date, double actualDistanceKm, int durationSec, double avgPaceSecPerKm, int? avgHr, int? maxHr, double? calories, RunSource source, ActivityType activityType, String? externalId
});




}
/// @nodoc
class _$CompletedRunCopyWithImpl<$Res>
    implements $CompletedRunCopyWith<$Res> {
  _$CompletedRunCopyWithImpl(this._self, this._then);

  final CompletedRun _self;
  final $Res Function(CompletedRun) _then;

/// Create a copy of CompletedRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? plannedRunId = freezed,Object? date = null,Object? actualDistanceKm = null,Object? durationSec = null,Object? avgPaceSecPerKm = null,Object? avgHr = freezed,Object? maxHr = freezed,Object? calories = freezed,Object? source = null,Object? activityType = null,Object? externalId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,plannedRunId: freezed == plannedRunId ? _self.plannedRunId : plannedRunId // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,actualDistanceKm: null == actualDistanceKm ? _self.actualDistanceKm : actualDistanceKm // ignore: cast_nullable_to_non_nullable
as double,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,avgPaceSecPerKm: null == avgPaceSecPerKm ? _self.avgPaceSecPerKm : avgPaceSecPerKm // ignore: cast_nullable_to_non_nullable
as double,avgHr: freezed == avgHr ? _self.avgHr : avgHr // ignore: cast_nullable_to_non_nullable
as int?,maxHr: freezed == maxHr ? _self.maxHr : maxHr // ignore: cast_nullable_to_non_nullable
as int?,calories: freezed == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RunSource,activityType: null == activityType ? _self.activityType : activityType // ignore: cast_nullable_to_non_nullable
as ActivityType,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CompletedRun].
extension CompletedRunPatterns on CompletedRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompletedRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompletedRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompletedRun value)  $default,){
final _that = this;
switch (_that) {
case _CompletedRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompletedRun value)?  $default,){
final _that = this;
switch (_that) {
case _CompletedRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int? plannedRunId,  DateTime date,  double actualDistanceKm,  int durationSec,  double avgPaceSecPerKm,  int? avgHr,  int? maxHr,  double? calories,  RunSource source,  ActivityType activityType,  String? externalId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompletedRun() when $default != null:
return $default(_that.id,_that.plannedRunId,_that.date,_that.actualDistanceKm,_that.durationSec,_that.avgPaceSecPerKm,_that.avgHr,_that.maxHr,_that.calories,_that.source,_that.activityType,_that.externalId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int? plannedRunId,  DateTime date,  double actualDistanceKm,  int durationSec,  double avgPaceSecPerKm,  int? avgHr,  int? maxHr,  double? calories,  RunSource source,  ActivityType activityType,  String? externalId)  $default,) {final _that = this;
switch (_that) {
case _CompletedRun():
return $default(_that.id,_that.plannedRunId,_that.date,_that.actualDistanceKm,_that.durationSec,_that.avgPaceSecPerKm,_that.avgHr,_that.maxHr,_that.calories,_that.source,_that.activityType,_that.externalId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int? plannedRunId,  DateTime date,  double actualDistanceKm,  int durationSec,  double avgPaceSecPerKm,  int? avgHr,  int? maxHr,  double? calories,  RunSource source,  ActivityType activityType,  String? externalId)?  $default,) {final _that = this;
switch (_that) {
case _CompletedRun() when $default != null:
return $default(_that.id,_that.plannedRunId,_that.date,_that.actualDistanceKm,_that.durationSec,_that.avgPaceSecPerKm,_that.avgHr,_that.maxHr,_that.calories,_that.source,_that.activityType,_that.externalId);case _:
  return null;

}
}

}

/// @nodoc


class _CompletedRun extends CompletedRun {
  const _CompletedRun({required this.id, this.plannedRunId, required this.date, required this.actualDistanceKm, required this.durationSec, required this.avgPaceSecPerKm, this.avgHr, this.maxHr, this.calories, required this.source, this.activityType = ActivityType.run, this.externalId}): super._();
  

@override final  int id;
/// Linked planned run, or null for an unplanned/extra run.
@override final  int? plannedRunId;
@override final  DateTime date;
@override final  double actualDistanceKm;
@override final  int durationSec;
/// Average pace in seconds per km (computed at ingest).
@override final  double avgPaceSecPerKm;
@override final  int? avgHr;
@override final  int? maxHr;
@override final  double? calories;
@override final  RunSource source;
/// What kind of activity this was. Defaults to [ActivityType.run] for
/// manually entered runs and pre-`activityType` rows.
@override@JsonKey() final  ActivityType activityType;
/// Health Connect record id, used to dedup repeated syncs.
@override final  String? externalId;

/// Create a copy of CompletedRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompletedRunCopyWith<_CompletedRun> get copyWith => __$CompletedRunCopyWithImpl<_CompletedRun>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompletedRun&&(identical(other.id, id) || other.id == id)&&(identical(other.plannedRunId, plannedRunId) || other.plannedRunId == plannedRunId)&&(identical(other.date, date) || other.date == date)&&(identical(other.actualDistanceKm, actualDistanceKm) || other.actualDistanceKm == actualDistanceKm)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.avgPaceSecPerKm, avgPaceSecPerKm) || other.avgPaceSecPerKm == avgPaceSecPerKm)&&(identical(other.avgHr, avgHr) || other.avgHr == avgHr)&&(identical(other.maxHr, maxHr) || other.maxHr == maxHr)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.source, source) || other.source == source)&&(identical(other.activityType, activityType) || other.activityType == activityType)&&(identical(other.externalId, externalId) || other.externalId == externalId));
}


@override
int get hashCode => Object.hash(runtimeType,id,plannedRunId,date,actualDistanceKm,durationSec,avgPaceSecPerKm,avgHr,maxHr,calories,source,activityType,externalId);

@override
String toString() {
  return 'CompletedRun(id: $id, plannedRunId: $plannedRunId, date: $date, actualDistanceKm: $actualDistanceKm, durationSec: $durationSec, avgPaceSecPerKm: $avgPaceSecPerKm, avgHr: $avgHr, maxHr: $maxHr, calories: $calories, source: $source, activityType: $activityType, externalId: $externalId)';
}


}

/// @nodoc
abstract mixin class _$CompletedRunCopyWith<$Res> implements $CompletedRunCopyWith<$Res> {
  factory _$CompletedRunCopyWith(_CompletedRun value, $Res Function(_CompletedRun) _then) = __$CompletedRunCopyWithImpl;
@override @useResult
$Res call({
 int id, int? plannedRunId, DateTime date, double actualDistanceKm, int durationSec, double avgPaceSecPerKm, int? avgHr, int? maxHr, double? calories, RunSource source, ActivityType activityType, String? externalId
});




}
/// @nodoc
class __$CompletedRunCopyWithImpl<$Res>
    implements _$CompletedRunCopyWith<$Res> {
  __$CompletedRunCopyWithImpl(this._self, this._then);

  final _CompletedRun _self;
  final $Res Function(_CompletedRun) _then;

/// Create a copy of CompletedRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? plannedRunId = freezed,Object? date = null,Object? actualDistanceKm = null,Object? durationSec = null,Object? avgPaceSecPerKm = null,Object? avgHr = freezed,Object? maxHr = freezed,Object? calories = freezed,Object? source = null,Object? activityType = null,Object? externalId = freezed,}) {
  return _then(_CompletedRun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,plannedRunId: freezed == plannedRunId ? _self.plannedRunId : plannedRunId // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,actualDistanceKm: null == actualDistanceKm ? _self.actualDistanceKm : actualDistanceKm // ignore: cast_nullable_to_non_nullable
as double,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,avgPaceSecPerKm: null == avgPaceSecPerKm ? _self.avgPaceSecPerKm : avgPaceSecPerKm // ignore: cast_nullable_to_non_nullable
as double,avgHr: freezed == avgHr ? _self.avgHr : avgHr // ignore: cast_nullable_to_non_nullable
as int?,maxHr: freezed == maxHr ? _self.maxHr : maxHr // ignore: cast_nullable_to_non_nullable
as int?,calories: freezed == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RunSource,activityType: null == activityType ? _self.activityType : activityType // ignore: cast_nullable_to_non_nullable
as ActivityType,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
