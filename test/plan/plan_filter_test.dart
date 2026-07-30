import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/models/planned_run.dart';
import 'package:paceshift/presentation/plan/plan_filter.dart';

PlannedRun _run({
  required int id,
  required RunType type,
  required RunStatus status,
  required DateTime date,
  double? km,
}) =>
    PlannedRun(
      id: id,
      planId: 1,
      scheduledDate: date,
      originalDate: date,
      weekIndex: 1,
      type: type,
      targetDistanceKm: km,
      status: status,
    );

void main() {
  // As-of date sits between a past run and a future run.
  final asOf = DateTime(2026, 7, 30);
  final past = DateTime(2026, 7, 1);
  final future = DateTime(2026, 8, 15);

  late List<PlannedRun> runs;

  setUp(() {
    runs = [
      _run(id: 1, type: RunType.easy, status: RunStatus.completed, date: past, km: 8),
      _run(id: 2, type: RunType.steady, status: RunStatus.pending, date: future, km: 10),
      _run(id: 3, type: RunType.long, status: RunStatus.pending, date: future, km: 20),
      _run(id: 4, type: RunType.rest, status: RunStatus.pending, date: future),
      _run(id: 5, type: RunType.easy, status: RunStatus.missed, date: past, km: 5),
    ];
  });

  test('an inactive filter returns the list unchanged', () {
    expect(const PlanFilter().apply(runs, asOf), runs);
    expect(const PlanFilter().isActive, isFalse);
  });

  test('runsOnly hides rest / cross / strength', () {
    final result = const PlanFilter(runsOnly: true).apply(runs, asOf);
    expect(result.every((r) => r.type.isRun), isTrue);
    expect(result.length, 4);
    expect(const PlanFilter(runsOnly: true).isActive, isTrue);
  });

  test('remainingOnly keeps only pending, not-yet-due work', () {
    final result = const PlanFilter(remainingOnly: true).apply(runs, asOf);
    // steady + long + rest are pending and in the future; the completed and
    // missed easy runs are excluded.
    expect(result.map((r) => r.id).toSet(), {2, 3, 4});
  });

  test('type filter narrows to the selected run types', () {
    final result =
        const PlanFilter(types: {RunType.easy}).apply(runs, asOf);
    expect(result.map((r) => r.id).toSet(), {1, 5});
  });

  test('runsOnly + remainingOnly compose', () {
    final result = const PlanFilter(runsOnly: true, remainingOnly: true)
        .apply(runs, asOf);
    // Rest excluded by runsOnly; completed/missed excluded by remainingOnly.
    expect(result.map((r) => r.id).toSet(), {2, 3});
  });

  test('matches nothing → empty list', () {
    final allDone = [
      _run(id: 1, type: RunType.easy, status: RunStatus.completed, date: past, km: 8),
      _run(id: 2, type: RunType.long, status: RunStatus.completed, date: past, km: 20),
    ];
    expect(
      const PlanFilter(remainingOnly: true).apply(allDone, asOf),
      isEmpty,
    );
  });

  test('copyWith preserves unmodified fields', () {
    const filter = PlanFilter(runsOnly: true, types: {RunType.long});
    final toggled = filter.copyWith(runsOnly: false);
    expect(toggled.runsOnly, isFalse);
    expect(toggled.types, {RunType.long});
    expect(toggled.remainingOnly, isFalse);
  });
}
