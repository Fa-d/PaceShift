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

/// Distance like `12.5 km` (trailing `.0` trimmed to a whole number).
String formatKm(double? km) {
  if (km == null) return '—';
  final rounded = (km * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return '${rounded.toInt()} km';
  return '${rounded.toStringAsFixed(1)} km';
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

/// Pace (sec/km) as `5:42 /km`.
String formatPace(double secPerKm) {
  if (secPerKm <= 0) return '—';
  final total = secPerKm.round();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')} /km';
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
