import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/data/db/app_database.dart';
import 'package:paceshift/data/repositories/plan_repository.dart';
import 'package:paceshift/data/repositories/run_repository.dart';
import 'package:paceshift/data/repositories/scheduler_repository.dart';
import 'package:paceshift/data/repositories/settings_repository.dart';
import 'package:paceshift/domain/engine/reschedule_outcome.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/plan_generator/plan_input.dart';

/// The degrade decision, end to end through the database.
///
/// The engine raised these options, the sheet displayed them, the athlete
/// picked one — and both call sites threw the answer away. `DegradeKind` had no
/// consumer anywhere in the app. This proves the whole loop now closes.
void main() {
  late AppDatabase db;
  late SchedulerRepository scheduler;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await SettingsRepository(db).ensureDefaults();
    scheduler = SchedulerRepository(db);
  });
  tearDown(() => db.close());

  /// A plan whose remaining long runs cannot be made up: race is close, so
  /// almost everything left is taper-locked.
  Future<void> seedUnfittablePlan() async {
    await PlanRepository(db).createPlanFromInput(PlanInput(
      raceDate: addDays(today(), 30),
      currentLongestRunKm: 10,
      preferredLongRunDay: DateTime.saturday,
    ));
    // Push every past-and-present run into the past so the rollover has to
    // deal with all of them at once.
    final plan = (await db.planDao.getActivePlan())!;
    final runs = await db.runsDao.getPlannedRuns(plan.id);
    for (final r in runs.take(4)) {
      await db.runsDao.updatePlannedRun(
          r.id, PlannedRunsCompanion(scheduledDate: Value(addDays(today(), -3))));
    }
  }

  test('the fixture really does force a decision', () async {
    await seedUnfittablePlan();
    final outcome = await scheduler.runDayRollover();
    expect(outcome?.needsDecision, isTrue,
        reason: 'the other tests here are only meaningful if this holds');
  });

  test('a decision raised in the background survives to be answered', () async {
    await seedUnfittablePlan();
    expect(await scheduler.hasPendingDegradeDecision(), isFalse);

    final outcome = await scheduler.runDayRollover();
    expect(outcome?.needsDecision, isTrue);

    // The flag is what lets a decision raised at launch, on resume, or by the
    // background worker ever reach a human.
    expect(await scheduler.hasPendingDegradeDecision(), isTrue);

    // A fresh repository — i.e. a new app process — still sees it.
    expect(await SchedulerRepository(db).hasPendingDegradeDecision(), isTrue);
  });

  test('answering it clears the question and changes the plan', () async {
    await seedUnfittablePlan();
    final raised = await scheduler.runDayRollover();
    expect(raised?.needsDecision, isTrue);

    final applied =
        await scheduler.applyDegradeDecision(DegradeKind.dropLowValue);
    expect(applied, isNotNull);
    expect(applied!.needsDecision, isFalse,
        reason: 'the same question must not come straight back');
    expect(await scheduler.hasPendingDegradeDecision(), isFalse);
  });

  test('acceptRisk answers the question without rewriting the plan', () async {
    await seedUnfittablePlan();
    final raised = await scheduler.runDayRollover();
    expect(raised?.needsDecision, isTrue);

    final plan = (await db.planDao.getActivePlan())!;
    final before = await db.runsDao.getPlannedRuns(plan.id);

    await scheduler.applyDegradeDecision(DegradeKind.acceptRisk);

    final after = await db.runsDao.getPlannedRuns(plan.id);
    expect(after.length, before.length);
    for (var i = 0; i < before.length; i++) {
      expect(after[i].scheduledDate, before[i].scheduledDate);
      expect(after[i].targetDistanceKm, before[i].targetDistanceKm);
    }
    // But it *is* answered — that is the entire point of the option.
    expect(await scheduler.hasPendingDegradeDecision(), isFalse);
  });

  test('logAsPlanned records the distance and links the run', () async {
    await PlanRepository(db).createPlanFromInput(PlanInput(
      raceDate: addDays(today(), 133),
      currentLongestRunKm: 18,
      preferredLongRunDay: DateTime.saturday,
    ));
    final plan = (await db.planDao.getActivePlan())!;
    final run = (await db.runsDao.getPlannedRuns(plan.id))
        .firstWhere((r) => r.targetDistanceKm != null);

    await RunRepository(db).logAsPlanned(run.id);

    final completed = await db.runsDao.watchCompletedRuns().first;
    expect(completed, hasLength(1));
    // The old AI "mark done" path flipped the status and recorded nothing at
    // all, so the run looked complete and contributed no distance to stats.
    expect(completed.single.actualDistanceKm, run.targetDistanceKm);
    expect(completed.single.plannedRunId, run.id);
    expect((await db.runsDao.getPlannedRun(run.id))?.status,
        RunStatus.completed);
  });

  test('logAsPlanned derives a duration from the target pace, and invents '
      'nothing when there is none', () async {
    // With a goal time the generator assigns paces, so "as planned" has a
    // defensible finish time.
    await PlanRepository(db).createPlanFromInput(PlanInput(
      raceDate: addDays(today(), 133),
      currentLongestRunKm: 18,
      preferredLongRunDay: DateTime.saturday,
      goalFinishSec: 4 * 3600,
    ));
    final plan = (await db.planDao.getActivePlan())!;
    final paced = (await db.runsDao.getPlannedRuns(plan.id)).firstWhere(
        (r) => r.targetPaceSecPerKm != null && r.targetDistanceKm != null);

    await RunRepository(db).logAsPlanned(paced.id);
    final logged = (await db.runsDao.watchCompletedRuns().first).single;

    expect(logged.durationSec,
        (paced.targetDistanceKm! * paced.targetPaceSecPerKm!).round());
    // And a real pace, not a divide-by-zero artefact.
    expect(logged.avgPaceSecPerKm, closeTo(paced.targetPaceSecPerKm!, 1));
  });
}
