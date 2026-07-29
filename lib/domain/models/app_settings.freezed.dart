// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

 UnitSystem get units;/// Morning reminder time, minutes since midnight (default 07:00).
 int get reminderMorningMinutes;/// Evening check-in time, minutes since midnight (default 20:00).
 int get reminderEveningMinutes; Aggressiveness get adaptivityAggressiveness;/// Days within which an ordinary missed run can still be made up.
 int get catchupWindowDays;/// Longer make-up window for long runs.
 int get longRunCatchupWindowDays; bool get cloudBackupEnabled;/// Display name captured during onboarding (empty = not provided).
 String get userName;/// Last successful health sync (null = never synced). Read-only here: the
/// sync repository owns the write, so a stale copy can't clobber it.
 DateTime? get lastSyncAt;/// When we last asked the user to connect health data (null = never asked).
/// Read-only here, for the same reason as [lastSyncAt].
 DateTime? get healthPromptedAt;/// When the engine raised a degrade decision the athlete hasn't answered
/// (null = nothing outstanding). Read-only here — the scheduler repository
/// owns the write.
 DateTime? get pendingDegradeSince;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.units, units) || other.units == units)&&(identical(other.reminderMorningMinutes, reminderMorningMinutes) || other.reminderMorningMinutes == reminderMorningMinutes)&&(identical(other.reminderEveningMinutes, reminderEveningMinutes) || other.reminderEveningMinutes == reminderEveningMinutes)&&(identical(other.adaptivityAggressiveness, adaptivityAggressiveness) || other.adaptivityAggressiveness == adaptivityAggressiveness)&&(identical(other.catchupWindowDays, catchupWindowDays) || other.catchupWindowDays == catchupWindowDays)&&(identical(other.longRunCatchupWindowDays, longRunCatchupWindowDays) || other.longRunCatchupWindowDays == longRunCatchupWindowDays)&&(identical(other.cloudBackupEnabled, cloudBackupEnabled) || other.cloudBackupEnabled == cloudBackupEnabled)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.healthPromptedAt, healthPromptedAt) || other.healthPromptedAt == healthPromptedAt)&&(identical(other.pendingDegradeSince, pendingDegradeSince) || other.pendingDegradeSince == pendingDegradeSince));
}


@override
int get hashCode => Object.hash(runtimeType,units,reminderMorningMinutes,reminderEveningMinutes,adaptivityAggressiveness,catchupWindowDays,longRunCatchupWindowDays,cloudBackupEnabled,userName,lastSyncAt,healthPromptedAt,pendingDegradeSince);

@override
String toString() {
  return 'AppSettings(units: $units, reminderMorningMinutes: $reminderMorningMinutes, reminderEveningMinutes: $reminderEveningMinutes, adaptivityAggressiveness: $adaptivityAggressiveness, catchupWindowDays: $catchupWindowDays, longRunCatchupWindowDays: $longRunCatchupWindowDays, cloudBackupEnabled: $cloudBackupEnabled, userName: $userName, lastSyncAt: $lastSyncAt, healthPromptedAt: $healthPromptedAt, pendingDegradeSince: $pendingDegradeSince)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 UnitSystem units, int reminderMorningMinutes, int reminderEveningMinutes, Aggressiveness adaptivityAggressiveness, int catchupWindowDays, int longRunCatchupWindowDays, bool cloudBackupEnabled, String userName, DateTime? lastSyncAt, DateTime? healthPromptedAt, DateTime? pendingDegradeSince
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? units = null,Object? reminderMorningMinutes = null,Object? reminderEveningMinutes = null,Object? adaptivityAggressiveness = null,Object? catchupWindowDays = null,Object? longRunCatchupWindowDays = null,Object? cloudBackupEnabled = null,Object? userName = null,Object? lastSyncAt = freezed,Object? healthPromptedAt = freezed,Object? pendingDegradeSince = freezed,}) {
  return _then(_self.copyWith(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as UnitSystem,reminderMorningMinutes: null == reminderMorningMinutes ? _self.reminderMorningMinutes : reminderMorningMinutes // ignore: cast_nullable_to_non_nullable
as int,reminderEveningMinutes: null == reminderEveningMinutes ? _self.reminderEveningMinutes : reminderEveningMinutes // ignore: cast_nullable_to_non_nullable
as int,adaptivityAggressiveness: null == adaptivityAggressiveness ? _self.adaptivityAggressiveness : adaptivityAggressiveness // ignore: cast_nullable_to_non_nullable
as Aggressiveness,catchupWindowDays: null == catchupWindowDays ? _self.catchupWindowDays : catchupWindowDays // ignore: cast_nullable_to_non_nullable
as int,longRunCatchupWindowDays: null == longRunCatchupWindowDays ? _self.longRunCatchupWindowDays : longRunCatchupWindowDays // ignore: cast_nullable_to_non_nullable
as int,cloudBackupEnabled: null == cloudBackupEnabled ? _self.cloudBackupEnabled : cloudBackupEnabled // ignore: cast_nullable_to_non_nullable
as bool,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,healthPromptedAt: freezed == healthPromptedAt ? _self.healthPromptedAt : healthPromptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pendingDegradeSince: freezed == pendingDegradeSince ? _self.pendingDegradeSince : pendingDegradeSince // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UnitSystem units,  int reminderMorningMinutes,  int reminderEveningMinutes,  Aggressiveness adaptivityAggressiveness,  int catchupWindowDays,  int longRunCatchupWindowDays,  bool cloudBackupEnabled,  String userName,  DateTime? lastSyncAt,  DateTime? healthPromptedAt,  DateTime? pendingDegradeSince)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.units,_that.reminderMorningMinutes,_that.reminderEveningMinutes,_that.adaptivityAggressiveness,_that.catchupWindowDays,_that.longRunCatchupWindowDays,_that.cloudBackupEnabled,_that.userName,_that.lastSyncAt,_that.healthPromptedAt,_that.pendingDegradeSince);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UnitSystem units,  int reminderMorningMinutes,  int reminderEveningMinutes,  Aggressiveness adaptivityAggressiveness,  int catchupWindowDays,  int longRunCatchupWindowDays,  bool cloudBackupEnabled,  String userName,  DateTime? lastSyncAt,  DateTime? healthPromptedAt,  DateTime? pendingDegradeSince)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.units,_that.reminderMorningMinutes,_that.reminderEveningMinutes,_that.adaptivityAggressiveness,_that.catchupWindowDays,_that.longRunCatchupWindowDays,_that.cloudBackupEnabled,_that.userName,_that.lastSyncAt,_that.healthPromptedAt,_that.pendingDegradeSince);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UnitSystem units,  int reminderMorningMinutes,  int reminderEveningMinutes,  Aggressiveness adaptivityAggressiveness,  int catchupWindowDays,  int longRunCatchupWindowDays,  bool cloudBackupEnabled,  String userName,  DateTime? lastSyncAt,  DateTime? healthPromptedAt,  DateTime? pendingDegradeSince)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.units,_that.reminderMorningMinutes,_that.reminderEveningMinutes,_that.adaptivityAggressiveness,_that.catchupWindowDays,_that.longRunCatchupWindowDays,_that.cloudBackupEnabled,_that.userName,_that.lastSyncAt,_that.healthPromptedAt,_that.pendingDegradeSince);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings extends AppSettings {
  const _AppSettings({this.units = UnitSystem.metric, this.reminderMorningMinutes = 7 * 60, this.reminderEveningMinutes = 20 * 60, this.adaptivityAggressiveness = Aggressiveness.balanced, this.catchupWindowDays = 7, this.longRunCatchupWindowDays = 10, this.cloudBackupEnabled = false, this.userName = '', this.lastSyncAt, this.healthPromptedAt, this.pendingDegradeSince}): super._();
  

@override@JsonKey() final  UnitSystem units;
/// Morning reminder time, minutes since midnight (default 07:00).
@override@JsonKey() final  int reminderMorningMinutes;
/// Evening check-in time, minutes since midnight (default 20:00).
@override@JsonKey() final  int reminderEveningMinutes;
@override@JsonKey() final  Aggressiveness adaptivityAggressiveness;
/// Days within which an ordinary missed run can still be made up.
@override@JsonKey() final  int catchupWindowDays;
/// Longer make-up window for long runs.
@override@JsonKey() final  int longRunCatchupWindowDays;
@override@JsonKey() final  bool cloudBackupEnabled;
/// Display name captured during onboarding (empty = not provided).
@override@JsonKey() final  String userName;
/// Last successful health sync (null = never synced). Read-only here: the
/// sync repository owns the write, so a stale copy can't clobber it.
@override final  DateTime? lastSyncAt;
/// When we last asked the user to connect health data (null = never asked).
/// Read-only here, for the same reason as [lastSyncAt].
@override final  DateTime? healthPromptedAt;
/// When the engine raised a degrade decision the athlete hasn't answered
/// (null = nothing outstanding). Read-only here — the scheduler repository
/// owns the write.
@override final  DateTime? pendingDegradeSince;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.units, units) || other.units == units)&&(identical(other.reminderMorningMinutes, reminderMorningMinutes) || other.reminderMorningMinutes == reminderMorningMinutes)&&(identical(other.reminderEveningMinutes, reminderEveningMinutes) || other.reminderEveningMinutes == reminderEveningMinutes)&&(identical(other.adaptivityAggressiveness, adaptivityAggressiveness) || other.adaptivityAggressiveness == adaptivityAggressiveness)&&(identical(other.catchupWindowDays, catchupWindowDays) || other.catchupWindowDays == catchupWindowDays)&&(identical(other.longRunCatchupWindowDays, longRunCatchupWindowDays) || other.longRunCatchupWindowDays == longRunCatchupWindowDays)&&(identical(other.cloudBackupEnabled, cloudBackupEnabled) || other.cloudBackupEnabled == cloudBackupEnabled)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.healthPromptedAt, healthPromptedAt) || other.healthPromptedAt == healthPromptedAt)&&(identical(other.pendingDegradeSince, pendingDegradeSince) || other.pendingDegradeSince == pendingDegradeSince));
}


@override
int get hashCode => Object.hash(runtimeType,units,reminderMorningMinutes,reminderEveningMinutes,adaptivityAggressiveness,catchupWindowDays,longRunCatchupWindowDays,cloudBackupEnabled,userName,lastSyncAt,healthPromptedAt,pendingDegradeSince);

@override
String toString() {
  return 'AppSettings(units: $units, reminderMorningMinutes: $reminderMorningMinutes, reminderEveningMinutes: $reminderEveningMinutes, adaptivityAggressiveness: $adaptivityAggressiveness, catchupWindowDays: $catchupWindowDays, longRunCatchupWindowDays: $longRunCatchupWindowDays, cloudBackupEnabled: $cloudBackupEnabled, userName: $userName, lastSyncAt: $lastSyncAt, healthPromptedAt: $healthPromptedAt, pendingDegradeSince: $pendingDegradeSince)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 UnitSystem units, int reminderMorningMinutes, int reminderEveningMinutes, Aggressiveness adaptivityAggressiveness, int catchupWindowDays, int longRunCatchupWindowDays, bool cloudBackupEnabled, String userName, DateTime? lastSyncAt, DateTime? healthPromptedAt, DateTime? pendingDegradeSince
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? units = null,Object? reminderMorningMinutes = null,Object? reminderEveningMinutes = null,Object? adaptivityAggressiveness = null,Object? catchupWindowDays = null,Object? longRunCatchupWindowDays = null,Object? cloudBackupEnabled = null,Object? userName = null,Object? lastSyncAt = freezed,Object? healthPromptedAt = freezed,Object? pendingDegradeSince = freezed,}) {
  return _then(_AppSettings(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as UnitSystem,reminderMorningMinutes: null == reminderMorningMinutes ? _self.reminderMorningMinutes : reminderMorningMinutes // ignore: cast_nullable_to_non_nullable
as int,reminderEveningMinutes: null == reminderEveningMinutes ? _self.reminderEveningMinutes : reminderEveningMinutes // ignore: cast_nullable_to_non_nullable
as int,adaptivityAggressiveness: null == adaptivityAggressiveness ? _self.adaptivityAggressiveness : adaptivityAggressiveness // ignore: cast_nullable_to_non_nullable
as Aggressiveness,catchupWindowDays: null == catchupWindowDays ? _self.catchupWindowDays : catchupWindowDays // ignore: cast_nullable_to_non_nullable
as int,longRunCatchupWindowDays: null == longRunCatchupWindowDays ? _self.longRunCatchupWindowDays : longRunCatchupWindowDays // ignore: cast_nullable_to_non_nullable
as int,cloudBackupEnabled: null == cloudBackupEnabled ? _self.cloudBackupEnabled : cloudBackupEnabled // ignore: cast_nullable_to_non_nullable
as bool,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,healthPromptedAt: freezed == healthPromptedAt ? _self.healthPromptedAt : healthPromptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pendingDegradeSince: freezed == pendingDegradeSince ? _self.pendingDegradeSince : pendingDegradeSince // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
