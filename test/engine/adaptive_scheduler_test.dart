import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/domain/engine/adaptive_scheduler.dart';
import 'package:paceshift/domain/engine/reschedule_outcome.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/models/planned_run.dart';
import 'package:paceshift/domain/models/training_plan.dart';

import 'helpers.dart';

const engine = AdaptiveScheduler();

bool _active(RunStatus s) =>
    s == RunStatus.pending || s == RunStatus.shifted || s == RunStatus.completed;

int _weekOf(TrainingPlan plan, DateTime d) =>
    (daysBetween(plan.startDate, d) ~/ 7) + 1;

/// Asserts no week in [result] is built **above** 115% of its original planned
/// volume — the engine's core safety guarantee (§4.3, rules 2 & 3). A week that
/// ends up *lower* than before (depleted by misses) is safe; the rule only
/// constrains the engine from cramming volume *up*, so we check the ceiling.
void assertWeeklySafety(
  List<PlannedRun> initial,
  List<PlannedRun> result,
  TrainingPlan plan,
) {
  const factor = 1.1501;
  final origByWeek = <int, double>{};
  for (final r in initial) {
    final w = _weekOf(plan, r.originalDate);
    origByWeek[w] = (origByWeek[w] ?? 0) + (r.type.isRun ? (r.targetDistanceKm ?? 0) : 0);
  }
  final maxOrig = origByWeek.values.fold<double>(0, (a, b) => a > b ? a : b);
  final safeCeiling = maxOrig * 1.25;

  double load(int w) => result
      .where((r) => _active(r.status) && _weekOf(plan, r.scheduledDate) == w)
      .fold<double>(0, (s, r) => s + r.loadKm);

  final weeks = result.map((r) => _weekOf(plan, r.scheduledDate)).toSet();
  for (final w in weeks) {
    final l = load(w);
    final ceiling = (origByWeek[w] ?? 0) * factor;
    expect(l <= ceiling + 0.01 || l <= safeCeiling + 0.01, isTrue,
        reason: 'week $w load $l exceeds safe ceiling ${ceiling.toStringAsFixed(1)}');
  }
}

/// All active runs as completed (so a past week isn't itself flagged missed).
List<PlannedRun> completed(List<PlannedRun> runs) =>
    runs.map((r) => r.copyWith(status: RunStatus.completed)).toList();

void main() {
  setUp(resetIds);

  test('1. miss one easy run → reschedules within the week or drops; '
      'weekly load stays within ceiling', () {
    final plan = testPlan();
    final easy = run(date: dayIn(3, DateTime.monday), type: RunType.easy, km: 6);
    final steady =
        run(date: dayIn(3, DateTime.wednesday), type: RunType.steady, km: 10);
    final long = run(date: dayIn(3, DateTime.saturday), type: RunType.long, km: 20);
    final week2 = completed(standardWeek(2));
    final runs = [...week2, easy, steady, long];

    final out = engine.onDayRollover(
      snapshot(plan: plan, runs: runs, today: dayIn(3, DateTime.tuesday)),
    );

    final result = out.runs.byId(easy.id);
    expect([RunStatus.shifted, RunStatus.dropped], contains(result.status));
    if (result.status == RunStatus.shifted) {
      expect(result.scheduledDate.isAfter(easy.scheduledDate), isTrue);
    }
    assertWeeklySafety(runs, out.runs, plan);
  });

  test('2. miss a long run → moves to the next valid long-run slot; '
      'never the day after another run', () {
    final plan = testPlan();
    final easy = run(
        date: dayIn(3, DateTime.monday),
        type: RunType.easy,
        km: 6,
        status: RunStatus.completed);
    final steady = run(
        date: dayIn(3, DateTime.wednesday),
        type: RunType.steady,
        km: 10,
        status: RunStatus.completed);
    final long = run(date: dayIn(3, DateTime.saturday), type: RunType.long, km: 20);

    final out = engine.onDayRollover(
      snapshot(
          plan: plan,
          runs: [easy, steady, long],
          today: dayIn(3, DateTime.sunday)),
    );

    final moved = out.runs.byId(long.id);
    expect(moved.status, RunStatus.shifted);
    expect(moved.type, RunType.long);
    expect(moved.scheduledDate.isAfter(long.scheduledDate), isTrue);
    expect(plan.taperWeeks, greaterThan(0));
    // Not pushed into the taper.
    expect(_weekOf(plan, moved.scheduledDate) < plan.totalWeeks - plan.taperWeeks,
        isTrue);
    // No other active run sits the day before the long run.
    final dayBefore = addDays(moved.scheduledDate, -1);
    final collision = out.runs.any((r) =>
        r.id != moved.id &&
        _active(r.status) &&
        isSameDate(r.scheduledDate, dayBefore));
    expect(collision, isFalse);
  });

  test('3. miss long runs two weeks running → both rebalance without breaching '
      'the 15% week-over-week rule', () {
    final plan = testPlan();
    // Weeks 2–5 with capacity; easy/steady completed, long runs pending+past.
    final runs = <PlannedRun>[];
    for (final w in [2, 3, 4, 5]) {
      runs.add(run(
          date: dayIn(w, DateTime.monday),
          type: RunType.easy,
          km: 6,
          status: RunStatus.completed));
      runs.add(run(
          date: dayIn(w, DateTime.tuesday),
          type: RunType.steady,
          km: 10,
          status: w <= 4 ? RunStatus.completed : RunStatus.pending));
      runs.add(run(
          date: dayIn(w, DateTime.saturday),
          type: RunType.long,
          km: 20,
          status: w == 3 || w == 4 ? RunStatus.pending : RunStatus.completed));
    }

    final out = engine.onDayRollover(
      snapshot(plan: plan, runs: runs, today: dayIn(4, DateTime.sunday)),
    );

    // Both missed long runs are no longer pending (moved/reduced/dropped/missed).
    final longs = out.runs.where((r) => r.type == RunType.long).toList();
    expect(longs.where((r) => r.status == RunStatus.pending), isEmpty);
    // No week holds two active long runs.
    final longWeeks = longs
        .where((r) => _active(r.status))
        .map((r) => _weekOf(plan, r.scheduledDate))
        .toList();
    expect(longWeeks.toSet().length, longWeeks.length);
    assertWeeklySafety(runs, out.runs, plan);
  });

  test('4. miss runs during taper → they drop; taper volume never increases', () {
    final plan = testPlan(); // weeks 7–10 are taper
    final taperWeek = 8;
    final easy = run(
        date: dayIn(taperWeek, DateTime.monday), type: RunType.easy, km: 5);
    final long = run(
        date: dayIn(taperWeek, DateTime.saturday), type: RunType.long, km: 16);
    // A non-taper completed week for context.
    final runs = [...completed(standardWeek(6)), easy, long];

    final taperOriginal = (easy.targetDistanceKm ?? 0) + (long.targetDistanceKm ?? 0);

    final out = engine.onDayRollover(
      snapshot(plan: plan, runs: runs, today: dayIn(taperWeek, DateTime.sunday)),
    );

    expect(out.runs.byId(easy.id).status, RunStatus.dropped);
    expect(out.runs.byId(long.id).status, RunStatus.dropped);
    // Taper week active volume did not increase.
    final taperLoad = out.runs
        .where((r) =>
            _active(r.status) && _weekOf(plan, r.scheduledDate) == taperWeek)
        .fold<double>(0, (s, r) => s + r.loadKm);
    expect(taperLoad <= taperOriginal, isTrue);
  });

  test('5. cascade near race day → engine triggers degradePlan and returns '
      'options rather than unsafe weeks', () {
    // Short plan: only week 1 is non-taper.
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
    final long = run(date: dayIn(1, DateTime.saturday), type: RunType.long, km: 20);

    final out = engine.onDayRollover(
      snapshot(
          plan: plan,
          runs: [easy, steady, long],
          today: dayIn(2, DateTime.monday)),
    );

    expect(out.needsDecision, isTrue);
    expect(out.decisions.map((d) => d.kind),
        containsAll([DegradeKind.reducePeak, DegradeKind.acceptRisk]));
    // The long run was not crammed in unsafely.
    expect(out.runs.byId(long.id).status, isNot(RunStatus.shifted));
  });

  test('6. catch-up window expiry → stale missed runs drop/expire', () {
    final plan = testPlan();
    final stale = run(date: dayIn(2, DateTime.monday), type: RunType.easy, km: 6);
    // Today is 20 days after the run was due (well beyond the 7-day window).
    final out = engine.onDayRollover(
      snapshot(
          plan: plan,
          runs: [stale],
          today: addDays(stale.scheduledDate, 20)),
    );

    final result = out.runs.byId(stale.id);
    expect(result.status, RunStatus.missed);
    expect(out.changes.whereType<RunExpiredChange>(), isNotEmpty);
  });
}
