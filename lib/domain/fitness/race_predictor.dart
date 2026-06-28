import '../models/completed_run.dart';
import '../paces/vdot.dart';
import 'fitness_estimator.dart';

/// A predicted race outcome.
class RacePrediction {
  const RacePrediction({
    required this.distanceKm,
    required this.predictedSec,
    required this.vdot,
    required this.confident,
  });

  final double distanceKm;
  final int predictedSec;
  final double vdot;

  /// True when based on a long-enough effort to be trustworthy.
  final bool confident;

  double get paceSecPerKm => distanceKm <= 0 ? 0 : predictedSec / distanceKm;
}

/// Predicts a finish time for the goal race distance from logged runs.
///
/// **Pure.** Strategy: estimate current VDOT (Daniels) and binary-search the
/// race time whose implied VDOT matches; cross-check against a Riegel
/// extrapolation from the longest quality effort and average the two. Confidence
/// is gated on having an effort at least [confidentFractionOfRace] of the race.
class RacePredictor {
  const RacePredictor({
    this.estimator = const FitnessEstimator(),
    this.confidentFractionOfRace = 0.5,
  });

  final FitnessEstimator estimator;
  final double confidentFractionOfRace;

  RacePrediction? predict({
    required double raceDistanceKm,
    required List<CompletedRun> runs,
    DateTime? asOf,
  }) {
    final vdot = estimator.estimateVdot(runs, asOf: asOf);
    if (vdot == null || vdot <= 0) return null;

    final fromVdot = _timeForVdot(raceDistanceKm, vdot);

    // Riegel cross-check from the longest qualifying effort.
    final longest = runs
        .where((r) => r.actualDistanceKm > 0 && r.durationSec > 0)
        .fold<CompletedRun?>(null, (best, r) =>
            best == null || r.actualDistanceKm > best.actualDistanceKm ? r : best);

    int predicted = fromVdot;
    if (longest != null) {
      final riegel = Vdot.riegelPredictSec(
        knownSec: longest.durationSec,
        knownKm: longest.actualDistanceKm,
        targetKm: raceDistanceKm,
      );
      predicted = ((fromVdot + riegel) / 2).round();
    }

    final confident = longest != null &&
        longest.actualDistanceKm >= raceDistanceKm * confidentFractionOfRace;

    return RacePrediction(
      distanceKm: raceDistanceKm,
      predictedSec: predicted,
      vdot: vdot,
      confident: confident,
    );
  }

  /// Finds the time (sec) over [distanceKm] whose implied VDOT equals [vdot],
  /// by binary search (VDOT decreases as time increases).
  int _timeForVdot(double distanceKm, double vdot) {
    var lo = 60; // 1 min (absurdly fast)
    var hi = 60 * 60 * 12; // 12 h (absurdly slow)
    for (var i = 0; i < 60; i++) {
      final mid = (lo + hi) ~/ 2;
      final v = Vdot.fromPerformance(distanceKm, mid);
      if (v > vdot) {
        lo = mid; // too fast → needs more time
      } else {
        hi = mid;
      }
    }
    return (lo + hi) ~/ 2;
  }
}
