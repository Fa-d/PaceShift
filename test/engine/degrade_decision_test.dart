import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/domain/engine/adaptive_scheduler.dart';
import 'package:paceshift/domain/engine/reschedule_outcome.dart';
import 'package:paceshift/domain/engine/schedule_snapshot.dart';
import 'package:paceshift/domain/models/completed_run.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/models/planned_run.dart';
import 'package:paceshift/domain/models/training_plan.dart';

import 'helpers.dart';

const engine = AdaptiveScheduler();

bool _active(RunStatus s) =>
    s == RunStatus.pending || s == RunStatus.shifted || s == RunStatus.completed;

int _weekOf(TrainingPlan plan, DateTime d) =>
    (daysBetween(plan.startDate, d) ~/ 7) + 1;

/// No week may be built above 115% of its original planned volume — the same
/// guarantee `assertWeeklySafety` enforces for the rollover path. Applying a
/// degrade choice must not become a back door around it.
void assertWeeklySafety(
  List<PlannedRun> initial,
  List<PlannedRun> result,
  TrainingPlan plan,
) {
  const factor = 1.1501;
  final origByWeek = <int, double>{};
  for (final r in initial) {
    final w = _weekOf(plan, r.originalDate);
    origByWeek[w] =
        (origByWeek[w] ?? 0) + (r.type.isRun ? (r.targetDistanceKm ?? 0) : 0);
  }
  final maxOrig = origByWeek.values.fold<double>(0, (a, b) => a > b ? a : b);
  final safeCeiling = maxOrig * 1.25;

  double load(int w) => result
      .where((r) => _active(r.status) && _weekOf(plan, r.scheduledDate) == w)
      .fold<double>(0, (s, r) => s + r.loadKm);

  for (final w in result.map((r) => _weekOf(plan, r.scheduledDate)).toSet()) {
    final l = load(w);
    final ceiling = (origByWeek[w] ?? 0) * factor;
    expect(l <= ceiling + 0.01 || l <= safeCeiling + 0.01, isTrue,
        reason: 'week $w load $l exceeds the safe ceiling');
  }
}

CompletedRun completedRun({required DateTime date, required double km}) =>
    CompletedRun(
      id: 900 + date.day,
      date: dateOnly(date),
      actualDistanceKm: km,
      durationSec: (km * 330).round(),
      avgPaceSecPerKm: 330,
      source: RunSource.manual,
    );

/// A plan where the long run genuinely cannot be redistributed: a short plan
/// whose only non-taper week has already gone by. This is the situation that
/// makes the engine ask rather than decide.
({
  TrainingPlan plan,
  List<PlannedRun> runs,
  PlannedRun long,
  DateTime today,
}) degradedSetup() {
  final plan = testPlan(weeks: 5, taperWeeks: 3);
  final easy = run(
      date: dayIn(1, DateTime.monday),
      type: RunType.easy,
      km: 6,
      status: RunStatus.completed);
  final steady = run(
      date: dayIn(1, DateTime.wednesday),
      type: RunType.steady,
      km: 10,
      status: RunStatus.completed);
  final long =
      run(date: dayIn(1, DateTime.saturday), type: RunType.long, km: 20);
  return (
    plan: plan,
    runs: [easy, steady, long],
    long: long,
    today: dayIn(2, DateTime.monday),
  );
}

/// Runs the rollover that raises the decision, then hands back a snapshot of
/// the *persisted* state — which is what the repository would feed back in when
/// the athlete finally answers.
ScheduleSnapshot afterDecisionRaised(
  TrainingPlan plan,
  List<PlannedRun> runs,
  DateTime today, {
  List<CompletedRun> completed = const [],
}) {
  final raised = engine.onDayRollover(
      snapshot(plan: plan, runs: runs, completed: completed, today: today));
  expect(raised.needsDecision, isTrue,
      reason: 'fixture should produce a degrade decision');
  return snapshot(
      plan: plan, runs: raised.runs, completed: completed, today: today);
}

void main() {
  setUp(resetIds);

  test('the engine offers exactly the three documented options', () {
    expect(AdaptiveScheduler.degradeOptions.map((o) => o.kind), [
      DegradeKind.reducePeak,
      DegradeKind.dropLowValue,
      DegradeKind.acceptRisk,
    ]);
  });

  group('applyDegradeDecision', () {
    test('never re-raises the question — the athlete already answered', () {
      final f = degradedSetup();
      final state = afterDecisionRaised(f.plan, f.runs, f.today);

      for (final kind in DegradeKind.values) {
        final out = engine.applyDegradeDecision(state, kind);
        expect(out.needsDecision, isFalse,
            reason: '$kind must not ask the same question again');
      }
    });

    test('acceptRisk leaves the plan exactly as it was', () {
      final f = degradedSetup();
      final state = afterDecisionRaised(f.plan, f.runs, f.today);

      final out = engine.applyDegradeDecision(state, DegradeKind.acceptRisk);

      expect(out.hasChanges, isFalse);
      for (final before in state.plannedRuns) {
        final after = out.runs.byId(before.id);
        expect(after.status, before.status);
        expect(after.scheduledDate, before.scheduledDate);
        expect(after.targetDistanceKm, before.targetDistanceKm);
      }
    });

    test('reducePeak caps remaining long runs at the demonstrated peak, '
        'grown one jump at a time', () {
      // A 10-week plan whose later long runs assume a base the athlete never
      // built: their longest actual run is 12 km, but week 4 asks for 30 km.
      final plan = testPlan(weeks: 10, taperWeeks: 3);
      final done = [
        ...standardWeek(1, longKm: 12).map(
            (r) => r.copyWith(status: RunStatus.completed)),
      ];
      final missedLong =
          run(date: dayIn(2, DateTime.saturday), type: RunType.long, km: 26);
      final futureLong =
          run(date: dayIn(4, DateTime.saturday), type: RunType.long, km: 30);
      final runs = [...done, missedLong, futureLong];
      final completed = [
        completedRun(date: dayIn(1, DateTime.saturday), km: 12),
      ];

      final state = afterDecisionRaised(
          plan, runs, dayIn(3, DateTime.monday),
          completed: completed);

      final out = engine.applyDegradeDecision(state, DegradeKind.reducePeak);

      final after = out.runs.byId(futureLong.id);
      expect(after.targetDistanceKm, isNotNull);
      expect(after.targetDistanceKm!, lessThan(30),
          reason: 'the unearned peak must come down');
      // Never below the long-run reduction floor — a 3 km "long run" is not a
      // long run, it is a demotivating fiction.
      expect(after.targetDistanceKm!, greaterThanOrEqualTo(0.5 * 30 - 0.01));
      expect(out.changes.whereType<RunReducedChange>(), isNotEmpty);
      assertWeeklySafety(state.plannedRuns, out.runs, plan);
    });

    test('reducePeak does nothing when there is no completed run to '
        'measure against', () {
      final f = degradedSetup();
      final state = afterDecisionRaised(f.plan, f.runs, f.today);

      final out = engine.applyDegradeDecision(state, DegradeKind.reducePeak);

      // With no evidence of what the athlete can handle, guessing a smaller
      // number would be inventing data.
      expect(out.changes.whereType<RunReducedChange>(), isEmpty);
    });

    test('dropLowValue sheds easy work inside the long run’s make-up window, '
        'and nothing outside it', () {
      final plan = testPlan(weeks: 10, taperWeeks: 3);
      final done = standardWeek(1)
          .map((r) => r.copyWith(status: RunStatus.completed))
          .toList();
      final missedLong =
          run(date: dayIn(2, DateTime.saturday), type: RunType.long, km: 30);
      // Inside the 10-day make-up window.
      final nearEasy =
          run(date: dayIn(3, DateTime.tuesday), type: RunType.easy, km: 6);
      // Well outside it — must be untouched.
      final farEasy =
          run(date: dayIn(6, DateTime.tuesday), type: RunType.easy, km: 6);
      final runs = [...done, missedLong, nearEasy, farEasy];

      final state =
          afterDecisionRaised(plan, runs, dayIn(3, DateTime.monday));

      final out = engine.applyDegradeDecision(state, DegradeKind.dropLowValue);

      expect(out.runs.byId(nearEasy.id).status, RunStatus.dropped,
          reason: 'easy work in the window should make room');
      expect(out.runs.byId(farEasy.id).status, isNot(RunStatus.dropped),
          reason: 'the rest of the plan must not be collateral damage');
      assertWeeklySafety(state.plannedRuns, out.runs, plan);
    });

    test('every decision keeps the race date and the taper untouched', () {
      final f = degradedSetup();
      final state = afterDecisionRaised(f.plan, f.runs, f.today);

      for (final kind in DegradeKind.values) {
        final out = engine.applyDegradeDecision(state, kind);
        for (final r in out.runs.where((r) => _active(r.status))) {
          expect(r.scheduledDate.isBefore(f.plan.raceDate), isTrue,
              reason: '$kind placed a run on or after race day');
        }
      }
    });
  });
}
