import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'workout_segment.dart';

part 'planned_run.freezed.dart';

/// A single prescribed session within a [TrainingPlan].
///
/// `scheduledDate` is mutable (the engine moves it); `originalDate` records
/// where it started so the UI can show shifts. Pure value type.
@freezed
abstract class PlannedRun with _$PlannedRun {
  const factory PlannedRun({
    required int id,
    required int planId,

    /// Current scheduled date (mutable — the engine reschedules this).
    required DateTime scheduledDate,

    /// Where the run originally sat — for showing original → new moves.
    required DateTime originalDate,

    /// 1-based training week index.
    required int weekIndex,
    required RunType type,

    /// Target distance in km. Null for rest/strength.
    double? targetDistanceKm,

    /// Optional target duration in minutes.
    int? targetDurationMin,

    /// Optional run/walk ratio, e.g. "4:1" (run 4 / walk 1).
    String? runWalkRatio,

    /// Target average pace for the whole session, seconds per km (null = by feel).
    double? targetPaceSecPerKm,

    /// Structured breakdown for quality sessions (intervals/tempo). Null for
    /// simple continuous runs.
    List<WorkoutSegment>? segments,
    required RunStatus status,
    String? notes,
  }) = _PlannedRun;

  const PlannedRun._();

  /// Scheduling priority band derived from [type] (spec §4.2).
  RunPriority get priority => runPriority(type);

  /// Distance that counts toward weekly running load (0 for rest/cross/strength).
  double get loadKm => type.isRun ? (targetDistanceKm ?? 0) : 0;

  /// Whether this session has a structured (interval/tempo) breakdown.
  bool get isStructured => segments != null && segments!.isNotEmpty;

  /// Whether this run still needs doing (pending and in the future/today).
  bool get isOpen => status == RunStatus.pending;

  /// True if the run was moved from where it originally sat.
  bool get wasShifted => !_sameDate(scheduledDate, originalDate);

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
