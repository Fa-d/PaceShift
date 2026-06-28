import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/db/app_database.dart';
import '../../data/health/health_service.dart';
import '../../data/repositories/scheduler_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../domain/models/app_settings.dart';
import '../notifications/notification_service.dart';

/// Task identifiers for the background worker.
class BackgroundTasks {
  static const periodicSync = 'paceshift.periodicSync';
  static const uniquePeriodic = 'paceshift.periodic';
}

/// Polls Health Connect a few times daily and rolls the plan forward so missed
/// runs are caught even when the app isn't opened (spec §7). Runs in a headless
/// isolate, so it opens its own database and services.
class BackgroundService {
  const BackgroundService();

  Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  /// Registers the periodic worker (every ~6h, network-connected).
  Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      BackgroundTasks.uniquePeriodic,
      BackgroundTasks.periodicSync,
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  Future<void> cancelAll() => Workmanager().cancelAll();
}

/// The headless entry point. Must be a top-level function annotated for the VM.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final db = AppDatabase();
    try {
      // 1) Roll the plan forward so any missed runs are redistributed.
      await SchedulerRepository(db).runDayRollover();

      // 2) Pull new workouts from Health Connect (best effort).
      final settings =
          await SettingsRepository(db).getSettings().catchError((_) => const AppSettings());
      final sync = SyncRepository(db, HealthService());
      final result = await sync.syncNow();

      // 3) Confirm any newly logged runs.
      if (result.isSuccess && result.newRuns > 0) {
        final notifier = NotificationService();
        await notifier.showPostSync(
          '${result.totalKm.toStringAsFixed(1)} km logged from your watch.',
        );
      }
      // Reference settings so the analyzer keeps the (useful) fetch above.
      debugPrint('Background task $task ran (units: ${settings.units.name}).');
      return true;
    } catch (e) {
      debugPrint('Background task failed: $e');
      return false;
    } finally {
      await db.close();
    }
  });
}
