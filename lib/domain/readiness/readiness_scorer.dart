import 'dart:math' as math;

import '../models/completed_run.dart';
import '../models/enums.dart';
import '../models/planned_run.dart';
import '../models/training_plan.dart';

/// A 0–100 race-readiness score with a plain-language band (spec §4.7).
class ReadinessScore {
  const ReadinessScore({
    required this.score,
    required this.hasSignal,
    this.longRunCompletion,
    this.longestRunKm,
    this.totalVolumeCompletion,
    this.consistency,
  });

  /// Not enough has happened yet to say anything honest.
  static const ReadinessScore noSignal =
      ReadinessScore(score: 0, hasSignal: false);

  /// 0–100 overall score. Meaningless unless [hasSignal].
  final int score;

  /// Whether enough training has come due to compute a meaningful score.
  ///
  /// Components with nothing to measure are *absent*, not satisfied. The old
  /// scorer treated a zero target as full credit, so a brand-new plan scored
  /// 0.40 + 0.20 + 0.15 = **75/100 "On track"** before a single run.
  final bool hasSignal;

  /// Fractions (0–1) of each contributing component, or null when that
  /// component has nothing to measure yet. For display/debugging.
  final double? longRunCompletion;
  final double? longestRunKm;
  final double? totalVolumeCompletion;
  final double? consistency;

  ReadinessBand get band {
    if (!hasSignal) return ReadinessBand.notEnoughData;
    if (score >= 75) return ReadinessBand.onTrack;
    if (score >= 50) return ReadinessBand.slightlyBehind;
    return ReadinessBand.atRisk;
  }

  String get label => switch (band) {
        ReadinessBand.onTrack => 'On track',
        ReadinessBand.slightlyBehind => 'Slightly behind',
        ReadinessBand.atRisk => 'At risk',
        ReadinessBand.notEnoughData => 'Not enough data yet',
      };
}

enum ReadinessBand { onTrack, slightlyBehind, atRisk, notEnoughData }

/// Computes readiness from completed work versus the plan. **Pure.**
///
/// Weights (sum to 1.0 when every component is measurable):
/// - 40% — long-run target volume completed (weighted heaviest),
/// - 25% — longest single run achieved vs the plan's peak long run,
/// - 20% — total planned volume completed,
/// - 15% — consistency (rolling completion rate).
///
/// Components with nothing to measure are dropped and the remaining weights are
/// renormalised, so an athlete who has done everything asked of them scores 100
/// even in week 2 — rather than being capped by targets the plan hasn't set yet.
class ReadinessScorer {
  const ReadinessScorer({this.peakLongRunKm, this.minDueRuns = 3});

  /// Override for the peak long run. Normally null — the peak is derived from
  /// the plan's own long-run ladder, which is the only value that makes the
  /// 25% component earnable for every race distance. It was hardcoded to 32 km,
  /// so a half-marathon plan peaking at 19 km could never exceed 19/32 = 0.59.
  final double? peakLongRunKm;

  /// How many runs must have come due before a score is meaningful. Below this,
  /// one missed easy run in week 1 would print "At risk".
  final int minDueRuns;

  ReadinessScore compute({
    required TrainingPlan plan,
    required List<PlannedRun> plannedRuns,
    required List<CompletedRun> completedRuns,
    required DateTime asOf,
  }) {
    // Walks and hikes are stored but never count toward running stats
    // (see ActivityType.isRun) — this scorer used to omit the filter, so a
    // logged hike inflated readiness while the progress screen ignored it.
    final runsDone = completedRuns.where((c) => c.isRun).toList();

    // A dropped run is the engine's own decision to shed load, not work the
    // athlete failed to do, so it is not counted as due.
    final due = plannedRuns
        .where((r) =>
            r.type.isRun &&
            r.status != RunStatus.dropped &&
            r.isDueBy(asOf))
        .toList();

    final completedByPlanned = {
      for (final c in runsDone)
        if (c.plannedRunId != null) c.plannedRunId!: c,
    };

    final components = <_Component>[];

    // 40% — long-run volume due vs completed.
    final longRunsDue = due.where((r) => r.type == RunType.long).toList();
    final longTargetKm =
        longRunsDue.fold<double>(0, (sum, r) => sum + (r.targetDistanceKm ?? 0));
    if (longTargetKm > 0) {
      final longDoneKm = longRunsDue
          .map((r) => completedByPlanned[r.id]?.actualDistanceKm ?? 0)
          .fold<double>(0, (a, b) => a + b);
      components.add(_Component(0.40, _ratio(longDoneKm, longTargetKm)));
    }

    // 25% — longest single run achieved vs the plan's peak long run. Held back
    // until the plan has actually asked for a long run, so it can't score 0
    // against a target the athlete was never given.
    final peak = peakLongRunKm ?? _derivePeak(plan, plannedRuns);
    if (longRunsDue.isNotEmpty && peak > 0) {
      final longestAchieved =
          runsDone.fold<double>(0, (mx, c) => math.max(mx, c.actualDistanceKm));
      components.add(_Component(0.25, _ratio(longestAchieved, peak)));
    }

    // 20% — total planned volume due vs completed.
    final totalTargetKm =
        due.fold<double>(0, (sum, r) => sum + (r.targetDistanceKm ?? 0));
    if (totalTargetKm > 0) {
      final totalDoneKm = runsDone
          .where((c) => !c.date.isAfter(asOf))
          .fold<double>(0, (sum, c) => sum + c.actualDistanceKm);
      components.add(_Component(0.20, _ratio(totalDoneKm, totalTargetKm)));
    }

    // 15% — consistency: fraction of due runs actually done.
    if (due.isNotEmpty) {
      final doneCount = due
          .where((r) =>
              r.status == RunStatus.completed ||
              completedByPlanned.containsKey(r.id))
          .length;
      components.add(_Component(0.15, doneCount / due.length));
    }

    if (due.length < minDueRuns || components.isEmpty) {
      return ReadinessScore.noSignal;
    }

    final totalWeight = components.fold<double>(0, (s, c) => s + c.weight);
    final raw = components.fold<double>(0, (s, c) => s + c.weight * c.value) /
        totalWeight;

    return ReadinessScore(
      score: (raw * 100).clamp(0, 100).round(),
      hasSignal: true,
      longRunCompletion: _valueOf(components, 0.40),
      longestRunKm: _valueOf(components, 0.25),
      totalVolumeCompletion: _valueOf(components, 0.20),
      consistency: _valueOf(components, 0.15),
    );
  }

  /// The plan's own peak long run.
  ///
  /// Race day is excluded: the generator schedules the race itself as a
  /// [RunType.long] of the full race distance, so taking a naive maximum would
  /// measure the athlete against 42.2 km and make the component unearnable
  /// until race morning. The fallback (0.75 × race distance ≈ 31.7 km for a
  /// marathon) matches the value this was hardcoded to.
  double _derivePeak(TrainingPlan plan, List<PlannedRun> plannedRuns) {
    final peak = plannedRuns
        .where((r) =>
            r.type == RunType.long && !_sameDate(r.scheduledDate, plan.raceDate))
        .fold<double>(0, (m, r) => math.max(m, r.targetDistanceKm ?? 0));
    return peak > 0 ? peak : math.max(8.0, plan.raceDistanceKm * 0.75);
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _ratio(double done, double target) =>
      target <= 0 ? 0 : (done / target).clamp(0.0, 1.0);

  double? _valueOf(List<_Component> components, double weight) {
    for (final c in components) {
      if (c.weight == weight) return c.value;
    }
    return null;
  }
}

class _Component {
  const _Component(this.weight, this.value);
  final double weight;
  final double value;
}
