/// Pure date helpers. Training logic works in **calendar dates** (no time of
/// day), so we normalise [DateTime] values to local midnight everywhere.
///
/// No Flutter or IO imports — safe for the pure domain layer and unit tests.
library;

/// Strips the time component, returning local midnight of the same calendar day.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Today's calendar date at local midnight.
DateTime today() => dateOnly(DateTime.now());

/// Whole calendar days from [a] to [b] (b - a). Negative if [b] precedes [a].
///
/// Computed on normalised dates so DST transitions never produce 23/25h drift.
int daysBetween(DateTime a, DateTime b) {
  final from = dateOnly(a);
  final to = dateOnly(b);
  return (to.difference(from).inHours / 24).round();
}

/// True when [a] and [b] fall on the same calendar day.
bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// [d] shifted by [days] calendar days (normalised to midnight).
DateTime addDays(DateTime d, int days) {
  final base = dateOnly(d);
  return DateTime(base.year, base.month, base.day + days);
}

/// ISO weekday for [d] where Monday == 1 … Sunday == 7 (matches `DateTime.weekday`).
int weekdayMon1(DateTime d) => d.weekday;

/// The most recent date on/before [d] that falls on ISO weekday [weekday]
/// (Mon=1 … Sun=7).
DateTime previousOrSameWeekday(DateTime d, int weekday) {
  final base = dateOnly(d);
  final diff = (base.weekday - weekday + 7) % 7;
  return addDays(base, -diff);
}

/// The next date on/after [d] that falls on ISO weekday [weekday] (Mon=1 … Sun=7).
DateTime nextOrSameWeekday(DateTime d, int weekday) {
  final base = dateOnly(d);
  final diff = (weekday - base.weekday + 7) % 7;
  return addDays(base, diff);
}

/// The 1-based training week that [date] falls in, relative to [planStart].
///
/// Dates before the plan started return 0, -1, … so base-building history
/// spreads across real weeks instead of piling into week 1.
///
/// Uses `.floor()`, never `~/`: integer division truncates *toward zero*, so
/// `~/` maps both day -1 and day -6 onto "week 1" and silently disagrees with
/// this function for every pre-plan date. Five call sites used to compute this
/// inline, two of them with `~/`; this is the one definition.
int planWeek(DateTime planStart, DateTime date) =>
    (daysBetween(planStart, date) / 7).floor() + 1;

/// [planWeek] floored at 1 — for display and for the engine, where "before the
/// plan started" is not a meaningful week to show or schedule into.
int planWeekClamped(DateTime planStart, DateTime date) {
  final w = planWeek(planStart, date);
  return w < 1 ? 1 : w;
}

/// The first calendar date of 1-based training [week].
///
/// The inverse of [planWeek]: `planWeekStart(s, planWeek(s, d)) <= d` and
/// `d < planWeekStart(...) + 7 days`, for pre-plan weeks too.
DateTime planWeekStart(DateTime planStart, int week) =>
    addDays(planStart, (week - 1) * 7);
