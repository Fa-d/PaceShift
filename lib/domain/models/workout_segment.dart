import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_segment.freezed.dart';
part 'workout_segment.g.dart';

/// The role a [WorkoutSegment] plays within a structured session.
enum SegmentKind { warmup, hard, recovery, tempo, steady, cooldown }

/// One block of a structured/pace-based workout (e.g. "6 × 800 m @ interval").
///
/// Pure value type (freezed + json) so it can be embedded in [PlannedRun] and
/// persisted as JSON. Either [distanceKm] or [durationSec] describes the block's
/// length; [reps] repeats `hard`/`recovery` pairs.
@freezed
abstract class WorkoutSegment with _$WorkoutSegment {
  const factory WorkoutSegment({
    required SegmentKind kind,
    @Default(1) int reps,
    double? distanceKm,
    int? durationSec,

    /// Target pace for this block, seconds per km (null = easy/by-feel).
    double? targetPaceSecPerKm,
    String? label,
  }) = _WorkoutSegment;

  const WorkoutSegment._();

  factory WorkoutSegment.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSegmentFromJson(json);

  /// Running distance this block contributes (reps × per-rep distance).
  double get totalKm => (distanceKm ?? 0) * reps;
}
