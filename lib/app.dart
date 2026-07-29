import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'domain/engine/reschedule_outcome.dart';
import 'presentation/providers/providers.dart';
import 'presentation/router.dart';
import 'services/notifications/notification_service.dart';

class PaceShiftApp extends ConsumerStatefulWidget {
  const PaceShiftApp({super.key, this.launchAdjustment});

  /// What the startup day-rollover changed, if anything. Surfaced on Today so
  /// a plan rewritten while the app was closed doesn't go unannounced.
  final RescheduleOutcome? launchAdjustment;

  @override
  ConsumerState<PaceShiftApp> createState() => _PaceShiftAppState();
}

class _PaceShiftAppState extends ConsumerState<PaceShiftApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    ref.read(recentAdjustmentProvider.notifier).record(widget.launchAdjustment);
    // Route notification taps/actions to the engine.
    NotificationService.onAction = _handleNotificationAction;
    // Ask for notification permission (Android 13+); harmless if already granted.
    await ref.read(notificationServiceProvider).requestPermissions();
    // Pull anything the watch recorded while we were away. Runs here rather
    // than in `main()` so the UI is already up — a sync that needs to surface a
    // permission sheet or an error shouldn't happen against a blank screen.
    await _autoSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app is the moment a just-finished run is most likely
    // to be waiting in the health store.
    if (state == AppLifecycleState.resumed) _autoSync();
  }

  /// Throttled background-style sync. Never prompts for permissions — an
  /// unexplained system dialog on resume reads as a bug.
  Future<void> _autoSync() async {
    if (!mounted) return;
    try {
      await syncAndSettle(
        sync: ref.read(syncRepositoryProvider),
        scheduler: ref.read(schedulerRepositoryProvider),
        onlyIfStale: true,
        onAdjustment: ref.read(recentAdjustmentProvider.notifier).record,
      );
    } catch (_) {
      // Sync is an enhancement, never a hard dependency.
    }
  }

  Future<void> _handleNotificationAction(
      String? actionId, String? payload) async {
    if (actionId == NotificationIds.actionCouldNotRun) {
      // The evening check "Couldn't run today" → run day rollover immediately.
      final outcome =
          await ref.read(schedulerRepositoryProvider).runDayRollover();
      // Answering from the lock screen still deserves an answer back: the
      // result lands on Today rather than vanishing.
      ref.read(recentAdjustmentProvider.notifier).record(outcome);
    }
    // "Mark done" simply opens the app on Today, where the user logs the run.
  }

  @override
  Widget build(BuildContext context) {
    // Keep scheduled reminders in sync with settings/today's run.
    ref.watch(reminderSchedulerProvider);

    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'PaceShift',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
