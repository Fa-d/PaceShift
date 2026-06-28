import 'package:drift/drift.dart';

import '../../core/date_utils.dart';
import '../../domain/models/completed_run.dart';
import '../../domain/models/enums.dart';
import '../db/app_database.dart';
import '../health/health_service.dart';

/// Outcome of a Health Connect sync, used for UI and the post-sync notification.
class SyncResult {
  const SyncResult({
    required this.status,
    this.newRuns = 0,
    this.totalKm = 0,
    this.syncedAt,
  });

  final SyncStatus status;
  final int newRuns;
  final double totalKm;
  final DateTime? syncedAt;

  bool get isSuccess => status == SyncStatus.success;
}

enum SyncStatus { success, unavailable, permissionDenied, noPlan, error }

/// Pulls workouts from Health Connect, dedups, matches them to planned runs, and
/// records them. Manual entry (see [RunRepository]) remains the always-available
/// fallback.
class SyncRepository {
  SyncRepository(this._db, this._health);

  final AppDatabase _db;
  final HealthService _health;

  Future<bool> isAvailable() => _health.isAvailable();
  Future<bool> hasPermissions() => _health.hasPermissions();
  Future<bool> requestPermissions() => _health.requestPermissions();
  Future<void> installHealthConnect() => _health.installHealthConnect();

  Future<DateTime?> lastSync() async =>
      (await _db.settingsDao.getSettings())?.lastSyncAt;

  /// Runs a sync. Safe to call when Health Connect is unavailable — it simply
  /// reports the reason without throwing.
  Future<SyncResult> syncNow() async {
    final plan = await _db.planDao.getActivePlan();
    if (plan == null) return const SyncResult(status: SyncStatus.noPlan);

    try {
      if (!await _health.isAvailable()) {
        return const SyncResult(status: SyncStatus.unavailable);
      }
      if (!await _health.hasPermissions()) {
        final granted = await _health.requestPermissions();
        if (!granted) {
          return const SyncResult(status: SyncStatus.permissionDenied);
        }
      }

      final settings = await _db.settingsDao.getSettings();
      // Default to the plan start (or 30 days back) on the very first sync.
      final since = settings?.lastSyncAt ??
          (plan.startDate.isBefore(DateTime.now())
              ? plan.startDate
              : DateTime.now().subtract(const Duration(days: 30)));

      final sessions = await _health.fetchWorkouts(since: since);

      var added = 0;
      var totalKm = 0.0;
      for (final session in sessions) {
        final existing =
            await _db.runsDao.getCompletedByExternalId(session.externalId);
        if (existing != null) continue;

        final plannedRunId = await _matchPlannedRun(plan.id, session.date);
        await _db.transaction(() async {
          await _db.runsDao.insertCompletedRun(CompletedRunsCompanion(
            plannedRunId: Value(plannedRunId),
            date: Value(dateOnly(session.date)),
            actualDistanceKm: Value(session.distanceKm),
            durationSec: Value(session.durationSec),
            avgPaceSecPerKm: Value(computeAvgPaceSecPerKm(
                distanceKm: session.distanceKm,
                durationSec: session.durationSec)),
            avgHr: Value(session.avgHr),
            maxHr: Value(session.maxHr),
            calories: Value(session.calories),
            source: const Value(RunSource.healthConnect),
            externalId: Value(session.externalId),
          ));
          if (plannedRunId != null) {
            await _db.runsDao.updatePlannedRun(
              plannedRunId,
              const PlannedRunsCompanion(status: Value(RunStatus.completed)),
            );
          }
        });
        added++;
        totalKm += session.distanceKm;
      }

      final now = DateTime.now();
      await _db.settingsDao.updateLastSync(now);
      return SyncResult(
        status: SyncStatus.success,
        newRuns: added,
        totalKm: totalKm,
        syncedAt: now,
      );
    } catch (_) {
      return const SyncResult(status: SyncStatus.error);
    }
  }

  /// Finds the nearest still-pending planned run on [date] to attach a workout
  /// to (spec §6). Returns null if there's no pending run that day.
  Future<int?> _matchPlannedRun(int planId, DateTime date) async {
    final dayRuns = await _db.runsDao.getPlannedRuns(planId);
    final candidates = dayRuns
        .where((r) =>
            isSameDate(r.scheduledDate, date) &&
            (r.status == RunStatus.pending || r.status == RunStatus.shifted) &&
            r.type != RunType.rest)
        .toList()
      ..sort((a, b) => _typeRank(a.type).compareTo(_typeRank(b.type)));
    return candidates.isEmpty ? null : candidates.first.id;
  }

  // Prefer matching to the highest-value run that day (long > steady > easy).
  int _typeRank(RunType type) => switch (type) {
        RunType.long => 0,
        RunType.steady => 1,
        RunType.easy => 2,
        _ => 3,
      };
}
