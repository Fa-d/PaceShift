import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/theme.dart';
import 'package:paceshift/data/db/app_database.dart';
import 'package:paceshift/data/health/health_service.dart';
import 'package:paceshift/data/repositories/settings_repository.dart';
import 'package:paceshift/presentation/providers/providers.dart';
import 'package:paceshift/presentation/sync/connect_health_screen.dart';

/// A health store that is present and already authorised, so the screen's
/// "Connect" path runs end to end without touching a platform channel.
class _FakeHealthService extends HealthService {
  _FakeHealthService({this.available = true});

  final bool available;

  @override
  Future<bool> isAvailable() async => available;

  @override
  bool get canInstallProvider => false;

  @override
  Future<bool?> permissionStatus() async => true;

  @override
  Future<List<WorkoutSession>> fetchWorkouts({required DateTime since}) async =>
      const [];
}

Future<AppDatabase> _pumpScreen(
  WidgetTester tester, {
  bool available = true,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await SettingsRepository(db).ensureDefaults();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        healthServiceProvider
            .overrideWithValue(_FakeHealthService(available: available)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const ConnectHealthScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

void main() {
  testWidgets('declining still records that we asked, so it never nags again',
      (tester) async {
    final db = await _pumpScreen(tester);
    expect((await db.settingsDao.getSettings())?.healthPromptedAt, isNull);

    await tester.tap(find.text('Not now — I’ll log runs myself'));
    await tester.pumpAndSettle();

    expect((await db.settingsDao.getSettings())?.healthPromptedAt, isNotNull,
        reason: 'stamping the flag is what releases the router gate');
  });

  testWidgets('connecting syncs and records that we asked', (tester) async {
    final db = await _pumpScreen(tester);

    await tester.tap(find.textContaining('Connect to '));
    // The screen now always reports the outcome in a SnackBar — including the
    // "connected, nothing to import yet" case this test exercises, which used
    // to produce no feedback at all. A SnackBar holds a 4s display timer that
    // `pumpAndSettle` does not wait out (no frames are scheduled while it just
    // sits there), so pump past it explicitly or it outlives the test.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Whatever the outcome, the athlete is told something. Connecting used to
    // report back only when it imported at least one run, so the common
    // "connected, nothing new yet" case produced silence — the screen simply
    // closed, which is indistinguishable from having failed.
    expect(find.byType(SnackBar), findsOneWidget);

    // Let the SnackBar's display timer expire, or it outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final settings = await db.settingsDao.getSettings();
    expect(settings?.healthPromptedAt, isNotNull);
    expect(settings?.lastSyncAt, isNull,
        reason: 'no active plan, so the sync bails before setting a cursor');

    // Reporting the import in the athlete's units opens the settings stream,
    // and drift schedules a zero-duration cleanup timer when that stream is
    // torn down. Dismantle the tree inside the test so the timer drains here
    // rather than being flagged as still-pending after the test ends.
    // (A bare `pump()` doesn't advance fake time, so a zero-duration timer
    // would still be sitting there — the elapse is the point.)
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('offers the install path when the provider is missing',
      (tester) async {
    await _pumpScreen(tester, available: false);
    // canInstallProvider is false here (iOS-like), so we must not offer an
    // install the platform can't perform — the connect button stays.
    expect(find.text('Install Health Connect'), findsNothing);
    expect(find.textContaining('Connect to '), findsOneWidget);
  });
}
