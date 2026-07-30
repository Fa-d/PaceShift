import 'dart:math' as math;

import '../../core/date_utils.dart';
import '../models/completed_run.dart';
import '../models/enums.dart';
import '../models/planned_run.dart';
import '../models/training_plan.dart';

/// Planned vs completed volume for one training week.
class WeeklyVolume {
  const WeeklyVolume({
    required this.week,
    required this.plannedKm,
    required this.completedKm,
  });
  final int week;
  final double plannedKm;
  final double completedKm;
}

/// One long-run data point for the progression line.
class LongRunPoint {
  const LongRunPoint({
    required this.week,
    required this.targetKm,
    this.actualKm,
  });
  final int week;
  final double targetKm;
  final double? actualKm;
}

/// Aggregated data backing the progress screen.
class ProgressStats {
  const ProgressStats({
    required this.weeklyVolumes,
    required this.longRunProgression,
    required this.completionStreak,
    required this.totalCompletedKm,
    required this.longestRunKm,
    required this.prePlanCompletedKm,
  });

  static const ProgressStats empty = ProgressStats(
    weeklyVolumes: [],
    longRunProgression: [],
    completionStreak: 0,
    totalCompletedKm: 0,
    longestRunKm: 0,
    prePlanCompletedKm: 0,
  );

  /// One entry per training week, contiguous and 1-based: `weeklyVolumes[i].week`
  /// is always `i + 1`. Charts index by position, so a gap here would mislabel
  /// every bar after it.
  final List<WeeklyVolume> weeklyVolumes;
  final List<LongRunPoint> longRunProgression;
  final int completionStreak;

  /// Lifetime running distance, including anything logged before the plan began.
  final double totalCompletedKm;
  final double longestRunKm;

  /// Distance logged before the plan's start date. Kept out of [weeklyVolumes]
  /// — base-building work has no planned volume to sit beside, and rendering it
  /// as `W0`/`W-1` bars next to empty planned bars reads as missed training.
  final double prePlanCompletedKm;

  /// Whether there is a plan to chart at all.
  bool get hasPlanData => weeklyVolumes.isNotEmpty;

  /// Whether the athlete has actually logged any running.
  ///
  /// Distinct from [hasPlanData]: a fresh plan produces a full set of planned
  /// bars, so keying the empty state off the volume list alone made it
  /// unreachable and showed a chart of all-zero completed bars instead.
  bool get hasLoggedWork => totalCompletedKm > 0;
}

/// Derives [ProgressStats] from a plan, its runs and what was actually run.
///
/// **Pure** — same contract as `domain/engine`: no Flutter, IO or Drift, so
/// every rule below is unit-testable without a widget or a database.
class ProgressCalculator {
  const ProgressCalculator();

  ProgressStats compute({
    required TrainingPlan plan,
    required List<PlannedRun> plannedRuns,
    required List<CompletedRun> completedRuns,
    required DateTime asOf,
  }) {
    if (plannedRuns.isEmpty) return ProgressStats.empty;

    // Only runs count toward running stats; walks/hikes are stored but excluded
    // (see ActivityType.isRun).
    final runsDone = completedRuns.where((c) => c.isRun).toList();

    final completedByPlanned = {
      for (final c in runsDone)
        if (c.plannedRunId != null) c.plannedRunId!: c,
    };

    // Weekly planned volume, bucketed by the run's stored weekIndex — the
    // plan's own structural week, which the engine maintains when it moves runs.
    final plannedByWeek = <int, double>{};
    final longByWeek = <int, double>{};
    for (final r in plannedRuns.where((r) => r.type.isRun)) {
      plannedByWeek[r.weekIndex] =
          (plannedByWeek[r.weekIndex] ?? 0) + (r.targetDistanceKm ?? 0);
      if (r.type == RunType.long) {
        // Max, not assignment or sum: a week gets a second long run whenever
        // the engine rebalances a missed one, and the ladder's rung for that
        // week is its longest single run — not the last one iterated.
        longByWeek[r.weekIndex] =
            math.max(longByWeek[r.weekIndex] ?? 0, r.targetDistanceKm ?? 0);
      }
    }

    // Weekly completed volume. Two bucketing rules, deliberately:
    //  - linked to a planned run  → that run's weekIndex, so a run the engine
    //    moved across weeks stays in the bar whose planned volume asked for it;
    //  - unlinked (extra/pre-plan) → the training week its date falls in.
    final completedByWeek = <int, double>{};
    var prePlanKm = 0.0;
    final runById = {for (final r in plannedRuns) r.id: r};
    for (final c in runsDone) {
      final linked = c.plannedRunId != null ? runById[c.plannedRunId] : null;
      final week = linked?.weekIndex ?? planWeek(plan.startDate, c.date);
      if (week < 1) {
        prePlanKm += c.actualDistanceKm;
        continue;
      }
      completedByWeek[week] = (completedByWeek[week] ?? 0) + c.actualDistanceKm;
    }

    // Contiguous 1..N, so week N is always at index N-1.
    final lastWeek = [
      plan.totalWeeks,
      ...plannedByWeek.keys,
      ...completedByWeek.keys,
    ].reduce(math.max);
    final weeklyVolumes = [
      for (var w = 1; w <= lastWeek; w++)
        WeeklyVolume(
          week: w,
          plannedKm: plannedByWeek[w] ?? 0,
          completedKm: completedByWeek[w] ?? 0,
        ),
    ];

    final longRunProgression = [
      for (final w in longByWeek.keys.toList()..sort())
        LongRunPoint(
          week: w,
          targetKm: longByWeek[w]!,
          // Max for the same reason as the target: report the week's biggest
          // long run, not whichever happened to come first in the list.
          actualKm: plannedRuns
              .where((r) => r.weekIndex == w && r.type == RunType.long)
              .map((r) => completedByPlanned[r.id]?.actualDistanceKm)
              .whereType<double>()
              .fold<double?>(null, (m, v) => m == null ? v : math.max(m, v)),
        ),
    ];

    final completionStreak =
        _streak(plannedRuns, completedByPlanned, asOf);

    final totalCompletedKm =
        runsDone.fold<double>(0, (s, c) => s + c.actualDistanceKm);
    final longestRunKm = runsDone.fold<double>(
        0, (m, c) => math.max(m, c.actualDistanceKm));

    return ProgressStats(
      weeklyVolumes: weeklyVolumes,
      longRunProgression: longRunProgression,
      completionStreak: completionStreak,
      totalCompletedKm: totalCompletedKm,
      longestRunKm: longestRunKm,
      prePlanCompletedKm: prePlanKm,
    );
  }

  /// Consecutive most-recent runs that were completed.
  ///
  /// Two rules keep this from punishing the athlete for things they didn't do:
  ///  - a run is only *due* once its day has fully passed, so a long run still
  ///    pending at 09:00 on Saturday doesn't read as a failure;
  ///  - a `dropped` run is skipped entirely — the adaptive engine shed that
  ///    load itself, so it neither extends nor breaks the streak.
  int _streak(
    List<PlannedRun> plannedRuns,
    Map<int, CompletedRun> completedByPlanned,
    DateTime asOf,
  ) {
    final candidates = plannedRuns
        .where((r) => r.type.isRun && r.status != RunStatus.dropped)
        .where((r) => r.isDueBy(asOf))
        .toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    var streak = 0;
    for (final r in candidates) {
      final done = r.status == RunStatus.completed ||
          completedByPlanned.containsKey(r.id);
      if (!done) break;
      streak++;
    }
    return streak;
  }
}
