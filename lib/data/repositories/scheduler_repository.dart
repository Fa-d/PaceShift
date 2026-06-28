import 'package:drift/drift.dart';

import '../../core/date_utils.dart';
import '../../domain/engine/adaptive_scheduler.dart';
import '../../domain/engine/reschedule_outcome.dart';
import '../../domain/engine/schedule_snapshot.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/planned_run.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Bridges the pure [AdaptiveScheduler] to the database: builds a snapshot,
/// runs the engine, and persists the resulting diff in one transaction.
class SchedulerRepository {
  SchedulerRepository(this._db, {AdaptiveScheduler engine = const AdaptiveScheduler()})
      : _engine = engine;

  final AppDatabase _db;
  final AdaptiveScheduler _engine;

  /// Rolls the plan forward to [today], catching every missed run.
  Future<RescheduleOutcome?> runDayRollover({DateTime? today}) =>
      _run((snapshot) => _engine.onDayRollover(snapshot), today: today);

  /// The user reported they couldn't run [plannedRunId] today.
  Future<RescheduleOutcome?> reportCouldNotRun(int plannedRunId,
          {DateTime? today}) =>
      _run((snapshot) => _engine.reportCouldNotRun(snapshot, plannedRunId),
          today: today);

  Future<RescheduleOutcome?> _run(
    RescheduleOutcome Function(ScheduleSnapshot) compute, {
    DateTime? today,
  }) async {
    final plan = await _db.planDao.getActivePlan();
    if (plan == null) return null;
    final planned = await _db.runsDao.getPlannedRuns(plan.id);
    final completed = await _db.runsDao.watchCompletedRuns().first;
    final settingsRow = await _db.settingsDao.getSettings();

    final before = {for (final r in planned) r.id: r.toDomain()};
    final snapshot = ScheduleSnapshot(
      plan: plan.toDomain(),
      plannedRuns: before.values.toList(),
      completedRuns: completed.map((c) => c.toDomain()).toList(),
      settings: settingsRow?.toDomain() ?? const AppSettings(),
      today: dateOnly(today ?? DateTime.now()),
    );

    final outcome = compute(snapshot);
    await _persist(before, outcome.runs);
    return outcome;
  }

  /// Writes only the runs that actually changed.
  Future<void> _persist(
      Map<int, PlannedRun> before, List<PlannedRun> after) async {
    await _db.transaction(() async {
      for (final run in after) {
        final prev = before[run.id];
        if (prev == null) continue;
        final changed = prev.scheduledDate != run.scheduledDate ||
            prev.status != run.status ||
            prev.targetDistanceKm != run.targetDistanceKm ||
            prev.weekIndex != run.weekIndex;
        if (!changed) continue;
        await _db.runsDao.updatePlannedRun(
          run.id,
          PlannedRunsCompanion(
            scheduledDate: Value(run.scheduledDate),
            weekIndex: Value(run.weekIndex),
            status: Value(run.status),
            targetDistanceKm: Value(run.targetDistanceKm),
          ),
        );
      }
    });
  }
}
