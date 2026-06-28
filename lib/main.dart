import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/billing/revenuecat_subscription_service.dart';
import 'data/billing/subscription_service.dart';
import 'data/db/app_database.dart';
import 'data/repositories/scheduler_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'presentation/providers/providers.dart';
import 'presentation/providers/subscription_providers.dart';
import 'services/background/background_service.dart';
import 'services/notifications/notification_service.dart';

/// RevenueCat public SDK key (sandbox or prod). Empty disables billing.
const _revenueCatKey = String.fromEnvironment('REVENUECAT_API_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Replay entrance animations after a hot reload during development.
  Animate.restartOnHotReload = true;

  // Open the database once and share it app-wide, then seed default settings.
  final db = AppDatabase();
  await SettingsRepository(db).ensureDefaults();

  // Catch any runs missed while the app was closed.
  await SchedulerRepository(db).runDayRollover();

  // Notifications + background polling (best effort — never block startup).
  final notifications = NotificationService();
  try {
    await notifications.init();
    await const BackgroundService().init();
    await const BackgroundService().registerPeriodicSync();
  } catch (_) {
    // Plugins unavailable (e.g. in tests) — the app still runs.
  }

  // Billing (RevenueCat). Falls back to a no-op service without a key.
  SubscriptionService subscriptions = const UnconfiguredSubscriptionService();
  try {
    final rc = await RevenueCatSubscriptionService.configure(
        apiKey: _revenueCatKey);
    if (rc != null) subscriptions = rc;
  } catch (_) {
    // Billing optional — the app runs free-tier without it.
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(notifications),
        subscriptionServiceProvider.overrideWithValue(subscriptions),
      ],
      child: const PaceShiftApp(),
    ),
  );
}
