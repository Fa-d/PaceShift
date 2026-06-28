import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'training_plan.freezed.dart';

/// A structured marathon training plan anchored to a **fixed race date**.
///
/// Pure value type (freezed) — no Flutter/IO dependencies.
@freezed
abstract class TrainingPlan with _$TrainingPlan {
  const factory TrainingPlan({
    required int id,
    required String name,
    required DateTime raceDate,
    required double raceDistanceKm,
    required DateTime startDate,

    /// Preferred weekday for long runs, Mon=1 … Sun=7.
    required int longRunDay,
    required PlanStatus status,
    required DateTime createdAt,

    /// Number of taper weeks at the end of the plan (sacred — see engine §4.3).
    @Default(3) int taperWeeks,
  }) = _TrainingPlan;

  const TrainingPlan._();

  /// Total whole weeks spanned by the plan (start → race), 1-based count.
  int get totalWeeks {
    final days = raceDate.difference(startDate).inDays;
    return (days / 7).ceil() + 1;
  }
}
