import '../domain/models/enums.dart';

/// Human-readable labels and number formatting for the UI.

String runTypeLabel(RunType type) {
  switch (type) {
    case RunType.easy:
      return 'Easy run';
    case RunType.steady:
      return 'Steady run';
    case RunType.long:
      return 'Long run';
    case RunType.rest:
      return 'Rest day';
    case RunType.cross:
      return 'Cross-training';
    case RunType.strength:
      return 'Strength';
  }
}

String runStatusLabel(RunStatus status) {
  switch (status) {
    case RunStatus.pending:
      return 'Pending';
    case RunStatus.completed:
      return 'Completed';
    case RunStatus.missed:
      return 'Missed';
    case RunStatus.shifted:
      return 'Moved';
    case RunStatus.dropped:
      return 'Dropped';
  }
}

/// Distance and pace in the athlete's chosen units.
///
/// Everything is stored in kilometres; this is the only place that converts.
/// The units setting used to be entirely cosmetic — `formatKm` and
/// `formatPace` hard-coded "km" and "/km" and took no units parameter, so
/// nothing in the app read [AppSettings.units] and choosing miles changed
/// exactly nothing on screen. Requiring the units here is what makes that
/// impossible to reintroduce.
extension UnitFormat on UnitSystem {
  static const double _kmPerMile = 1.609344;

  bool get _imperial => this == UnitSystem.imperial;

  /// Short unit name: `km` or `mi`.
  String get distanceLabel => _imperial ? 'mi' : 'km';

  /// Pace suffix: `/km` or `/mi`.
  String get paceLabel => _imperial ? '/mi' : '/km';

  /// Converts a stored kilometre value into display units.
  double toDisplay(double km) => _imperial ? km / _kmPerMile : km;

  /// Distance like `12.5 km` / `7.8 mi` (a trailing `.0` is trimmed).
  String distance(double? km) {
    if (km == null) return '—';
    final v = toDisplay(km);
    final rounded = (v * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return '${rounded.toInt()} $distanceLabel';
    }
    return '${rounded.toStringAsFixed(1)} $distanceLabel';
  }

  /// Distance with no unit suffix, for when the caption already carries it.
  String distanceValue(double? km) {
    if (km == null) return '—';
    final rounded = (toDisplay(km) * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? '${rounded.toInt()}'
        : rounded.toStringAsFixed(1);
  }

  /// Pace like `5:42 /km` or `9:11 /mi`, from a stored sec/km value.
  String pace(double secPerKm) {
    if (secPerKm <= 0) return '—';
    final perUnit = _imperial ? secPerKm * _kmPerMile : secPerKm;
    final total = perUnit.round();
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')} $paceLabel';
  }
}

/// Duration in seconds as `1h 12m` / `48m` / `0m`.
String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

/// A finish time in seconds as `3:45:12` (h:mm:ss).
String formatFinishTime(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String weekdayName(int weekday) => _weekdayNames[(weekday - 1) % 7];
String monthName(int month) => _monthNames[(month - 1) % 12];

/// `Sat, 1 Nov` style date label.
String formatDateLabel(DateTime d) =>
    '${weekdayName(d.weekday)}, ${d.day} ${monthName(d.month)}';

/// `07:00` style time label from minutes since midnight.
String formatMinutesOfDay(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
