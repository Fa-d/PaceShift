import '../models/completed_run.dart';
import '../paces/vdot.dart';

/// Estimates the athlete's current fitness (VDOT) from logged runs.
///
/// **Pure.** A run only counts as a fitness signal if it's long enough to be a
/// meaningful effort ([minQualityKm]); we take a robust high-water mark rather
/// than the mean so a few easy days don't depress the estimate, but a single
/// fluke can't dominate either (we use the 2nd-best when enough efforts exist).
class FitnessEstimator {
  const FitnessEstimator({this.minQualityKm = 3.0, this.lookback = 60});

  /// Minimum distance for a run to inform fitness.
  final double minQualityKm;

  /// Consider at most this many of the most recent qualifying runs.
  final int lookback;

  /// Returns the estimated VDOT, or null when there isn't enough signal.
  double? estimateVdot(List<CompletedRun> runs, {DateTime? asOf}) {
    final cutoff = asOf ?? DateTime.now();
    final efforts = runs
        .where((r) =>
            r.actualDistanceKm >= minQualityKm &&
            r.durationSec > 0 &&
            !r.date.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final recent = efforts.take(lookback).toList();
    if (recent.isEmpty) return null;

    final vdots = recent
        .map((r) => Vdot.fromPerformance(r.actualDistanceKm, r.durationSec))
        .where((v) => v > 0)
        .toList()
      ..sort((a, b) => b.compareTo(a)); // descending
    if (vdots.isEmpty) return null;

    // Robust best: 2nd-highest when we have ≥3 efforts, else the highest.
    return vdots.length >= 3 ? vdots[1] : vdots.first;
  }
}
