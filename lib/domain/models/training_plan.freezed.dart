// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrainingPlan {

 int get id; String get name; DateTime get raceDate; double get raceDistanceKm; DateTime get startDate;/// Preferred weekday for long runs, Mon=1 … Sun=7.
 int get longRunDay; PlanStatus get status; DateTime get createdAt;/// Number of taper weeks at the end of the plan (sacred — see engine §4.3).
 int get taperWeeks;
/// Create a copy of TrainingPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingPlanCopyWith<TrainingPlan> get copyWith => _$TrainingPlanCopyWithImpl<TrainingPlan>(this as TrainingPlan, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.raceDate, raceDate) || other.raceDate == raceDate)&&(identical(other.raceDistanceKm, raceDistanceKm) || other.raceDistanceKm == raceDistanceKm)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.longRunDay, longRunDay) || other.longRunDay == longRunDay)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.taperWeeks, taperWeeks) || other.taperWeeks == taperWeeks));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,raceDate,raceDistanceKm,startDate,longRunDay,status,createdAt,taperWeeks);

@override
String toString() {
  return 'TrainingPlan(id: $id, name: $name, raceDate: $raceDate, raceDistanceKm: $raceDistanceKm, startDate: $startDate, longRunDay: $longRunDay, status: $status, createdAt: $createdAt, taperWeeks: $taperWeeks)';
}


}

/// @nodoc
abstract mixin class $TrainingPlanCopyWith<$Res>  {
  factory $TrainingPlanCopyWith(TrainingPlan value, $Res Function(TrainingPlan) _then) = _$TrainingPlanCopyWithImpl;
@useResult
$Res call({
 int id, String name, DateTime raceDate, double raceDistanceKm, DateTime startDate, int longRunDay, PlanStatus status, DateTime createdAt, int taperWeeks
});




}
/// @nodoc
class _$TrainingPlanCopyWithImpl<$Res>
    implements $TrainingPlanCopyWith<$Res> {
  _$TrainingPlanCopyWithImpl(this._self, this._then);

  final TrainingPlan _self;
  final $Res Function(TrainingPlan) _then;

/// Create a copy of TrainingPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? raceDate = null,Object? raceDistanceKm = null,Object? startDate = null,Object? longRunDay = null,Object? status = null,Object? createdAt = null,Object? taperWeeks = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,raceDate: null == raceDate ? _self.raceDate : raceDate // ignore: cast_nullable_to_non_nullable
as DateTime,raceDistanceKm: null == raceDistanceKm ? _self.raceDistanceKm : raceDistanceKm // ignore: cast_nullable_to_non_nullable
as double,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,longRunDay: null == longRunDay ? _self.longRunDay : longRunDay // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,taperWeeks: null == taperWeeks ? _self.taperWeeks : taperWeeks // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TrainingPlan].
extension TrainingPlanPatterns on TrainingPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingPlan value)  $default,){
final _that = this;
switch (_that) {
case _TrainingPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingPlan value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  DateTime raceDate,  double raceDistanceKm,  DateTime startDate,  int longRunDay,  PlanStatus status,  DateTime createdAt,  int taperWeeks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingPlan() when $default != null:
return $default(_that.id,_that.name,_that.raceDate,_that.raceDistanceKm,_that.startDate,_that.longRunDay,_that.status,_that.createdAt,_that.taperWeeks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  DateTime raceDate,  double raceDistanceKm,  DateTime startDate,  int longRunDay,  PlanStatus status,  DateTime createdAt,  int taperWeeks)  $default,) {final _that = this;
switch (_that) {
case _TrainingPlan():
return $default(_that.id,_that.name,_that.raceDate,_that.raceDistanceKm,_that.startDate,_that.longRunDay,_that.status,_that.createdAt,_that.taperWeeks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  DateTime raceDate,  double raceDistanceKm,  DateTime startDate,  int longRunDay,  PlanStatus status,  DateTime createdAt,  int taperWeeks)?  $default,) {final _that = this;
switch (_that) {
case _TrainingPlan() when $default != null:
return $default(_that.id,_that.name,_that.raceDate,_that.raceDistanceKm,_that.startDate,_that.longRunDay,_that.status,_that.createdAt,_that.taperWeeks);case _:
  return null;

}
}

}

/// @nodoc


class _TrainingPlan extends TrainingPlan {
  const _TrainingPlan({required this.id, required this.name, required this.raceDate, required this.raceDistanceKm, required this.startDate, required this.longRunDay, required this.status, required this.createdAt, this.taperWeeks = 3}): super._();
  

@override final  int id;
@override final  String name;
@override final  DateTime raceDate;
@override final  double raceDistanceKm;
@override final  DateTime startDate;
/// Preferred weekday for long runs, Mon=1 … Sun=7.
@override final  int longRunDay;
@override final  PlanStatus status;
@override final  DateTime createdAt;
/// Number of taper weeks at the end of the plan (sacred — see engine §4.3).
@override@JsonKey() final  int taperWeeks;

/// Create a copy of TrainingPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingPlanCopyWith<_TrainingPlan> get copyWith => __$TrainingPlanCopyWithImpl<_TrainingPlan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.raceDate, raceDate) || other.raceDate == raceDate)&&(identical(other.raceDistanceKm, raceDistanceKm) || other.raceDistanceKm == raceDistanceKm)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.longRunDay, longRunDay) || other.longRunDay == longRunDay)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.taperWeeks, taperWeeks) || other.taperWeeks == taperWeeks));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,raceDate,raceDistanceKm,startDate,longRunDay,status,createdAt,taperWeeks);

@override
String toString() {
  return 'TrainingPlan(id: $id, name: $name, raceDate: $raceDate, raceDistanceKm: $raceDistanceKm, startDate: $startDate, longRunDay: $longRunDay, status: $status, createdAt: $createdAt, taperWeeks: $taperWeeks)';
}


}

/// @nodoc
abstract mixin class _$TrainingPlanCopyWith<$Res> implements $TrainingPlanCopyWith<$Res> {
  factory _$TrainingPlanCopyWith(_TrainingPlan value, $Res Function(_TrainingPlan) _then) = __$TrainingPlanCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, DateTime raceDate, double raceDistanceKm, DateTime startDate, int longRunDay, PlanStatus status, DateTime createdAt, int taperWeeks
});




}
/// @nodoc
class __$TrainingPlanCopyWithImpl<$Res>
    implements _$TrainingPlanCopyWith<$Res> {
  __$TrainingPlanCopyWithImpl(this._self, this._then);

  final _TrainingPlan _self;
  final $Res Function(_TrainingPlan) _then;

/// Create a copy of TrainingPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? raceDate = null,Object? raceDistanceKm = null,Object? startDate = null,Object? longRunDay = null,Object? status = null,Object? createdAt = null,Object? taperWeeks = null,}) {
  return _then(_TrainingPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,raceDate: null == raceDate ? _self.raceDate : raceDate // ignore: cast_nullable_to_non_nullable
as DateTime,raceDistanceKm: null == raceDistanceKm ? _self.raceDistanceKm : raceDistanceKm // ignore: cast_nullable_to_non_nullable
as double,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,longRunDay: null == longRunDay ? _self.longRunDay : longRunDay // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,taperWeeks: null == taperWeeks ? _self.taperWeeks : taperWeeks // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
