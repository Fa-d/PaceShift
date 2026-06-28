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
  }) = _CompletedRun;

  const CompletedRun._();

  /// Whether this session counts as running mileage/fitness (excludes walks/hikes).
  bool get isRun => activityType.isRun;

  /// Pace formatted as `m:ss /km`, e.g. `5:42 /km`.
  String get formattedPace {
    final total = avgPaceSecPerKm.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }
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
