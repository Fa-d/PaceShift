import '../../core/design.dart';

/// Heatmap mark geometry for the plan screen, mirroring why
/// `stats/chart_math.dart` lives in `presentation/`: cell shading is a property
/// of the rendered heatmap, not of training. Plain numbers, no Flutter widget
/// code, so it unit-tests directly.

/// Opacity for a heatmap cell whose distance is [value], relative to the
/// plan-wide [max].
///
/// Lerps from [Alpha.tint] (the lightest a low-volume day renders) to
/// [Alpha.muted] (the darkest a peak week renders), so a short day still reads
/// as a faint wash rather than a blank cell. Returns the floor ([Alpha.tint])
/// when there is nothing to scale against (`max <= 0`) or [value] is
/// non-finite — a NaN/Infinity share would otherwise leak through as a
/// fully-opaque cell.
double intensityAlpha(double value, double max) {
  if (max <= 0 || !value.isFinite || !max.isFinite) return Alpha.tint;
  if (value <= 0) return Alpha.tint;
  final t = (value / max).clamp(0.0, 1.0);
  return Alpha.tint + (Alpha.muted - Alpha.tint) * t;
}

// No scroll-offset estimates live here. Jump-to-today needs them only when the
// target week has not been built yet; the plan screen builds its weeks eagerly
// (the shared-axis view swap needs a single box child), so every week has a
// live `GlobalKey` context and `Scrollable.ensureVisible` anchors exactly
// instead of approximating.
