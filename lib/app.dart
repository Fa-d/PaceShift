import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'presentation/providers/providers.dart';
import 'presentation/router.dart';
import 'services/notifications/notification_service.dart';

class PaceShiftApp extends ConsumerStatefulWidget {
  const PaceShiftApp({super.key});

  @override
  ConsumerState<PaceShiftApp> createState() => _PaceShiftAppState();
}

class _PaceShiftAppState extends ConsumerState<PaceShiftApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // Route notification taps/actions to the engine.
    NotificationService.onAction = _handleNotificationAction;
    // Ask for notification permission (Android 13+); harmless if already granted.
    await ref.read(notificationServiceProvider).requestPermissions();
  }

  Future<void> _handleNotificationAction(
      String? actionId, String? payload) async {
    if (actionId == NotificationIds.actionCouldNotRun) {
      // The evening check "Couldn't run today" → run day rollover immediately.
      await ref.read(schedulerRepositoryProvider).runDayRollover();
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
