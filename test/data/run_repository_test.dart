import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/data/db/app_database.dart';
import 'package:paceshift/data/repositories/plan_repository.dart';
import 'package:paceshift/data/repositories/run_repository.dart';
import 'package:paceshift/data/repositories/settings_repository.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/models/planned_run.dart';
import 'package:paceshift/domain/plan_generator/plan_input.dart';

/// `RunRepository` had no test file, yet it writes every figure the progress
/// screen reports. These cover the duration/pace derivation in particular,
/// where `durationSec` is non-nullable and 0 is the "unknown" sentinel.
void main() {
  late AppDatabase db;
  late RunRepository repo;
  late List<PlannedRun> runs;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await SettingsRepository(db).ensureDefaults();
    final planId = await PlanRepository(db).createPlanFromInput(PlanInput(
      raceDate: addDays(today(), 133),
      currentLongestRunKm: 18,
      preferredLongRunDay: DateTime.saturday,
    ));
    repo = RunRepository(db);
    runs = await repo.getPlannedRuns(planId);
  });

  tearDown(() => db.close());

  Future<List<CompletedRunRow>> completed() =>
      db.select(db.completedRuns).get();

  group('logAsPlanned', () {
    test('derives a duration from the target pace when there is one', () async {
      final paced = runs.firstWhere((r) =>
          r.type.isRun && r.targetDistanceKm != null && r.targetPaceSecPerKm != null,
          orElse: () => runs.firstWhere((r) => r.type.isRun));

      if (paced.targetPaceSecPerKm == null) {
        // This plan carries no goal time, so patch a pace onto one run.
        await db.update(db.plannedRuns).replace(
              await (db.select(db.plannedRuns)
                    ..where((t) => t.id.equals(paced.id)))
                  .getSingle()
                  .then((row) => row.copyWith(
                      targetPaceSecPerKm: const Value(300.0))),
            );
      }

      await repo.logAsPlanned(paced.id);
      final row = (await completed()).single;

      final km = paced.targetDistanceKm!;
      expect(row.actualDistanceKm, km);
      expect(row.plannedRunId, paced.id);
      expect(row.durationSec, (km * 300).round());
      expect(row.avgPaceSecPerKm, closeTo(300, 0.5));
    });

    test('records distance and links the run', () async {
      final run = runs.firstWhere((r) => r.type.isRun);
      await repo.logAsPlanned(run.id);

      final row = (await completed()).single;
      expect(row.plannedRunId, run.id);
      expect(row.actualDistanceKm, run.targetDistanceKm);

      final updated = await repo.getPlannedRuns(run.planId);
      expect(updated.firstWhere((r) => r.id == run.id).status,
          RunStatus.completed);
    });

    test('is a no-op for an id that does not exist', () async {
      await repo.logAsPlanned(999999);
      expect(await completed(), isEmpty);
    });
  });

  group('unknown duration', () {
    test('stores 0 and a 0 pace, and the row still counts as logged', () async {
      final run = runs.firstWhere((r) => r.type.isRun);
      // Strip both the pace and the target duration so nothing can be derived.
      await (db.update(db.plannedRuns)..where((t) => t.id.equals(run.id))).write(
        const PlannedRunsCompanion(
          targetPaceSecPerKm: Value(null),
          targetDurationMin: Value(null),
        ),
      );

      await repo.logAsPlanned(run.id);
      final row = (await completed()).single;

      // 0 is the documented sentinel — `durationSec` is non-nullable.
      expect(row.durationSec, 0);
      expect(row.avgPaceSecPerKm, 0);
      // The distance was still really run, so it is not discarded.
      expect(row.actualDistanceKm, run.targetDistanceKm);
    });
  });

  group('logManualCompletion', () {
    test('computes pace from the supplied distance and duration', () async {
      final run = runs.firstWhere((r) => r.type.isRun);
      await repo.logManualCompletion(run, distanceKm: 10, durationSec: 3000);

      final row = (await completed()).single;
      expect(row.actualDistanceKm, 10);
      expect(row.durationSec, 3000);
      expect(row.avgPaceSecPerKm, 300);
      expect(row.source, RunSource.manual);
    });
  });

  group('logExtraRun', () {
    test('stores an unlinked run that defaults to an actual run', () async {
      await repo.logExtraRun(
          date: today(), distanceKm: 7.5, durationSec: 2700);

      final row = (await completed()).single;
      expect(row.plannedRunId, null);
      expect(row.actualDistanceKm, 7.5);
      expect(row.activityType, ActivityType.run);
      expect(row.avgPaceSecPerKm, 360);
    });
  });
}
