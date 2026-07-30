import 'dart:math' as math;

/// Axis geometry for the progress charts.
///
/// Plain Dart with no Flutter import, so it unit-tests directly. It lives in
/// `presentation/` rather than `domain/` on purpose: gridline spacing is a
/// property of the rendered chart, not of training.

/// The axis ceiling for a series whose largest value is [rawMax], leaving
/// [headroom] above it so the tallest bar doesn't touch the top.
///
/// Returns [fallback] when there is nothing to plot, so callers can compute the
/// ceiling **once** and derive the tick interval from the same number — the
/// charts used to size the axis with a fallback but compute the interval from
/// the raw (zero) value, producing gridlines that didn't match the axis.
double niceAxisMax(double rawMax, {required double fallback, double headroom = 1.2}) {
  if (!rawMax.isFinite || rawMax <= 0) return fallback;
  return rawMax * headroom;
}

/// The smallest "nice" step (1, 2, 2.5 or 5 × a power of ten) that covers
/// [axisMax] in at most [ticks] gridlines.
///
/// Always greater than zero — fl_chart asserts on a non-positive interval — and
/// never coarser than the axis itself. The previous `(maxY / 4).clamp(5, 100)`
/// had a hard floor of 5, so an imperial athlete running 3-mile weeks got a
/// single gridline on a chart with a ceiling of 3.6.
double niceInterval(double axisMax, {int ticks = 4}) {
  if (!axisMax.isFinite || axisMax <= 0 || ticks <= 0) return 1;

  final rough = axisMax / ticks;
  final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  for (final step in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    final candidate = step * magnitude;
    if (candidate >= rough) return candidate;
  }
  return 10 * magnitude;
}

/// Index ranges of consecutive `true` entries in [present], as inclusive
/// `[start, end]` pairs.
///
/// Used to split a line series at missing weeks. Drawing one curved series over
/// non-adjacent points makes fl_chart interpolate straight across the gap,
/// which reads as long runs that were done but weren't.
List<List<int>> contiguousSegments(List<bool> present) {
  final segments = <List<int>>[];
  var start = -1;
  for (var i = 0; i < present.length; i++) {
    if (present[i]) {
      if (start < 0) start = i;
    } else if (start >= 0) {
      segments.add([start, i - 1]);
      start = -1;
    }
  }
  if (start >= 0) segments.add([start, present.length - 1]);
  return segments;
}
