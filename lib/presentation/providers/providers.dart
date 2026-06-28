import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/run_repository.dart';
import '../../data/health/health_service.dart';
import '../../data/repositories/scheduler_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/completed_run.dart';
import '../../domain/models/planned_run.dart';
import '../../domain/fitness/race_predictor.dart';
import '../../domain/models/training_plan.dart';
import '../../domain/readiness/readiness_scorer.dart';
import '../../services/background/background_service.dart';
import '../../services/notifications/notification_service.dart';

/// Root database. Overridden in `main()` so the open DB is shared app-wide and
/// closed on disposal.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(databaseProvider)),
);

final runRepositoryProvider = Provider<RunRepository>(
  (ref) => RunRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final schedulerRepositoryProvider = Provider<SchedulerRepository>(
  (ref) => SchedulerRepository(ref.watch(databaseProvider)),
);

final healthServiceProvider = Provider<HealthService>((ref) => HealthService());

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final backgroundServiceProvider =
    Provider<BackgroundService>((ref) => const BackgroundService());

final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => SyncRepository(
      ref.watch(databaseProvider), ref.watch(healthServiceProvider)),
);

/// Whether Health Connect is usable on this device.
final healthAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(syncRepositoryProvider).isAvailable(),
);

/// Last successful sync time (null until first sync).
final lastSyncProvider = FutureProvider<DateTime?>(
  (ref) => ref.watch(syncRepositoryProvider).lastSync(),
);

/// Today's calendar date. A plain provider for Phase 1; background day-rollover
/// (Phase 4) drives real transitions.
final todayProvider = Provider<DateTime>((ref) => today());

/// The active plan (null until onboarding completes).
final activePlanProvider = StreamProvider<TrainingPlan?>(
  (ref) => ref.watch(planRepositoryProvider).watchActivePlan(),
);

/// Whether onboarding is needed.
final hasActivePlanProvider = Provider<bool>(
  (ref) => ref.watch(activePlanProvider).value != null,
);

/// All planned runs for the active plan.
final plannedRunsProvider = StreamProvider<List<PlannedRun>>((ref) {
  final plan = ref.watch(activePlanProvider).value;
  if (plan == null) return Stream.value(const <PlannedRun>[]);
  return ref.watch(runRepositoryProvider).watchPlannedRuns(plan.id);
});

/// Completed runs (newest first).
final completedRunsProvider = StreamProvider<List<CompletedRun>>(
  (ref) => ref.watch(runRepositoryProvider).watchCompletedRuns(),
);

/// User settings (always non-null with defaults).
final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchSettings(),
);

/// Today's planned runs (may be empty / a rest day).
final todayRunsProvider = Provider<List<PlannedRun>>((ref) {
  final runs = ref.watch(plannedRunsProvider).value ?? const [];
  final t = ref.watch(todayProvider);
  return runs.where((r) => isSameDate(r.scheduledDate, t)).toList();
});

/// Keeps the scheduled daily reminders in sync with the current settings and
/// today's prescribed run. Watch this once (e.g. in the app root) to activate.
final reminderSchedulerProvider = Provider<void>((ref) {
  final settings = ref.watch(settingsProvider).value;
  if (settings == null) return;
  final todayRuns = ref.watch(todayRunsProvider);
  final notifier = ref.watch(notificationServiceProvider);
  // Fire-and-forget; the plugin de-dupes by id.
  notifier.scheduleDailyReminders(
    settings,
    todaysRun: todayRuns.isEmpty ? null : todayRuns.first,
  );
});

/// Predicted finish time for the active plan's race distance, from logged runs.
final racePredictionProvider = Provider<RacePrediction?>((ref) {
  final plan = ref.watch(activePlanProvider).value;
  if (plan == null) return null;
  final completed = ref.watch(completedRunsProvider).value ?? const [];
  return const RacePredictor().predict(
    raceDistanceKm: plan.raceDistanceKm,
    runs: completed,
    asOf: ref.watch(todayProvider),
  );
});

/// A short plain-text plan summary used to ground AI coaching (Phase 10).
final planSummaryProvider = Provider<String>((ref) {
  final plan = ref.watch(activePlanProvider).value;
  if (plan == null) return 'No active plan.';
  final t = ref.watch(todayProvider);
  final week = (daysBetween(plan.startDate, t) ~/ 7) + 1;
  final readiness = ref.watch(readinessProvider);
  final prediction = ref.watch(racePredictionProvider);
  final parts = <String>[
    '${plan.raceDistanceKm}km race on ${plan.raceDate.toIso8601String().split('T').first}',
    'week $week of ${plan.totalWeeks}',
    'taper ${plan.taperWeeks} weeks',
  ];
  if (readiness != null) parts.add('readiness ${readiness.score}/100 (${readiness.label})');
  if (prediction != null) {
    final s = prediction.predictedSec;
    parts.add('predicted finish ${s ~/ 3600}h${(s % 3600) ~/ 60}m');
  }
  return parts.join(', ');
});

/// Live race-readiness score derived from the plan and logged runs.
final readinessProvider = Provider<ReadinessScore?>((ref) {
  final plan = ref.watch(activePlanProvider).value;
  if (plan == null) return null;
  final runs = ref.watch(plannedRunsProvider).value ?? const [];
  final completed = ref.watch(completedRunsProvider).value ?? const [];
  return ReadinessScorer(peakLongRunKm: 32).compute(
    plan: plan,
    plannedRuns: runs,
    completedRuns: completed,
    asOf: ref.watch(todayProvider),
  );
});
