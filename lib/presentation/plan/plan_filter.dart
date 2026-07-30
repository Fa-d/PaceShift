import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';

/// The plan screen's filter state — which run cards to show.
///
/// Pure value type with no Flutter/IO. The week list applies it to the full run
/// set; the filter bar mutates it via [copyWith]. Lives in `presentation/`
/// because "what to show on a screen" is a presentation concern, but it owns no
/// rendering — it could move to `domain/` unchanged if a second surface needed
/// the same filtering.
class PlanFilter {
  const PlanFilter({
    this.types = const {},
    this.runsOnly = false,
    this.remainingOnly = false,
  });

  /// Restrict to these run types (empty = no type restriction).
  final Set<RunType> types;

  /// Hide rest / cross / strength days — show only actual running.
  final bool runsOnly;

  /// Hide everything that isn't still-to-do future work.
  final bool remainingOnly;

  /// Whether any toggle is active (i.e. the list is narrower than the full plan).
  bool get isActive => types.isNotEmpty || runsOnly || remainingOnly;

  PlanFilter copyWith({
    Set<RunType>? types,
    bool? runsOnly,
    bool? remainingOnly,
  }) =>
      PlanFilter(
        types: types ?? this.types,
        runsOnly: runsOnly ?? this.runsOnly,
        remainingOnly: remainingOnly ?? this.remainingOnly,
      );

  /// [runs] narrowed to this filter, evaluated as of [asOf].
  ///
  /// Reuses [PlannedRun.isDueBy] for "remaining" so this can never disagree with
  /// the engine and the readiness scorer about what counts as overdue.
  List<PlannedRun> apply(List<PlannedRun> runs, DateTime asOf) {
    if (!isActive) return runs;
    return runs.where((r) {
      if (runsOnly && !r.type.isRun) return false;
      if (types.isNotEmpty && !types.contains(r.type)) return false;
      if (remainingOnly && !(r.isOpen && !r.isDueBy(asOf))) return false;
      return true;
    }).toList();
  }
}
