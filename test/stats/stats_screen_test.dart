import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/core/theme.dart';
import 'package:paceshift/data/db/app_database.dart';
import 'package:paceshift/data/repositories/plan_repository.dart';
import 'package:paceshift/data/repositories/run_repository.dart';
import 'package:paceshift/data/repositories/settings_repository.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/plan_generator/plan_input.dart';
import 'package:paceshift/presentation/providers/providers.dart';
import 'package:paceshift/presentation/stats/stats_screen.dart';

/// The Progress screen had no widget test at all, which is how two visible
/// defects survived: sub-unit totals rendered as a bare "0" (the count-up
/// formatter shadowed the one-decimal string), and the "No stats yet" empty
/// state was unreachable because any plan produces planned bars.
Future<AppDatabase> _pumpStats(
  WidgetTester tester, {
  bool withPlan = true,
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await SettingsRepository(db).ensureDefaults();
  if (withPlan) {
    await PlanRepository(db).createPlanFromInput(PlanInput(
      raceDate: addDays(today(), 133),
      currentLongestRunKm: 18,
      preferredLongRunDay: DateTime.saturday,
    ));
  }
  return db;
}

Future<void> _pump(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(theme: AppTheme.light(), home: const StatsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('with no plan, invites the athlete to create one', (tester) async {
    final db = await _pumpStats(tester, withPlan: false);
    await _pump(tester, db);

    expect(find.text('No plan yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('with a plan but nothing logged, shows the empty state',
      (tester) async {
    final db = await _pumpStats(tester);
    await _pump(tester, db);

    // Previously unreachable: the screen drew a chart of all-zero completed
    // bars instead, which reads as broken rather than as "nothing yet".
    expect(find.text('No stats yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('renders a sub-kilometre total as 0.6, not 0', (tester) async {
    final db = await _pumpStats(tester);
    await RunRepository(db).logExtraRun(
      date: today(),
      distanceKm: 0.6,
      durationSec: 240,
    );
    await _pump(tester, db);

    expect(find.text('No stats yet'), findsNothing);
    // The count-up formatter used to be `(n) => n.round().toString()`, so this
    // tile read "0" while the athlete's log said 0.6 km.
    expect(find.text('0.6'), findsWidgets);
    await _settle(tester);
  });

  testWidgets('builds the charts without a layout or paint exception',
      (tester) async {
    final db = await _pumpStats(tester);
    final repo = RunRepository(db);
    for (var i = 0; i < 3; i++) {
      await repo.logExtraRun(
        date: addDays(today(), -i * 3),
        distanceKm: 8.0 + i,
        durationSec: 2400,
      );
    }
    await _pump(tester, db);

    expect(tester.takeException(), isNull);
    expect(find.text('Weekly volume'), findsOneWidget);

    // The second chart is below the fold, and the ListView builds lazily.
    await tester.scrollUntilVisible(find.text('Long-run progression'), 300);
    expect(find.text('Long-run progression'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('acknowledges volume logged before the plan started',
      (tester) async {
    final db = await _pumpStats(tester);
    final plan = await PlanRepository(db).getActivePlan();
    await RunRepository(db).logExtraRun(
      date: addDays(plan!.startDate, -10),
      distanceKm: 12,
      durationSec: 3600,
    );
    await _pump(tester, db);

    // Kept off the bars (no W0/W-1) but not silently dropped either.
    expect(find.textContaining('before this plan'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('survives a small screen', (tester) async {
    final db = await _pumpStats(tester, size: const Size(320, 560));
    await RunRepository(db)
        .logExtraRun(date: today(), distanceKm: 10, durationSec: 3000);
    await _pump(tester, db);

    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('shows distances in miles for an imperial athlete',
      (tester) async {
    final db = await _pumpStats(tester);
    final settings = SettingsRepository(db);
    await settings.update((await settings.getSettings())
        .copyWith(units: UnitSystem.imperial));
    await RunRepository(db).logExtraRun(
      date: today(),
      distanceKm: 16.09344, // exactly 10 miles
      durationSec: 3600,
    );
    await _pump(tester, db);

    expect(find.text('total mi'), findsOneWidget);
    expect(find.text('10'), findsWidgets);
    await _settle(tester);
  });
}
