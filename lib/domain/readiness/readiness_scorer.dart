import 'dart:math' as math;

import '../models/completed_run.dart';
import '../models/enums.dart';
import '../models/planned_run.dart';
import '../models/training_plan.dart';

/// A 0–100 race-readiness score with a plain-language band (spec §4.7).
class ReadinessScore {
  const ReadinessScore({
    required this.score,
    required this.longRunCompletion,
    required this.longestRunKm,
    required this.totalVolumeCompletion,
    required this.consistency,
  });

  /// 0–100 overall score.
  final int score;

  /// Fractions (0–1) of each contributing component, for display/debugging.
  final double longRunCompletion;
  final double longestRunKm;
  final double totalVolumeCompletion;
  final double consistency;

  ReadinessBand get band {
    if (score >= 75) return ReadinessBand.onTrack;
    if (score >= 50) return ReadinessBand.slightlyBehind;
    return ReadinessBand.atRisk;
  }

  String get label => switch (band) {
        ReadinessBand.onTrack => 'On track',
        ReadinessBand.slightlyBehind => 'Slightly behind',
        ReadinessBand.atRisk => 'At risk',
      };
}

enum ReadinessBand { onTrack, slightlyBehind, atRisk }

/// Computes readiness from completed work versus the plan. **Pure.**
///
/// Weights (sum to 1.0):
/// - 40% — long-run target volume completed (weighted heaviest),
/// - 25% — longest single run achieved vs the peak target,
/// - 20% — total planned volume completed,
/// - 15% — consistency (rolling completion rate).
class ReadinessScorer {
  const ReadinessScorer({this.peakLongRunKm = 32});

  final double peakLongRunKm;

  ReadinessScore compute({
    required TrainingPlan plan,
    required List<PlannedRun> plannedRuns,
    required List<CompletedRun> completedRuns,
    required DateTime asOf,
  }) {
    final due = plannedRuns
        .where((r) => r.type.isRun && !r.scheduledDate.isAfter(asOf))
        .toList();

    // Long-run volume due vs completed (matched by linked planned run).
    final longRunsDue = due.where((r) => r.type == RunType.long);
    final longTargetKm =
        longRunsDue.fold<double>(0, (sum, r) => sum + (r.targetDistanceKm ?? 0));
    final completedByPlanned = {
      for (final c in completedRuns)
        if (c.plannedRunId != null) c.plannedRunId!: c,
    };
    final longDoneKm = longRunsDue
        .map((r) => completedByPlanned[r.id]?.actualDistanceKm ?? 0)
        .fold<double>(0, (a, b) => a + b);
    final longRunCompletion = _ratio(longDoneKm, longTargetKm);

    // Longest single run achieved vs the peak target.
    final longestAchieved = completedRuns.fold<double>(
        0, (mx, c) => math.max(mx, c.actualDistanceKm));
    final longestRatio = _ratio(longestAchieved, peakLongRunKm);

    // Total planned volume due vs completed.
    final totalTargetKm =
        due.fold<double>(0, (sum, r) => sum + (r.targetDistanceKm ?? 0));
    final totalDoneKm = completedRuns
        .where((c) => !c.date.isAfter(asOf))
        .fold<double>(0, (sum, c) => sum + c.actualDistanceKm);
    final totalCompletion = _ratio(totalDoneKm, totalTargetKm);

    // Consistency: fraction of due runs that were actually done (marked
    // completed or matched to a logged run).
    final doneCount = due
        .where((r) =>
            r.status == RunStatus.completed || completedByPlanned.containsKey(r.id))
        .length;
    final consistency = due.isEmpty ? 1.0 : doneCount / due.length;

    final raw = 0.40 * longRunCompletion +
        0.25 * longestRatio +
        0.20 * totalCompletion +
        0.15 * consistency;
    final score = (raw * 100).clamp(0, 100).round();

    return ReadinessScore(
      score: score,
      longRunCompletion: longRunCompletion,
      longestRunKm: longestRatio,
      totalVolumeCompletion: totalCompletion,
      consistency: consistency,
    );
  }

  double _ratio(double done, double target) {
    if (target <= 0) return 1.0;
    return (done / target).clamp(0.0, 1.0);
  }
}
