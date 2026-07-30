/// The macro-cycle phase a training week belongs to.
///
/// Structural, not volume-derived: a phase is a *position* in the plan (how
/// close to the race), which is what a taper is — a property of training, not of
/// rendering. Sits beside `progress_stats.dart` for that reason.
///
/// Pure Dart — no Flutter/IO, so it unit-tests directly.
enum PlanPhase { base, build, peak, taper }

extension PlanPhaseX on PlanPhase {
  /// Display label, e.g. `Build`.
  String get label => switch (this) {
        PlanPhase.base => 'Base',
        PlanPhase.build => 'Build',
        PlanPhase.peak => 'Peak',
        PlanPhase.taper => 'Taper',
      };
}

/// The phase for 1-based training [week] within a plan of [totalWeeks] that
/// ends with [taperWeeks] taper weeks.
///
/// Rules:
///  * **Taper** — the final [taperWeeks] weeks.
///  * Of the weeks before that, the first ~40% are **base**, the next ~40%
///    **build**, and the remainder (min 1) **peak**.
///
/// Degenerate plans clamp instead of throwing: a 1-week plan is all taper, and
/// `taperWeeks >= totalWeeks` makes every week taper. [week] itself is clamped
/// into `[1, totalWeeks]` so an out-of-range index answers something sensible
/// rather than crashing the UI.
PlanPhase phaseForWeek(
  int week, {
  required int totalWeeks,
  required int taperWeeks,
}) {
  // Guard the degenerate cases without ever throwing.
  final weeks = totalWeeks < 1 ? 1 : totalWeeks;
  final taper = taperWeeks.clamp(0, weeks);
  final w = week.clamp(1, weeks);

  // Taper: the final `taper` weeks (1 when taper == weeks, so every week tapers).
  final taperStart = weeks - taper + 1;
  if (w >= taperStart) return PlanPhase.taper;

  final buildable = taperStart - 1; // weeks before the taper
  final baseCount = (buildable * 0.4).floor();
  final buildCount = (buildable * 0.4).floor();
  if (w <= baseCount) return PlanPhase.base;
  if (w <= baseCount + buildCount) return PlanPhase.build;
  // Peak is whatever remains — always at least one week before the taper.
  return PlanPhase.peak;
}
