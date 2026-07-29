// `isNull`/`isNotNull` collide with drift's column expressions.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/data/db/app_database.dart';
import 'package:paceshift/data/health/health_service.dart';
import 'package:paceshift/data/repositories/sync_repository.dart';
import 'package:paceshift/domain/models/app_settings.dart';
import 'package:paceshift/data/db/mappers.dart';
import 'package:paceshift/domain/models/enums.dart';

/// Stands in for the platform health store so these tests exercise the
/// import/match/persist path without touching Health Connect or HealthKit.
class _FakeHealthService extends HealthService {
  _FakeHealthService(this.sessions, {this.permission = true});

  final List<WorkoutSession> sessions;
  final bool? permission;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool?> permissionStatus() async => permission;

  @override
  Future<bool> requestPermissions() async => permission ?? true;

  @override
  Future<List<WorkoutSession>> fetchWorkouts({required DateTime since}) async =>
      sessions;
}

final _today = DateTime(2026, 3, 2);

WorkoutSession _session(
  String id, {
  required DateTime date,
  double km = 10,
  int durationSec = 3000,
  ActivityType type = ActivityType.run,
}) =>
    WorkoutSession(
      externalId: id,
      date: date,
      distanceKm: km,
      durationSec: durationSec,
      activityType: type,
    );

Future<int> _seedPlan(AppDatabase db) async {
  await db.settingsDao.upsertSettings(const AppSettings().toCompanion());
  return db.planDao.insertPlan(TrainingPlansCompanion.insert(
    name: 'Test plan',
    raceDate: _today.add(const Duration(days: 90)),
    raceDistanceKm: 42.2,
    startDate: _today.subtract(const Duration(days: 7)),
    longRunDay: 7,
    status: PlanStatus.active,
    createdAt: _today,
  ));
}

Future<int> _seedRun(
  AppDatabase db,
  int planId, {
  required DateTime date,
  RunType type = RunType.easy,
  double? km = 10,
}) =>
    db.runsDao.insertPlannedRun(PlannedRunsCompanion.insert(
      planId: planId,
      scheduledDate: date,
      originalDate: date,
      weekIndex: 2,
      type: type,
      status: RunStatus.pending,
      targetDistanceKm: Value(km),
    ));

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<SyncResult> sync(List<WorkoutSession> sessions) =>
      SyncRepository(db, _FakeHealthService(sessions)).syncNow();

  test('a matching workout completes the planned run', () async {
    final planId = await _seedPlan(db);
    final runId = await _seedRun(db, planId, date: _today);

    final result = await sync([_session('a', date: _today)]);

    expect(result.isSuccess, isTrue);
    expect(result.newRuns, 1);
    final runs = await db.runsDao.getPlannedRuns(planId);
    expect(runs.single.status, RunStatus.completed);
    final completed = await db.runsDao.getCompletedForPlannedRun(runId);
    expect(completed, isNotNull);
    expect(completed!.source, RunSource.healthConnect);
  });

  test('two workouts on one day cannot both claim the same planned run',
      () async {
    final planId = await _seedPlan(db);
    await _seedRun(db, planId, date: _today);

    final result = await sync([
      _session('a', date: _today),
      _session('b', date: _today),
    ]);

    expect(result.newRuns, 2, reason: 'both are still imported');
    final linked = (await db.runsDao.watchCompletedRuns().first)
        .where((c) => c.plannedRunId != null)
        .toList();
    expect(linked, hasLength(1),
        reason: 'only one may satisfy the single planned run');
  });

  test('a suggestion does not block a confident match for the same run',
      () async {
    final planId = await _seedPlan(db);
    await _seedRun(db, planId, date: _today, type: RunType.long, km: 30);

    // The short jog can only be a suggestion; the 29 km run is unmistakably
    // the long run and must win regardless of processing order.
    final result = await sync([
      _session('jog', date: _today, km: 4),
      _session('long', date: _today, km: 29),
    ]);

    expect(result.needsConfirmation, 1);
    final runs = await db.runsDao.getPlannedRuns(planId);
    expect(runs.single.status, RunStatus.completed);
    final completed = await db.runsDao.watchCompletedRuns().first;
    final attached = completed.where((c) => c.plannedRunId != null).single;
    expect(attached.externalId, 'long');
  });

  test('an ambiguous match is stored as a suggestion, not an attachment',
      () async {
    final planId = await _seedPlan(db);
    await _seedRun(db, planId, date: _today, type: RunType.long, km: 30);

    // 4 km against a 30 km long run: plausible as an extra, implausible as
    // "the long run is done".
    final result = await sync([_session('a', date: _today, km: 4)]);

    expect(result.needsConfirmation, 1);
    final runs = await db.runsDao.getPlannedRuns(planId);
    expect(runs.single.status, RunStatus.pending,
        reason: 'a short jog must not mark the long run done');
    final completed = (await db.runsDao.watchCompletedRuns().first).single;
    expect(completed.plannedRunId, isNull);
    expect(completed.suggestedPlannedRunId, runs.single.id);
  });

  test('a workout the day before claims the planned run', () async {
    final planId = await _seedPlan(db);
    final sunday = _today.add(const Duration(days: 1));
    await _seedRun(db, planId, date: sunday, type: RunType.long, km: 24);

    await sync([_session('a', date: _today, km: 23)]);

    final runs = await db.runsDao.getPlannedRuns(planId);
    expect(runs.single.status, RunStatus.completed);
  });

  test('re-syncing the same workout does not duplicate it', () async {
    final planId = await _seedPlan(db);
    await _seedRun(db, planId, date: _today);

    await sync([_session('a', date: _today)]);
    final second = await sync([_session('a', date: _today)]);

    expect(second.newRuns, 0);
    expect(await db.runsDao.watchCompletedRuns().first, hasLength(1));
  });

  test('walks are imported but never satisfy a planned run', () async {
    final planId = await _seedPlan(db);
    await _seedRun(db, planId, date: _today);

    final result =
        await sync([_session('a', date: _today, type: ActivityType.walk)]);

    expect(result.newRuns, 0, reason: 'walks are not reported as runs');
    final runs = await db.runsDao.getPlannedRuns(planId);
    expect(runs.single.status, RunStatus.pending);
    expect(await db.runsDao.watchCompletedRuns().first, hasLength(1));
  });

  test('attaching to a missed run flags that the plan needs settling', () async {
    final planId = await _seedPlan(db);
    final runId = await _seedRun(db, planId, date: _today);
    await db.runsDao.updatePlannedRun(
      runId,
      const PlannedRunsCompanion(status: Value(RunStatus.missed)),
    );

    final result = await sync([_session('a', date: _today)]);

    expect(result.recoveredMissedRun, isTrue);
    final runs = await db.runsDao.getPlannedRuns(planId);
    expect(runs.single.status, RunStatus.completed);
  });

  group('permissions', () {
    test('an automatic sync never prompts when access was refused', () async {
      await _seedPlan(db);
      final health = _FakeHealthService(const [], permission: false);
      final result = await SyncRepository(db, health)
          .syncNow(trigger: SyncTrigger.automatic);
      expect(result.status, SyncStatus.permissionDenied);
    });

    test('undetermined access (iOS) is only prompted once', () async {
      await _seedPlan(db);
      final health = _FakeHealthService(const [], permission: null);
      final repo = SyncRepository(db, health);

      final first = await repo.syncNow();
      expect(first.isSuccess, isTrue);
      expect((await db.settingsDao.getSettings())?.healthPromptedAt, isNotNull);

      // Having asked once, later automatic syncs proceed instead of bailing —
      // Apple never reports READ grants, so the read itself is the only truth.
      final second = await repo.syncNow(trigger: SyncTrigger.automatic);
      expect(second.isSuccess, isTrue);
    });
  });

  test('syncIfStale skips inside the throttle window', () async {
    await _seedPlan(db);
    await db.settingsDao.updateLastSync(DateTime.now());
    final result = await SyncRepository(db, _FakeHealthService(const []))
        .syncIfStale(minInterval: const Duration(minutes: 15));
    expect(result.status, SyncStatus.skipped);
  });
}
