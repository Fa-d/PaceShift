import 'package:drift/drift.dart';

import '../../core/date_utils.dart';
import '../../domain/models/completed_run.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Persists and exposes planned and completed runs.
class RunRepository {
  RunRepository(this._db);

  final AppDatabase _db;

  RunsDao get _runs => _db.runsDao;

  /// Reactive stream of all planned runs for [planId], ordered by date.
  Stream<List<PlannedRun>> watchPlannedRuns(int planId) =>
      _runs.watchPlannedRuns(planId).map((rows) => rows.map((r) => r.toDomain()).toList());

  Future<List<PlannedRun>> getPlannedRuns(int planId) async =>
      (await _runs.getPlannedRuns(planId)).map((r) => r.toDomain()).toList();

  /// Reactive stream of completed runs (newest first).
  Stream<List<CompletedRun>> watchCompletedRuns() =>
      _runs.watchCompletedRuns().map((rows) => rows.map((r) => r.toDomain()).toList());

  /// Marks [run] completed and records a manual [CompletedRun]. If
  /// [distanceKm]/[durationSec] are omitted, the planned targets are used.
  Future<void> logManualCompletion(
    PlannedRun run, {
    double? distanceKm,
    int? durationSec,
    int? avgHr,
    int? maxHr,
    String? notes,
    DateTime? onDate,
  }) async {
    final date = dateOnly(onDate ?? run.scheduledDate);
    final dist = distanceKm ?? run.targetDistanceKm ?? 0;
    final dur = durationSec ?? ((run.targetDurationMin ?? 0) * 60);
    await _db.transaction(() async {
      await _runs.insertCompletedRun(CompletedRunsCompanion(
        plannedRunId: Value(run.id),
        date: Value(date),
        actualDistanceKm: Value(dist),
        durationSec: Value(dur),
        avgPaceSecPerKm:
            Value(computeAvgPaceSecPerKm(distanceKm: dist, durationSec: dur)),
        avgHr: Value(avgHr),
        maxHr: Value(maxHr),
        source: const Value(RunSource.manual),
        externalId: const Value(null),
      ));
      await _runs.updatePlannedRun(
        run.id,
        PlannedRunsCompanion(
          status: const Value(RunStatus.completed),
          notes: notes == null ? const Value.absent() : Value(notes),
        ),
      );
    });
  }

  /// Logs an extra/unplanned manual run not tied to any planned run.
  Future<void> logExtraRun({
    required DateTime date,
    required double distanceKm,
    required int durationSec,
    int? avgHr,
    int? maxHr,
    String? notes,
  }) async {
    await _runs.insertCompletedRun(CompletedRunsCompanion(
      plannedRunId: const Value(null),
      date: Value(dateOnly(date)),
      actualDistanceKm: Value(distanceKm),
      durationSec: Value(durationSec),
      avgPaceSecPerKm:
          Value(computeAvgPaceSecPerKm(distanceKm: distanceKm, durationSec: durationSec)),
      avgHr: Value(avgHr),
      maxHr: Value(maxHr),
      source: const Value(RunSource.manual),
    ));
  }

  /// Completes [runId] exactly as planned — the one-tap path.
  ///
  /// Use this, not [updateRunStatus], whenever a run is *finished*. Flipping
  /// the status alone records no distance and no duration, so the run silently
  /// contributes nothing to stats, streaks, the fitness estimate or the race
  /// prediction: it looks done and counts for nothing. [logManualCompletion]
  /// falls back to the planned targets, which is exactly what "did it as
  /// planned" means.
  Future<void> logAsPlanned(int runId) async {
    final row = await _runs.getPlannedRun(runId);
    if (row == null) return;
    await logManualCompletion(row.toDomain());
  }

  /// Sets a planned run's lifecycle status without recording an actual.
  ///
  /// For status transitions only (e.g. reopening a run). To mark a run
  /// *finished*, use [logAsPlanned] or [logManualCompletion].
  Future<void> updateRunStatus(int runId, RunStatus status) =>
      _runs.updatePlannedRun(runId, PlannedRunsCompanion(status: Value(status)));

  // ---- Reconciling synced runs ----

  /// Synced runs carrying a suggested planned-run match the user hasn't ruled on.
  Stream<List<CompletedRun>> watchUnconfirmedRuns() => _runs
      .watchUnconfirmedRuns()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  /// Accepts a suggested match: links the completed run to the planned run and
  /// marks it done.
  Future<void> confirmSuggestedMatch(CompletedRun run) async {
    final plannedRunId = run.suggestedPlannedRunId;
    if (plannedRunId == null) return;
    await _db.transaction(() async {
      await _runs.updateCompletedRun(
        run.id,
        CompletedRunsCompanion(
          plannedRunId: Value(plannedRunId),
          suggestedPlannedRunId: const Value(null),
        ),
      );
      await _runs.updatePlannedRun(
        plannedRunId,
        const PlannedRunsCompanion(status: Value(RunStatus.completed)),
      );
    });
  }

  /// Rejects a suggested match — the workout stays as an unattached extra run.
  Future<void> rejectSuggestedMatch(int completedRunId) => _runs.updateCompletedRun(
        completedRunId,
        const CompletedRunsCompanion(suggestedPlannedRunId: Value(null)),
      );

  /// Undoes an automatic match: unlinks the completed run and reopens the
  /// planned run so the engine can reschedule it.
  Future<void> detachCompletedRun(CompletedRun run) async {
    final plannedRunId = run.plannedRunId;
    if (plannedRunId == null) return;
    await _db.transaction(() async {
      await _runs.updateCompletedRun(
        run.id,
        const CompletedRunsCompanion(plannedRunId: Value(null)),
      );
      await _runs.updatePlannedRun(
        plannedRunId,
        const PlannedRunsCompanion(status: Value(RunStatus.pending)),
      );
    });
  }
}
