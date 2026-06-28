import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/date_utils.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/completed_run.dart';
import '../../domain/models/planned_run.dart';
import '../../domain/models/training_plan.dart';
import '../../domain/models/workout_segment.dart';
import 'app_database.dart';

/// Encodes/decodes structured workout segments to the DB's JSON text column.
String? _encodeSegments(List<WorkoutSegment>? segments) =>
    (segments == null || segments.isEmpty)
        ? null
        : jsonEncode(segments.map((s) => s.toJson()).toList());

List<WorkoutSegment>? _decodeSegments(String? json) {
  if (json == null || json.isEmpty) return null;
  final list = jsonDecode(json) as List<dynamic>;
  return list
      .map((e) => WorkoutSegment.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Conversions between Drift row data classes and pure domain models.
///
/// Dates are normalised to local midnight on the way out so domain/engine code
/// always works with clean calendar dates.

extension TrainingPlanRowMapper on TrainingPlanRow {
  TrainingPlan toDomain() => TrainingPlan(
        id: id,
        name: name,
        raceDate: dateOnly(raceDate),
        raceDistanceKm: raceDistanceKm,
        startDate: dateOnly(startDate),
        longRunDay: longRunDay,
        status: status,
        taperWeeks: taperWeeks,
        createdAt: createdAt,
      );
}

extension TrainingPlanToCompanion on TrainingPlan {
  TrainingPlansCompanion toCompanion({bool withId = false}) =>
      TrainingPlansCompanion(
        id: withId ? Value(id) : const Value.absent(),
        name: Value(name),
        raceDate: Value(dateOnly(raceDate)),
        raceDistanceKm: Value(raceDistanceKm),
        startDate: Value(dateOnly(startDate)),
        longRunDay: Value(longRunDay),
        status: Value(status),
        taperWeeks: Value(taperWeeks),
        createdAt: Value(createdAt),
      );
}

extension PlannedRunRowMapper on PlannedRunRow {
  PlannedRun toDomain() => PlannedRun(
        id: id,
        planId: planId,
        scheduledDate: dateOnly(scheduledDate),
        originalDate: dateOnly(originalDate),
        weekIndex: weekIndex,
        type: type,
        targetDistanceKm: targetDistanceKm,
        targetDurationMin: targetDurationMin,
        runWalkRatio: runWalkRatio,
        targetPaceSecPerKm: targetPaceSecPerKm,
        segments: _decodeSegments(segmentsJson),
        status: status,
        notes: notes,
      );
}

extension PlannedRunToCompanion on PlannedRun {
  /// Full companion for inserts. Omits id unless [withId] (engine-applied updates
  /// usually target by id separately).
  PlannedRunsCompanion toCompanion({bool withId = false}) => PlannedRunsCompanion(
        id: withId ? Value(id) : const Value.absent(),
        planId: Value(planId),
        scheduledDate: Value(dateOnly(scheduledDate)),
        originalDate: Value(dateOnly(originalDate)),
        weekIndex: Value(weekIndex),
        type: Value(type),
        targetDistanceKm: Value(targetDistanceKm),
        targetDurationMin: Value(targetDurationMin),
        runWalkRatio: Value(runWalkRatio),
        targetPaceSecPerKm: Value(targetPaceSecPerKm),
        segmentsJson: Value(_encodeSegments(segments)),
        status: Value(status),
        notes: Value(notes),
      );
}

extension CompletedRunRowMapper on CompletedRunRow {
  CompletedRun toDomain() => CompletedRun(
        id: id,
        plannedRunId: plannedRunId,
        date: dateOnly(date),
        actualDistanceKm: actualDistanceKm,
        durationSec: durationSec,
        avgPaceSecPerKm: avgPaceSecPerKm,
        avgHr: avgHr,
        maxHr: maxHr,
        calories: calories,
        source: source,
        externalId: externalId,
      );
}

extension CompletedRunToCompanion on CompletedRun {
  CompletedRunsCompanion toCompanion({bool withId = false}) =>
      CompletedRunsCompanion(
        id: withId ? Value(id) : const Value.absent(),
        plannedRunId: Value(plannedRunId),
        date: Value(dateOnly(date)),
        actualDistanceKm: Value(actualDistanceKm),
        durationSec: Value(durationSec),
        avgPaceSecPerKm: Value(avgPaceSecPerKm),
        avgHr: Value(avgHr),
        maxHr: Value(maxHr),
        calories: Value(calories),
        source: Value(source),
        externalId: Value(externalId),
      );
}

extension SettingsRowMapper on SettingsRow {
  AppSettings toDomain() => AppSettings(
        units: units,
        reminderMorningMinutes: reminderMorningMinutes,
        reminderEveningMinutes: reminderEveningMinutes,
        adaptivityAggressiveness: adaptivityAggressiveness,
        catchupWindowDays: catchupWindowDays,
        longRunCatchupWindowDays: longRunCatchupWindowDays,
        cloudBackupEnabled: cloudBackupEnabled,
      );
}

extension SettingsToCompanion on AppSettings {
  SettingsRowsCompanion toCompanion() => SettingsRowsCompanion(
        id: const Value(0),
        units: Value(units),
        reminderMorningMinutes: Value(reminderMorningMinutes),
        reminderEveningMinutes: Value(reminderEveningMinutes),
        adaptivityAggressiveness: Value(adaptivityAggressiveness),
        catchupWindowDays: Value(catchupWindowDays),
        longRunCatchupWindowDays: Value(longRunCatchupWindowDays),
        cloudBackupEnabled: Value(cloudBackupEnabled),
      );
}
