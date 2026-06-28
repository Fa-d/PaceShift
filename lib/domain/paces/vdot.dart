import 'dart:math' as math;

/// Jack Daniels' VDOT model (Daniels & Gilbert) plus the Riegel endurance model.
///
/// **Pure** — no Flutter/IO. These functions turn race performances into a
/// fitness number (VDOT) and back into training paces, and predict times across
/// distances. Used by [PaceCalculator], `FitnessEstimator` and `RacePredictor`.
class Vdot {
  const Vdot._();

  /// Oxygen cost (ml/kg/min) of running at velocity [vMetersPerMin].
  static double vo2AtVelocity(double vMetersPerMin) =>
      -4.60 + 0.182258 * vMetersPerMin + 0.000104 * vMetersPerMin * vMetersPerMin;

  /// Fraction of VO2max sustainable for a race lasting [minutes].
  static double percentVo2maxForDuration(double minutes) =>
      0.8 +
      0.1894393 * math.exp(-0.012778 * minutes) +
      0.2989558 * math.exp(-0.1932605 * minutes);

  /// VDOT implied by covering [distanceKm] in [durationSec].
  ///
  /// e.g. a 5 km run in 20:00 → ≈ 49.8.
  static double fromPerformance(double distanceKm, int durationSec) {
    if (distanceKm <= 0 || durationSec <= 0) return 0;
    final minutes = durationSec / 60.0;
    final vMetersPerMin = (distanceKm * 1000.0) / minutes;
    final vo2 = vo2AtVelocity(vMetersPerMin);
    final pct = percentVo2maxForDuration(minutes);
    return vo2 / pct;
  }

  /// Velocity (m/min) that costs [targetVo2] ml/kg/min, inverting [vo2AtVelocity]
  /// via the quadratic formula (positive root).
  static double velocityForVo2(double targetVo2) {
    const a = 0.000104;
    const b = 0.182258;
    final c = -4.60 - targetVo2;
    final disc = b * b - 4 * a * c;
    if (disc <= 0) return 0;
    return (-b + math.sqrt(disc)) / (2 * a);
  }

  /// Training pace (seconds per km) for running at [intensityFraction] of [vdot].
  ///
  /// Intensity fractions follow Daniels' zones (see [PaceCalculator]).
  static double paceSecPerKmAtIntensity(double vdot, double intensityFraction) {
    if (vdot <= 0) return 0;
    final v = velocityForVo2(vdot * intensityFraction);
    if (v <= 0) return 0;
    return 60000.0 / v; // 1000 m / (v m/min) * 60 s/min
  }

  /// Riegel endurance prediction: time (sec) to cover [targetKm] given a known
  /// effort of [knownSec] over [knownKm]. `T2 = T1 · (D2/D1)^1.06`.
  static int riegelPredictSec({
    required int knownSec,
    required double knownKm,
    required double targetKm,
  }) {
    if (knownSec <= 0 || knownKm <= 0 || targetKm <= 0) return 0;
    return (knownSec * math.pow(targetKm / knownKm, 1.06)).round();
  }
}
