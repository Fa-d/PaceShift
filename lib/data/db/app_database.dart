import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/models/enums.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The app's local SQLite database (Drift). Exposes reactive (`watch*`) queries
/// that drive the UI automatically, plus DAOs grouping per-feature access.
@DriftDatabase(
  tables: [TrainingPlans, PlannedRuns, CompletedRuns, SettingsRows],
  daos: [PlanDao, RunsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'paceshift'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // v2: structured/pace-based workouts (Phase 6).
          if (from < 2) {
            await m.addColumn(plannedRuns, plannedRuns.targetPaceSecPerKm);
            await m.addColumn(plannedRuns, plannedRuns.segmentsJson);
          }
        },
      );
}

/// Access to the active plan and its planned runs.
@DriftAccessor(tables: [TrainingPlans, PlannedRuns])
class PlanDao extends DatabaseAccessor<AppDatabase> with _$PlanDaoMixin {
  PlanDao(super.db);

  Stream<TrainingPlanRow?> watchActivePlan() {
    final q = select(trainingPlans)
      ..where((t) => t.status.equalsValue(PlanStatus.active))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return q.watchSingleOrNull();
  }

  Future<TrainingPlanRow?> getActivePlan() {
    final q = select(trainingPlans)
      ..where((t) => t.status.equalsValue(PlanStatus.active))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return q.getSingleOrNull();
  }

  Future<int> insertPlan(TrainingPlansCompanion plan) =>
      into(trainingPlans).insert(plan);

  Future<void> archiveAllActivePlans() => (update(trainingPlans)
        ..where((t) => t.status.equalsValue(PlanStatus.active)))
      .write(const TrainingPlansCompanion(status: Value(PlanStatus.archived)));

  Future<void> updatePlanStatus(int planId, PlanStatus status) =>
      (update(trainingPlans)..where((t) => t.id.equals(planId)))
          .write(TrainingPlansCompanion(status: Value(status)));
}

/// Access to planned runs and completed runs.
@DriftAccessor(tables: [PlannedRuns, CompletedRuns])
class RunsDao extends DatabaseAccessor<AppDatabase> with _$RunsDaoMixin {
  RunsDao(super.db);

  Stream<List<PlannedRunRow>> watchPlannedRuns(int planId) {
    final q = select(plannedRuns)
      ..where((t) => t.planId.equals(planId))
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]);
    return q.watch();
  }

  Future<List<PlannedRunRow>> getPlannedRuns(int planId) {
    final q = select(plannedRuns)
      ..where((t) => t.planId.equals(planId))
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]);
    return q.get();
  }

  Stream<List<PlannedRunRow>> watchPlannedRunsOnDate(int planId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final q = select(plannedRuns)
      ..where((t) =>
          t.planId.equals(planId) &
          t.scheduledDate.isBiggerOrEqualValue(start) &
          t.scheduledDate.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]);
    return q.watch();
  }

  Future<int> insertPlannedRun(PlannedRunsCompanion run) =>
      into(plannedRuns).insert(run);

  Future<void> insertPlannedRuns(List<PlannedRunsCompanion> runs) async {
    await batch((b) => b.insertAll(plannedRuns, runs));
  }

  Future<void> deletePlannedRunsForPlan(int planId) =>
      (delete(plannedRuns)..where((t) => t.planId.equals(planId))).go();

  Future<void> updatePlannedRun(int id, PlannedRunsCompanion changes) =>
      (update(plannedRuns)..where((t) => t.id.equals(id))).write(changes);

  // ---- Completed runs ----

  Stream<List<CompletedRunRow>> watchCompletedRuns() {
    final q = select(completedRuns)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return q.watch();
  }

  Future<CompletedRunRow?> getCompletedByExternalId(String externalId) {
    final q = select(completedRuns)
      ..where((t) => t.externalId.equals(externalId))
      ..limit(1);
    return q.getSingleOrNull();
  }

  Future<CompletedRunRow?> getCompletedForPlannedRun(int plannedRunId) {
    final q = select(completedRuns)
      ..where((t) => t.plannedRunId.equals(plannedRunId))
      ..limit(1);
    return q.getSingleOrNull();
  }

  Future<int> insertCompletedRun(CompletedRunsCompanion run) =>
      into(completedRuns).insert(run);
}

/// Access to the single-row settings table.
@DriftAccessor(tables: [SettingsRows])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<SettingsRow?> watchSettings() =>
      (select(settingsRows)..where((t) => t.id.equals(0))).watchSingleOrNull();

  Future<SettingsRow?> getSettings() =>
      (select(settingsRows)..where((t) => t.id.equals(0))).getSingleOrNull();

  Future<void> upsertSettings(SettingsRowsCompanion row) =>
      into(settingsRows).insertOnConflictUpdate(row.copyWith(id: const Value(0)));

  Future<void> updateLastSync(DateTime when) =>
      (update(settingsRows)..where((t) => t.id.equals(0)))
          .write(SettingsRowsCompanion(lastSyncAt: Value(when)));
}
