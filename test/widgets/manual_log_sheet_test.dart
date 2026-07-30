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
import 'package:paceshift/domain/models/planned_run.dart';
import 'package:paceshift/domain/plan_generator/plan_input.dart';
import 'package:paceshift/presentation/providers/providers.dart';
import 'package:paceshift/presentation/widgets/manual_log_sheet.dart';

/// The manual log sheet stored whatever number was typed straight into
/// `distanceKm`, while its label read "Distance (km)" regardless of the
/// athlete's units. An imperial runner logging a 13.1-mile half marathon
/// recorded 13.1 km — a 38% under-count that then flowed into weekly volume,
/// lifetime totals, the readiness score, the VDOT estimate and the race
/// prediction. These tests pin the conversion at the boundary.

Future<AppDatabase> _db(UnitSystem units) async {
  final db = AppDatabase(NativeDatabase.memory());
  final settings = SettingsRepository(db);
  await settings.ensureDefaults();
  await settings.update((await settings.getSettings()).copyWith(units: units));
  await PlanRepository(db).createPlanFromInput(PlanInput(
    raceDate: addDays(today(), 133),
    currentLongestRunKm: 18,
    preferredLongRunDay: DateTime.saturday,
  ));
  return db;
}

/// Opens the sheet through its real modal route, so the `Navigator.pop` on save
/// has something to pop.
Future<void> _openSheet(
  WidgetTester tester,
  AppDatabase db, {
  PlannedRun? plannedRun,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () =>
                    ManualLogSheet.show(context, plannedRun: plannedRun),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Saves and drains the celebration overlay.
///
/// `pumpAndSettle` cannot be used here: saving fires a 900ms confetti
/// controller plus a 2.6s delayed overlay removal, so the tree never reaches a
/// steady state. Pump past both instead.
Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save run'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 3));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

/// Reads with a plain query, not `watchCompletedRuns()`: awaiting a drift
/// *stream* inside `testWidgets` deadlocks, because the stream's timers are
/// owned by the fake clock that only advances when the tester pumps.
Future<CompletedRunRow> _onlyCompleted(AppDatabase db) async =>
    (await db.select(db.completedRuns).get()).single;

void main() {
  testWidgets('labels the distance field in the athlete\'s own units',
      (tester) async {
    final db = await _db(UnitSystem.imperial);
    addTearDown(db.close);
    await _openSheet(tester, db);

    expect(find.text('Distance (mi)'), findsOneWidget);
    expect(find.text('Distance (km)'), findsNothing);
    await _settle(tester);
  });

  testWidgets('metric labels and stores kilometres unchanged', (tester) async {
    final db = await _db(UnitSystem.metric);
    addTearDown(db.close);
    await _openSheet(tester, db);

    expect(find.text('Distance (km)'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '13.1');
    await tester.enterText(find.byType(TextFormField).at(1), '60');
    await _save(tester);

    expect((await _onlyCompleted(db)).actualDistanceKm, closeTo(13.1, 1e-9));
    await _settle(tester);
  });

  testWidgets('converts a typed imperial distance back to kilometres',
      (tester) async {
    final db = await _db(UnitSystem.imperial);
    addTearDown(db.close);
    await _openSheet(tester, db);

    // 13.1 miles is a half marathon: ~21.08 km, not 13.1 km.
    await tester.enterText(find.byType(TextFormField).first, '13.1');
    await tester.enterText(find.byType(TextFormField).at(1), '105');
    await _save(tester);

    expect((await _onlyCompleted(db)).actualDistanceKm, closeTo(21.082, 0.001));
    await _settle(tester);
  });

  testWidgets('prefills a planned run in display units and saves it exactly',
      (tester) async {
    final db = await _db(UnitSystem.imperial);
    addTearDown(db.close);
    final plan = await PlanRepository(db).getActivePlan();
    final runs = await RunRepository(db).getPlannedRuns(plan!.id);
    final long = runs.firstWhere((r) => r.type == RunType.long);

    await _openSheet(tester, db, plannedRun: long);

    // The field must show miles, not the raw stored kilometres.
    final field = tester.widget<TextFormField>(find.byType(TextFormField).first);
    final shown = double.parse(field.controller!.text);
    expect(shown, closeTo(long.targetDistanceKm! / 1.609344, 0.05));

    // Saving it untouched stores the exact planned distance, not the rounded
    // display value round-tripped back through the conversion.
    await tester.enterText(find.byType(TextFormField).at(1), '90');
    await _save(tester);

    expect((await _onlyCompleted(db)).actualDistanceKm, long.targetDistanceKm);
    await _settle(tester);
  });
}
