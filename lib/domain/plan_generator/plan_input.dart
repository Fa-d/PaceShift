import '../../core/date_utils.dart';

/// Inputs the user provides during onboarding to generate a plan (spec §5).
///
/// Pure value object — no Flutter/IO.
class PlanInput {
  /// Shortest plan the generator can build: a taper plus a minimal build.
  static const int minPlanWeeks = 6;

  /// Longest plan offered. Beyond this the extra weeks add base, not fitness,
  /// and the plan would start absurdly far in the future.
  static const int maxPlanWeeks = 24;

  /// Plan length in whole weeks that actually fits between [from] and
  /// [raceDate], counting the current week through race week inclusive.
  ///
  /// **Must be passed by every caller.** [planWeeks] defaults to 19, and the
  /// generator anchors `startDate` backwards from race week — so leaving it at
  /// the default gave an athlete racing in 8 weeks a plan that started 10 weeks
  /// *in the past*, whose entire pre-history was then marked missed on the first
  /// rollover. That is what made a fresh plan open at "At risk" with weeks of
  /// phantom missed runs on the progress chart.
  static int weeksUntilRace(DateTime from, DateTime raceDate) {
    final raceWeekMonday = previousOrSameWeekday(raceDate, DateTime.monday);
    final thisWeekMonday = previousOrSameWeekday(from, DateTime.monday);
    final wholeWeeks = daysBetween(thisWeekMonday, raceWeekMonday) ~/ 7;
    final weeks = wholeWeeks + 1;
    if (weeks < minPlanWeeks) return minPlanWeeks;
    if (weeks > maxPlanWeeks) return maxPlanWeeks;
    return weeks;
  }

  /// A sensible peak long run for [raceDistanceKm], in km.
  ///
  /// The ratio rises as the race shortens — a marathoner peaks well below race
  /// distance, a 10k runner well above it. Rounded to whole km, which keeps a
  /// marathon at exactly 32 km and so preserves the spec's canonical seed
  /// ladder. Without this the default 32 applied to every race, giving a
  /// half-marathon plan a peak of 1.5x the race distance.
  static double defaultPeakLongRunKm(double raceDistanceKm) {
    final ratio = raceDistanceKm <= 10
        ? 1.3
        : raceDistanceKm <= 21.1
            ? 0.9
            : 0.76;
    return (raceDistanceKm * ratio).roundToDouble();
  }

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
