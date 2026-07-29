import 'package:drift/drift.dart';

import '../../core/date_utils.dart';
import '../../domain/models/completed_run.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';
import '../../domain/sync/workout_matcher.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';
import '../health/health_service.dart';

/// Outcome of a health sync, used for UI and the post-sync notification.
class SyncResult {
  const SyncResult({
    required this.status,
    this.newRuns = 0,
    this.totalKm = 0,
    this.needsConfirmation = 0,
    this.recoveredMissedRun = false,
    this.syncedAt,
  });

  final SyncStatus status;
  final int newRuns;
  final double totalKm;

  /// How many imported runs need the user to confirm a suggested match.
  final int needsConfirmation;

  /// True when a workout was attached to a run the rollover had already written
  /// off as missed. The caller should re-run the day rollover so the engine can
  /// settle the load it redistributed on the strength of that miss.
  final bool recoveredMissedRun;

  final DateTime? syncedAt;

  bool get isSuccess => status == SyncStatus.success;
}

enum SyncStatus { success, unavailable, permissionDenied, noPlan, error, skipped }

/// Why a sync is running. Automatic passes (launch, resume, background) must
/// never surface a system permission dialog — the user didn't ask for one and a
/// prompt appearing out of nowhere reads as a bug. Only [manual] may prompt.
enum SyncTrigger { manual, automatic }

/// Pulls workouts from the platform health store (Health Connect on Android,
/// HealthKit on iOS), dedups, matches them to planned runs, and records them.
/// Manual entry (see [RunRepository]) remains the always-available fallback.
class SyncRepository {
  SyncRepository(this._db, this._health);

  final AppDatabase _db;
  final HealthService _health;

  Future<bool> isAvailable() => _health.isAvailable();
  Future<bool> requestPermissions() => _health.requestPermissions();
  Future<void> installHealthConnect() => _health.installHealthConnect();
  bool get canInstallProvider => _health.canInstallProvider;

  /// User-facing name of this platform's health store ("Apple Health" / "Health
  /// Connect"), so screens don't need to branch on the platform themselves.
  String get providerName => HealthService.providerName;

  Future<DateTime?> lastSync() async =>
      (await _db.settingsDao.getSettings())?.lastSyncAt;

  /// Syncs only if the last one is older than [minInterval]. Used by the
  /// launch/resume triggers so foregrounding the app repeatedly doesn't hammer
  /// the health store.
  Future<SyncResult> syncIfStale({
    Duration minInterval = const Duration(minutes: 15),
  }) async {
    final last = await lastSync();
    if (last != null && DateTime.now().difference(last) < minInterval) {
      return const SyncResult(status: SyncStatus.skipped);
    }
    return syncNow(trigger: SyncTrigger.automatic);
  }

  /// Runs a sync. Safe to call when no health store is available — it reports
  /// the reason without throwing.
  Future<SyncResult> syncNow({SyncTrigger trigger = SyncTrigger.manual}) async {
    final plan = await _db.planDao.getActivePlan();
    if (plan == null) return const SyncResult(status: SyncStatus.noPlan);

    try {
      if (!await _health.isAvailable()) {
        return const SyncResult(status: SyncStatus.unavailable);
      }
      if (!await _ensurePermission(trigger)) {
        return const SyncResult(status: SyncStatus.permissionDenied);
      }

      final settings = await _db.settingsDao.getSettings();
      // On the very first sync, pull ~6 months of history so pre-plan runs form
      // meaningful base stats; reach back to the plan start if it's older still.
      final firstSyncFloor = DateTime.now().subtract(const Duration(days: 180));
      final since = settings?.lastSyncAt ??
          (plan.startDate.isBefore(firstSyncFloor)
              ? plan.startDate
              : firstSyncFloor);

      final sessions = await _health.fetchWorkouts(since: since);

      // Load the plan's runs once, not once per workout. The trade-off is that
      // this snapshot goes stale as we attach runs, so `claimed` tracks what
      // we've consumed and keeps two workouts off the same planned run.
      final planned = (await _db.runsDao.getPlannedRuns(plan.id))
          .map((r) => r.toDomain())
          .toList();
      final claimed = <int>{};

      var added = 0;
      var totalKm = 0.0;
      var pending = 0;
      var recovered = false;

      for (final session in sessions) {
        final existing =
            await _db.runsDao.getCompletedByExternalId(session.externalId);
        if (existing != null) continue;

        // Only actual runs satisfy a planned run; walks/hikes are stored but
        // never mark a scheduled run as completed.
        final match = session.activityType.isRun
            ? matchWorkout(
                distanceKm: session.distanceKm,
                workoutDate: session.date,
                candidates: planned,
                excludeIds: claimed,
              )
            : const WorkoutMatch.none();

        final attachId = match.isAutomatic ? match.plannedRunId : null;
        final suggestId = match.needsConfirmation ? match.plannedRunId : null;
        // Only a real attachment consumes the planned run. A mere suggestion
        // must not block it: a short jog and the actual long run can land on
        // the same day, and whichever we happen to process first, the long run
        // should still win outright.
        if (attachId != null) claimed.add(attachId);
        if (attachId != null && _statusOf(planned, attachId) == RunStatus.missed) {
          recovered = true;
        }

        await _db.transaction(() async {
          await _db.runsDao.insertCompletedRun(CompletedRunsCompanion(
            plannedRunId: Value(attachId),
            suggestedPlannedRunId: Value(suggestId),
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
            activityType: Value(session.activityType),
            externalId: Value(session.externalId),
          ));
          if (attachId != null) {
            await _db.runsDao.updatePlannedRun(
              attachId,
              const PlannedRunsCompanion(status: Value(RunStatus.completed)),
            );
          }
        });

        if (suggestId != null) pending++;
        // Report runs only — walks/hikes are imported silently.
        if (session.activityType.isRun) {
          added++;
          totalKm += session.distanceKm;
        }
      }

      final now = DateTime.now();
      await _db.settingsDao.updateLastSync(now);
      return SyncResult(
        status: SyncStatus.success,
        newRuns: added,
        totalKm: totalKm,
        needsConfirmation: pending,
        recoveredMissedRun: recovered,
        syncedAt: now,
      );
    } catch (_) {
      return const SyncResult(status: SyncStatus.error);
    }
  }

  RunStatus? _statusOf(List<PlannedRun> runs, int id) {
    for (final r in runs) {
      if (r.id == id) return r.status;
    }
    return null;
  }

  /// Resolves the platform's tri-state read permission into "can we read now?".
  ///
  /// Android answers true/false honestly. iOS answers `null` always — Apple
  /// won't disclose READ grants — so there we prompt exactly once (the system
  /// sheet only ever appears the first time anyway), record that we asked, and
  /// treat the read itself as the source of truth from then on. Collapsing null
  /// to false instead would re-prompt on every single sync.
  Future<bool> _ensurePermission(SyncTrigger trigger) async {
    final status = await _health.permissionStatus();
    if (status == true) return true;

    if (status == false) {
      if (trigger == SyncTrigger.automatic) return false;
      return _health.requestPermissions();
    }

    // Undetermined (iOS).
    final alreadyAsked =
        (await _db.settingsDao.getSettings())?.healthPromptedAt != null;
    if (alreadyAsked) return true;
    if (trigger == SyncTrigger.automatic) return false;
    await _health.requestPermissions();
    await _db.settingsDao.markHealthPrompted(DateTime.now());
    return true;
  }
}
