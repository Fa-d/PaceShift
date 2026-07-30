import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/domain/models/completed_run.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/models/planned_run.dart';
import 'package:paceshift/domain/progress/progress_stats.dart';

import '../engine/helpers.dart';

void main() {
  setUp(resetIds);
  const calc = ProgressCalculator();

  var nextCompletedId = 1000;
  CompletedRun logged({
    int? plannedRunId,
    required DateTime date,
    required double km,
    ActivityType activityType = ActivityType.run,
  }) =>
      CompletedRun(
        id: nextCompletedId++,
        plannedRunId: plannedRunId,
        date: dateOnly(date),
        actualDistanceKm: km,
        durationSec: (km * 360).round(),
        avgPaceSecPerKm: 360,
        source: RunSource.manual,
        activityType: activityType,
      );

  group('weekly volume', () {
    test('buckets planned volume by the run\'s stored weekIndex', () {
      final plan = testPlan();
      final runs = [...standardWeek(1), ...standardWeek(2)];

      final stats = calc.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: const [],
        asOf: dayIn(2, DateTime.sunday),
      );

      // standardWeek is 6 + 10 + 20.
      expect(stats.weeklyVolumes[0].plannedKm, 36);
      expect(stats.weeklyVolumes[1].plannedKm, 36);
    });

    test('is contiguous and 1-based, so week N sits at index N-1', () {
      final plan = testPlan(weeks: 10);
      // Only weeks 1 and 5 have runs — the gap must still be charted.
      final runs = [...standardWeek(1), ...standardWeek(5)];

      final stats = calc.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: const [],
        asOf: dayIn(5, DateTime.sunday),
      );

      expect(stats.weeklyVolumes.length, 10);
      for (var i = 0; i < stats.weeklyVolumes.length; i++) {
        expect(stats.weeklyVolumes[i].week, i + 1);
      }
      expect(stats.weeklyVolumes[2].plannedKm, 0);
      expect(stats.weeklyVolumes[4].plannedKm, 36);
    });

    test('keeps a fully dropped week in the series with zero planned volume',
        () {
      final plan = testPlan();
      final runs = [
        ...standardWeek(1),
        ...standardWeek(2).map((r) => r.copyWith(status: RunStatus.dropped)),
      ];

      final stats = calc.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: const [],
        asOf: dayIn(3, DateTime.monday),
      );

      expect(stats.weeklyVolumes[1].week, 2);
      // Dropped runs keep their target, so the bar shows what was asked for.
      expect(stats.weeklyVolumes[1].completedKm, 0);
    });

    test('credits a completion to the planned run\'s week, not its own date',
        () {
      final plan = testPlan();
      // The engine moved a week-4 long run into week 5 but kept weekIndex 4,
      // so the completion belongs in the bar that asked for the volume.
      final moved = PlannedRun(
        id: 501,
        planId: 1,
        scheduledDate: dayIn(5, DateTime.saturday),
        originalDate: dayIn(4, DateTime.saturday),
        weekIndex: 4,
        type: RunType.long,
        targetDistanceKm: 24,
        status: RunStatus.pending,
      );

      final stats = calc.compute(
        plan: plan,
        plannedRuns: [moved],
        completedRuns: [
          logged(
              plannedRunId: 501, date: dayIn(5, DateTime.saturday), km: 24),
        ],
        asOf: dayIn(6, DateTime.monday),
      );

      expect(stats.weeklyVolumes[3].completedKm, 24, reason: 'week 4');
      expect(stats.weeklyVolumes[4].completedKm, 0, reason: 'week 5');
    });

    test('buckets an unlinked extra run by the week its date falls in', () {
      final plan = testPlan();
      final stats = calc.compute(
        plan: plan,
        plannedRuns: standardWeek(1),
        completedRuns: [logged(date: dayIn(3, DateTime.tuesday), km: 8)],
        asOf: dayIn(4, DateTime.monday),
      );

      expect(stats.weeklyVolumes[2].completedKm, 8);
    });
  });

  group('pre-plan history', () {
    test('is kept out of the weekly bars but counted in the lifetime total',
        () {
      final plan = testPlan();
      final stats = calc.compute(
        plan: plan,
        plannedRuns: standardWeek(1),
        completedRuns: [
          logged(date: addDays(kStart, -10), km: 12),
          logged(date: dayIn(1, DateTime.monday), km: 6),
        ],
        asOf: dayIn(2, DateTime.monday),
      );

      expect(stats.weeklyVolumes.every((w) => w.week >= 1), isTrue);
      expect(stats.prePlanCompletedKm, 12);
      expect(stats.totalCompletedKm, 18);
      expect(stats.weeklyVolumes[0].completedKm, 6);
    });

    test('a pre-plan run still counts toward the longest run', () {
      final plan = testPlan();
      final stats = calc.compute(
        plan: plan,
        plannedRuns: standardWeek(1),
        completedRuns: [logged(date: addDays(kStart, -21), km: 30)],
        asOf: dayIn(1, DateTime.monday),
      );

      expect(stats.longestRunKm, 30);
      expect(stats.prePlanCompletedKm, 30);
    });
  });

  group('long-run progression', () {
    test('reports the longest target when a week has two long runs', () {
      final plan = testPlan();
      final runs = [
        ...standardWeek(3),
        // A rebalanced second long run in the same week.
        run(date: dayIn(3, DateTime.sunday), type: RunType.long, km: 24),
      ];

      final stats = calc.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: const [],
        asOf: dayIn(4, DateTime.monday),
      );

      final week3 = stats.longRunProgression.firstWhere((p) => p.week == 3);
      // Not 20 — the last one iterated used to overwrite the longer one.
      expect(week3.targetKm, 24);
    });

    test('reports the longest actual when a week has two long runs', () {
      final plan = testPlan();
      final first =
          run(date: dayIn(3, DateTime.saturday), type: RunType.long, km: 20);
      final second =
          run(date: dayIn(3, DateTime.sunday), type: RunType.long, km: 24);

      final stats = calc.compute(
        plan: plan,
        plannedRuns: [first, second],
        completedRuns: [
          logged(
              plannedRunId: first.id,
              date: dayIn(3, DateTime.saturday),
              km: 20),
          logged(
              plannedRunId: second.id,
              date: dayIn(3, DateTime.sunday),
              km: 24),
        ],
        asOf: dayIn(4, DateTime.monday),
      );

      final week3 = stats.longRunProgression.firstWhere((p) => p.week == 3);
      expect(week3.actualKm, 24);
    });

    test('leaves actual null for a long run that was not done', () {
      final plan = testPlan();
      final stats = calc.compute(
        plan: plan,
        plannedRuns: standardWeek(2),
        completedRuns: const [],
        asOf: dayIn(3, DateTime.monday),
      );

      expect(stats.longRunProgression.single.actualKm, isNull);
    });
  });

  group('walks and hikes', () {
    test('are excluded from every running statistic', () {
      final plan = testPlan();
      final runs = standardWeek(1);
      final long = runs.firstWhere((r) => r.type == RunType.long);

      final stats = calc.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: [
          logged(
              date: dayIn(1, DateTime.sunday),
              km: 15,
              activityType: ActivityType.walk),
          logged(
              plannedRunId: long.id,
              date: dayIn(1, DateTime.saturday),
              km: 20),
        ],
        asOf: dayIn(2, DateTime.monday),
      );

      expect(stats.totalCompletedKm, 20, reason: 'the 15 km walk must not count');
      expect(stats.longestRunKm, 20);
      expect(stats.weeklyVolumes[0].completedKm, 20);
    });

    test('a walk cannot complete a planned run for the streak', () {
      final plan = testPlan();
      final runs = standardWeek(1);

      final stats = calc.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: [
          for (final r in runs)
            logged(
                plannedRunId: r.id,
                date: r.scheduledDate,
                km: r.targetDistanceKm!,
                activityType: ActivityType.hike),
        ],
        asOf: dayIn(2, DateTime.monday),
      );

      expect(stats.completionStreak, 0);
    });
  });

  group('completion streak', () {
    test('counts consecutive completed runs back from the most recent', () {
      final plan = testPlan();
      final runs = standardWeek(1);

      final stats = calc.compute(
        plan: plan,
        plannedRuns: [
          for (final r in runs) r.copyWith(status: RunStatus.completed),
        ],
        completedRuns: const [],
        asOf: dayIn(2, DateTime.monday),
      );

      expect(stats.completionStreak, 3);
    });

    test('breaks on a missed run', () {
      final plan = testPlan();
      final runs = standardWeek(1);
      final stats = calc.compute(
        plan: plan,
        plannedRuns: [
          runs[0].copyWith(status: RunStatus.completed),
          runs[1].copyWith(status: RunStatus.missed),
          runs[2].copyWith(status: RunStatus.completed),
        ],
        completedRuns: const [],
        asOf: dayIn(2, DateTime.monday),
      );

      // Only Saturday's run survives; Wednesday's miss stops the count.
      expect(stats.completionStreak, 1);
    });

    test('a dropped run neither counts nor breaks the streak', () {
      final plan = testPlan();
      final runs = standardWeek(1);
      final stats = calc.compute(
        plan: plan,
        plannedRuns: [
          runs[0].copyWith(status: RunStatus.completed),
          // The engine shed this one — not the athlete's failure.
          runs[1].copyWith(status: RunStatus.dropped),
          runs[2].copyWith(status: RunStatus.completed),
        ],
        completedRuns: const [],
        asOf: dayIn(2, DateTime.monday),
      );

      expect(stats.completionStreak, 2);
    });

    test('today\'s still-pending run is not yet a failure', () {
      final plan = testPlan();
      final runs = standardWeek(1);
      final stats = calc.compute(
        plan: plan,
        plannedRuns: [
          runs[0].copyWith(status: RunStatus.completed),
          runs[1].copyWith(status: RunStatus.completed),
          // Saturday's long run, still pending, on Saturday itself.
          runs[2],
        ],
        completedRuns: const [],
        asOf: dayIn(1, DateTime.saturday),
      );

      // Without the "due only once the day has passed" rule this reads 0.
      expect(stats.completionStreak, 2);
    });

    test('a run matched by a logged completion counts even if still pending',
        () {
      final plan = testPlan();
      final runs = standardWeek(1);
      final stats = calc.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: [
          for (final r in runs)
            logged(
                plannedRunId: r.id,
                date: r.scheduledDate,
                km: r.targetDistanceKm!),
        ],
        asOf: dayIn(2, DateTime.monday),
      );

      expect(stats.completionStreak, 3);
    });
  });

  group('empty states', () {
    test('a plan with no runs at all yields ProgressStats.empty', () {
      final stats = calc.compute(
        plan: testPlan(),
        plannedRuns: const [],
        completedRuns: const [],
        asOf: kStart,
      );

      expect(stats.hasPlanData, isFalse);
      expect(stats.hasLoggedWork, isFalse);
    });

    test('a fresh plan has chartable weeks but nothing logged', () {
      final stats = calc.compute(
        plan: testPlan(),
        plannedRuns: [...standardWeek(1), ...standardWeek(2)],
        completedRuns: const [],
        asOf: kStart,
      );

      // The state the old `isEmpty => weeklyVolumes.isEmpty` could never reach,
      // so the screen drew all-zero completed bars instead of an empty state.
      expect(stats.hasPlanData, isTrue);
      expect(stats.hasLoggedWork, isFalse);
    });

    test('logging one run flips hasLoggedWork', () {
      final runs = standardWeek(1);
      final stats = calc.compute(
        plan: testPlan(),
        plannedRuns: runs,
        completedRuns: [
          logged(plannedRunId: runs.first.id, date: kStart, km: 6),
        ],
        asOf: dayIn(2, DateTime.monday),
      );

      expect(stats.hasLoggedWork, isTrue);
    });
  });
}
