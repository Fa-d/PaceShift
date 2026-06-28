import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/domain/models/completed_run.dart';
import 'package:paceshift/domain/models/enums.dart';
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
}
