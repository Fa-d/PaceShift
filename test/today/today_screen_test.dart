import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/core/theme.dart';
import 'package:paceshift/data/db/app_database.dart';
import 'package:paceshift/data/repositories/plan_repository.dart';
import 'package:paceshift/data/repositories/settings_repository.dart';
import 'package:paceshift/domain/plan_generator/plan_input.dart';
import 'package:paceshift/presentation/providers/providers.dart';
import 'package:paceshift/presentation/today/today_screen.dart';

/// The dashboard, actually built.
///
/// Today shipped a layout crash that took the whole screen down to a red error
/// box on first launch — a `Row` stretching inside a vertical `ListView`,
/// demanding infinite height. Every unit test passed, because nothing had ever
/// pumped this widget. These do.
Future<AppDatabase> _pumpToday(
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

  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const TodayScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// Dismantles the tree and lets drift's stream-cleanup timers drain.
///
/// Today watches several drift streams, and drift posts a zero-duration timer
/// as each one is torn down. The framework checks for pending timers at the
/// end of the test *body* — before `addTearDown` callbacks run — so this has
/// to be called from inside the test itself.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('builds without a layout or paint exception', (tester) async {
    await _pumpToday(tester);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('shows where you are in the plan, with a denominator',
      (tester) async {
    await _pumpToday(tester);
    // A bare "Week 12" tells a runner nothing, and the race date — the whole
    // premise of the app — was previously nowhere on the dashboard.
    expect(find.textContaining('Week 1 of'), findsOneWidget);
    expect(find.textContaining('to race day'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('the primary action is above the fold', (tester) async {
    await _pumpToday(tester);

    // Whatever today holds, the hero for it must be visible without scrolling.
    // Secondary cards used to render *above* the run card and push it off
    // screen whenever anything was pending.
    final hero = find.byWidgetPredicate(
      (w) => w.runtimeType.toString().contains('Hero') ||
          w.runtimeType.toString().contains('Rest'),
    );
    expect(hero, findsWidgets);

    final screenBottom = tester.view.physicalSize.height;
    expect(tester.getTopLeft(hero.first).dy, lessThan(screenBottom / 2),
        reason: 'today’s card must not be pushed below the fold');
    await _settle(tester);
  });

  testWidgets('survives a small screen', (tester) async {
    // The connect screen overflowed on anything shorter than the design.
    await _pumpToday(tester, size: const Size(320, 560));
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('never claims a rest day before the plan has loaded',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await SettingsRepository(db).ensureDefaults();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.light(), home: const TodayScreen()),
      ),
    );
    // First frame only — the database has not answered yet. Reading
    // `.value ?? const []` used to collapse "loading" into "no runs" and
    // cheerfully tell the athlete to take the day off.
    await tester.pump();
    expect(find.text('Rest day'), findsNothing);

    await tester.pumpAndSettle();
    await _settle(tester);
  });
}
