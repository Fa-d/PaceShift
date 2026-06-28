import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../domain/models/completed_run.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';
import '../providers/providers.dart';

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

/// Aggregated data backing the stats screen.
class StatsData {
  const StatsData({
    required this.weeklyVolumes,
    required this.longRunProgression,
    required this.completionStreak,
    required this.totalCompletedKm,
    required this.longestRunKm,
  });

  final List<WeeklyVolume> weeklyVolumes;
  final List<LongRunPoint> longRunProgression;
  final int completionStreak;
  final double totalCompletedKm;
  final double longestRunKm;

  bool get isEmpty => weeklyVolumes.isEmpty;
}

/// Derives [StatsData] from the active plan, planned runs and completed runs.
final statsProvider = Provider<StatsData>((ref) {
  final plan = ref.watch(activePlanProvider).value;
  final runs = ref.watch(plannedRunsProvider).value ?? const <PlannedRun>[];
  final completed = ref.watch(completedRunsProvider).value ?? const <CompletedRun>[];
  if (plan == null || runs.isEmpty) {
    return const StatsData(
      weeklyVolumes: [],
      longRunProgression: [],
      completionStreak: 0,
      totalCompletedKm: 0,
      longestRunKm: 0,
    );
  }

  final completedByPlanned = {
    for (final c in completed)
      if (c.plannedRunId != null) c.plannedRunId!: c,
  };

  // Weekly planned volume.
  final plannedByWeek = <int, double>{};
  final longByWeek = <int, double>{};
  for (final r in runs.where((r) => r.type.isRun)) {
    plannedByWeek[r.weekIndex] =
        (plannedByWeek[r.weekIndex] ?? 0) + (r.targetDistanceKm ?? 0);
    if (r.type == RunType.long) {
      longByWeek[r.weekIndex] = r.targetDistanceKm ?? 0;
    }
  }

  // Weekly completed volume (by the week the planned run lives in; falls back to
  // calendar week for unplanned runs).
  final completedByWeek = <int, double>{};
  int weekOfDate(DateTime d) {
    final days = daysBetween(plan.startDate, d);
    return days < 0 ? 1 : (days ~/ 7) + 1;
  }

  final runById = {for (final r in runs) r.id: r};
  for (final c in completed) {
    final week = c.plannedRunId != null && runById.containsKey(c.plannedRunId)
        ? runById[c.plannedRunId]!.weekIndex
        : weekOfDate(c.date);
    completedByWeek[week] = (completedByWeek[week] ?? 0) + c.actualDistanceKm;
  }

  final weeks = (plannedByWeek.keys.toSet()..addAll(completedByWeek.keys)).toList()
    ..sort();
  final weeklyVolumes = [
    for (final w in weeks)
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
        actualKm: runs
            .where((r) => r.weekIndex == w && r.type == RunType.long)
            .map((r) => completedByPlanned[r.id]?.actualDistanceKm)
            .firstWhere((v) => v != null, orElse: () => null),
      ),
  ];

  // Completion streak: consecutive most-recent due runs that were completed.
  final today = ref.watch(todayProvider);
  final dueRuns = runs
      .where((r) => r.type.isRun && !r.scheduledDate.isAfter(today))
      .toList()
    ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
  var streak = 0;
  for (final r in dueRuns) {
    final done = r.status == RunStatus.completed ||
        completedByPlanned.containsKey(r.id);
    if (done) {
      streak++;
    } else {
      break;
    }
  }

  final totalCompletedKm =
      completed.fold<double>(0, (s, c) => s + c.actualDistanceKm);
  final longestRunKm =
      completed.fold<double>(0, (m, c) => c.actualDistanceKm > m ? c.actualDistanceKm : m);

  return StatsData(
    weeklyVolumes: weeklyVolumes,
    longRunProgression: longRunProgression,
    completionStreak: streak,
    totalCompletedKm: totalCompletedKm,
    longestRunKm: longestRunKm,
  );
});
