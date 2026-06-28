import 'vdot.dart';

/// The five Daniels training intensities plus goal race pace, as **seconds per
/// km**. Pure value type.
class TrainingPaces {
  const TrainingPaces({
    required this.vdot,
    required this.easy,
    required this.marathon,
    required this.threshold,
    required this.interval,
    required this.repetition,
    required this.race,
  });

  final double vdot;
  final double easy; // recovery / long-run pace
  final double marathon; // steady "M" pace
  final double threshold; // tempo "T" pace
  final double interval; // "I" pace (~vVO2max)
  final double repetition; // "R" pace (speed)
  final double race; // target race pace (from goal time when known)

  /// Pace (sec/km) for a [RunType]-ish label used by the generator/UI.
  double forZone(PaceZone zone) => switch (zone) {
        PaceZone.easy => easy,
        PaceZone.marathon => marathon,
        PaceZone.threshold => threshold,
        PaceZone.interval => interval,
        PaceZone.repetition => repetition,
        PaceZone.race => race,
      };
}

enum PaceZone { easy, marathon, threshold, interval, repetition, race }

/// Derives [TrainingPaces] from fitness (VDOT) or a goal race time.
///
/// **Pure.** Intensity fractions of VDOT follow Daniels' zones:
/// E≈0.70, M≈0.84, T≈0.88, I≈0.98, R≈1.05.
class PaceCalculator {
  const PaceCalculator();

  static const _easyFrac = 0.70;
  static const _marathonFrac = 0.84;
  static const _thresholdFrac = 0.88;
  static const _intervalFrac = 0.98;
  static const _repetitionFrac = 1.05;

  /// Builds paces from a known [vdot]. [raceGoalSecPerKm] overrides the derived
  /// race pace when the athlete has a concrete goal time.
  TrainingPaces fromVdot(double vdot, {double? raceGoalSecPerKm}) {
    double at(double f) => Vdot.paceSecPerKmAtIntensity(vdot, f);
    return TrainingPaces(
      vdot: vdot,
      easy: at(_easyFrac),
      marathon: at(_marathonFrac),
      threshold: at(_thresholdFrac),
      interval: at(_intervalFrac),
      repetition: at(_repetitionFrac),
      race: raceGoalSecPerKm ?? at(_marathonFrac),
    );
  }

  /// Builds paces implied by a goal of finishing [raceDistanceKm] in [goalSec].
  /// The goal performance defines the VDOT; race pace is the exact goal pace.
  TrainingPaces fromGoalTime({
    required double raceDistanceKm,
    required int goalSec,
  }) {
    final vdot = Vdot.fromPerformance(raceDistanceKm, goalSec);
    final racePace = goalSec / raceDistanceKm;
    return fromVdot(vdot, raceGoalSecPerKm: racePace);
  }
}
