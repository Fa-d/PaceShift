import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'completed_run.freezed.dart';

/// A run the athlete actually performed — from Health Connect or entered
/// manually. May or may not be linked to a [PlannedRun].
@freezed
abstract class CompletedRun with _$CompletedRun {
  const factory CompletedRun({
    required int id,

    /// Linked planned run, or null for an unplanned/extra run.
    int? plannedRunId,
    required DateTime date,
    required double actualDistanceKm,
    required int durationSec,

    /// Average pace in seconds per km (computed at ingest).
    required double avgPaceSecPerKm,
    int? avgHr,
    int? maxHr,
    double? calories,
    required RunSource source,

    /// What kind of activity this was. Defaults to [ActivityType.run] for
    /// manually entered runs and pre-`activityType` rows.
    @Default(ActivityType.run) ActivityType activityType,

    /// Health Connect record id, used to dedup repeated syncs.
    String? externalId,

    /// A planned run this workout probably belongs to, pending the user's
    /// confirmation. Only ever set while [plannedRunId] is null.
    int? suggestedPlannedRunId,
  }) = _CompletedRun;

  const CompletedRun._();

  /// Whether this session counts as running mileage/fitness (excludes walks/hikes).
  bool get isRun => activityType.isRun;

  /// Whether a real duration was recorded.
  ///
  /// [durationSec] is non-nullable, so `0` is the "unknown" sentinel: a run
  /// logged with neither an explicit time nor a target duration stores 0, and
  /// [avgPaceSecPerKm] is then 0 too. The distance is still real — such a run
  /// counts toward volume and the streak — but its time and pace must render
  /// as unknown rather than as "0m" at "0:00 /km".
  bool get hasDuration => durationSec > 0;
}

/// Computes average pace (sec/km) from distance and duration, guarding against
/// division by zero for empty/invalid sessions.
double computeAvgPaceSecPerKm({
  required double distanceKm,
  required int durationSec,
}) {
  if (distanceKm <= 0) return 0;
  return durationSec / distanceKm;
}
