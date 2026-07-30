import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/domain/models/completed_run.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/models/training_plan.dart';
import 'package:paceshift/domain/readiness/readiness_scorer.dart';

import '../engine/helpers.dart';

void main() {
  setUp(resetIds);
  const scorer = ReadinessScorer();

  CompletedRun done(int plannedId, double km) => CompletedRun(
        id: plannedId,
        plannedRunId: plannedId,
        date: kStart,
        actualDistanceKm: km,
        durationSec: (km * 360).round(),
        avgPaceSecPerKm: 360,
        source: RunSource.manual,
      );

  test('perfect completion scores high and lands "On track"', () {
    final plan = testPlan();
    final runs = [
      ...standardWeek(1),
      ...standardWeek(2),
    ];
    final completed = runs
        .where((r) => r.type.isRun)
        .map((r) => done(r.id, r.targetDistanceKm!))
        .toList();

    final score = scorer.compute(
      plan: plan,
      plannedRuns: runs,
      completedRuns: completed,
      asOf: dayIn(2, DateTime.sunday),
    );

    expect(score.score, greaterThanOrEqualTo(75));
    expect(score.band, ReadinessBand.onTrack);
    expect(score.consistency, 1.0);
  });

  test('no runs completed scores low and lands "At risk"', () {
    final plan = testPlan();
    final runs = [...standardWeek(1), ...standardWeek(2)];

    final score = scorer.compute(
      plan: plan,
      plannedRuns: runs,
      completedRuns: const [],
      asOf: dayIn(2, DateTime.sunday),
    );

    expect(score.score, lessThan(50));
    expect(score.band, ReadinessBand.atRisk);
  });

  test('score rises monotonically as more long-run volume is completed', () {
    final plan = testPlan();
    final runs = [...standardWeek(1), ...standardWeek(2), ...standardWeek(3)];
    final asOf = dayIn(3, DateTime.sunday);

    final longRuns = runs.where((r) => r.type == RunType.long).toList();
    final partial = scorer.compute(
      plan: plan,
      plannedRuns: runs,
      completedRuns: [done(longRuns.first.id, longRuns.first.targetDistanceKm!)],
      asOf: asOf,
    );
    final more = scorer.compute(
      plan: plan,
      plannedRuns: runs,
      completedRuns:
          longRuns.map((r) => done(r.id, r.targetDistanceKm!)).toList(),
      asOf: asOf,
    );
    expect(more.score, greaterThan(partial.score));
  });

  group('no signal', () {
    test('a brand-new plan reports "not enough data", never 75/"On track"', () {
      final plan = testPlan();
      final runs = [...standardWeek(1), ...standardWeek(2)];

      final score = scorer.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: const [],
        // Before anything has come due.
        asOf: kStart,
      );

      expect(score.hasSignal, isFalse);
      expect(score.band, ReadinessBand.notEnoughData);
      expect(score.label, 'Not enough data yet');
      // The headline defect: vacuous 1.0 ratios used to total exactly 75.
      expect(score.score, isNot(75));
    });

    test('holds back until minDueRuns have come due', () {
      final plan = testPlan();
      final runs = standardWeek(1);

      // Only Monday's easy run has passed.
      final early = scorer.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: const [],
        asOf: dayIn(1, DateTime.tuesday),
      );
      expect(early.hasSignal, isFalse);

      final later = scorer.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: const [],
        asOf: dayIn(2, DateTime.monday),
      );
      expect(later.hasSignal, isTrue);
    });

    test('a plan with no runs at all has no signal', () {
      final score = scorer.compute(
        plan: testPlan(),
        plannedRuns: const [],
        completedRuns: const [],
        asOf: kStart,
      );
      expect(score.band, ReadinessBand.notEnoughData);
    });
  });

  group('derived peak long run', () {
    /// A half-marathon plan whose long-run ladder peaks at 19 km.
    TrainingPlan halfPlan() => TrainingPlan(
          id: 1,
          name: 'Half',
          raceDate: addDays(kStart, 9 * 7),
          raceDistanceKm: 21.1,
          startDate: kStart,
          longRunDay: DateTime.saturday,
          status: PlanStatus.active,
          createdAt: kStart,
        );

    test('a half-marathon athlete can reach a perfect longest-run component',
        () {
      final plan = halfPlan();
      final runs = [
        ...standardWeek(1, longKm: 17),
        ...standardWeek(2, longKm: 19),
      ];
      final completed = runs
          .where((r) => r.type.isRun)
          .map((r) => done(r.id, r.targetDistanceKm!))
          .toList();

      final score = scorer.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: completed,
        asOf: dayIn(2, DateTime.sunday),
      );

      // Against the old hardcoded 32 km peak this component capped at 0.59
      // and the score could never reach 100.
      expect(score.longestRunKm, 1.0);
      expect(score.score, 100);
    });

    test('race day is excluded from the derived peak', () {
      final plan = halfPlan();
      final runs = [
        ...standardWeek(1, longKm: 17),
        ...standardWeek(2, longKm: 19),
        // The generator schedules the race itself as a long run.
        run(date: plan.raceDate, type: RunType.long, km: 21.1),
      ];
      final completed = runs
          .where((r) => r.type.isRun && r.targetDistanceKm! <= 19)
          .map((r) => done(r.id, r.targetDistanceKm!))
          .toList();

      final score = scorer.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: completed,
        asOf: dayIn(2, DateTime.sunday),
      );

      // Peak stays 19, not 21.1 — a naive max would reproduce the bug.
      expect(score.longestRunKm, 1.0);
    });

    test('falls back to 0.75x race distance when the plan has no long runs',
        () {
      final plan = testPlan();
      final runs = [
        for (var w = 1; w <= 2; w++) ...[
          run(date: dayIn(w, DateTime.monday), type: RunType.easy, km: 6),
          run(date: dayIn(w, DateTime.wednesday), type: RunType.steady, km: 10),
        ],
      ];

      final score = scorer.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: runs.map((r) => done(r.id, r.targetDistanceKm!)).toList(),
        asOf: dayIn(3, DateTime.monday),
      );

      // No long run has come due, so that component is absent rather than 0.
      expect(score.longestRunKm, isNull);
      expect(score.longRunCompletion, isNull);
      expect(score.score, 100);
    });
  });

  group('walks and hikes', () {
    test('do not inflate the longest run or the volume completed', () {
      final plan = testPlan();
      final runs = [...standardWeek(1), ...standardWeek(2)];

      CompletedRun walk(double km) => CompletedRun(
            id: 9000,
            date: dayIn(1, DateTime.sunday),
            actualDistanceKm: km,
            durationSec: (km * 700).round(),
            avgPaceSecPerKm: 700,
            source: RunSource.manual,
            activityType: ActivityType.hike,
          );

      final withoutWalk = scorer.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: const [],
        asOf: dayIn(2, DateTime.sunday),
      );
      final withWalk = scorer.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns: [walk(25)],
        asOf: dayIn(2, DateTime.sunday),
      );

      expect(withWalk.score, withoutWalk.score);
      expect(withWalk.longestRunKm, 0.0);
    });
  });

  group('due semantics', () {
    test('today\'s still-pending long run does not dent consistency', () {
      final plan = testPlan();
      final runs = [...standardWeek(1), ...standardWeek(2)];
      // It is Saturday of week 2. Everything before today is done; today's long
      // run has not been logged yet.
      final asOf = dayIn(2, DateTime.saturday);
      final alreadyDue =
          runs.where((r) => r.scheduledDate.isBefore(asOf)).toList();

      final score = scorer.compute(
        plan: plan,
        plannedRuns: runs,
        completedRuns:
            alreadyDue.map((r) => done(r.id, r.targetDistanceKm!)).toList(),
        asOf: asOf,
      );

      // Counting today's run as already missed would make this 5/6 = 0.83.
      expect(score.consistency, 1.0);
      expect(score.hasSignal, isTrue);
    });

    test('a dropped run is not counted as missed', () {
      final plan = testPlan();
      final runs = [...standardWeek(1), ...standardWeek(2)];
      final kept = runs.where((r) => r.type != RunType.steady).toList();

      final allDropped = [
        for (final r in runs)
          if (r.type == RunType.steady)
            r.copyWith(status: RunStatus.dropped)
          else
            r,
      ];

      final score = scorer.compute(
        plan: plan,
        plannedRuns: allDropped,
        completedRuns:
            kept.map((r) => done(r.id, r.targetDistanceKm!)).toList(),
        asOf: dayIn(2, DateTime.sunday),
      );

      // The engine shed the steady runs; everything asked of the athlete was done.
      expect(score.consistency, 1.0);
      expect(score.band, ReadinessBand.onTrack);
    });
  });
}
