/// Inputs the user provides during onboarding to generate a plan (spec §5).
///
/// Pure value object — no Flutter/IO.
class PlanInput {
  const PlanInput({
    required this.raceDate,
    this.raceDistanceKm = 42.2,
    required this.currentLongestRunKm,
    this.daysPerWeek = 3,
    required this.preferredLongRunDay,
    this.planName,
    this.planWeeks = 19,
    this.taperWeeks = 3,
    this.peakLongRunKm = 32,
    this.goalFinishSec,
  });

  /// The immovable anchor.
  final DateTime raceDate;
  final double raceDistanceKm;

  /// Longest single run the athlete has done recently (km).
  final double currentLongestRunKm;

  /// Running days per week (3–5 supported; default 3 = Easy + Steady + Long).
  final int daysPerWeek;

  /// Preferred long-run weekday, Mon=1 … Sun=7.
  final int preferredLongRunDay;

  final String? planName;

  /// Total plan length in weeks (the final week is race week).
  final int planWeeks;

  /// Number of taper weeks before race week.
  final int taperWeeks;

  /// Peak long-run distance (km).
  final double peakLongRunKm;

  /// Optional goal finish time in seconds. When set, the generator assigns
  /// training paces (VDOT) to every run and builds structured quality sessions.
  final int? goalFinishSec;
}
