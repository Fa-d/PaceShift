import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/core/theme.dart';
import 'package:paceshift/data/db/app_database.dart';
import 'package:paceshift/data/repositories/plan_repository.dart';
import 'package:paceshift/data/repositories/run_repository.dart';
import 'package:paceshift/data/repositories/settings_repository.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/plan_generator/plan_input.dart';
import 'package:paceshift/presentation/plan/plan_screen.dart';
import 'package:paceshift/presentation/providers/providers.dart';
import 'package:paceshift/presentation/widgets/segment_bar.dart';

/// Widget coverage for the redesigned Plan screen. The Plan screen had no test
/// at all before the redesign; this locks in the headline behaviours the design
/// depends on: the hero (countdown + week), the week/month toggle, the filter
/// chips, the no-match empty state, the heatmap deep-link, units, the empty
/// state, and that none of it overflows on a small screen at 2× text scale.
Future<AppDatabase> _pumpPlan(
  WidgetTester tester, {
  bool withPlan = true,
  Size size = const Size(400, 900),
  int? goalFinishSec,
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
      goalFinishSec: goalFinishSec,
    ));
  }
  return db;
}

Future<void> _pump(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (_, _) => const PlanScreen()),
            GoRoute(
              path: '/run/:id',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: Text('run ${state.pathParameters['id']}'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Drain any trailing animations / timers so a deferred error can't bleed into
/// the next test.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  // The week/month toggle fires HapticFeedback; without a handler the unawaited
  // platform call surfaces as a MissingPluginException. Stub the platform
  // channel so the toggle tests stay clean.
  setUp(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  testWidgets('with no plan, invites the athlete to create one', (tester) async {
    final db = await _pumpPlan(tester, withPlan: false);
    await _pump(tester, db);

    expect(find.text('No plan yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('hero shows the week and a race countdown', (tester) async {
    final db = await _pumpPlan(tester);
    await _pump(tester, db);

    expect(find.textContaining('Week 1 of'), findsOneWidget);
    expect(find.text('days to race'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('toggles to the month view and back without errors',
      (tester) async {
    final db = await _pumpPlan(tester);
    await _pump(tester, db);

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.view_week_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('a type filter chip narrows the week to that run type',
      (tester) async {
    final db = await _pumpPlan(tester);
    await _pump(tester, db);

    // Week 1 is anchored at the top on open, so its cards are visible.
    expect(find.text('Easy run'), findsWidgets);
    expect(find.text('Long run'), findsWidgets);

    await tester.tap(find.text('Long'));
    await tester.pumpAndSettle();

    expect(find.text('Easy run'), findsNothing);
    expect(find.text('Long run'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('offers no "Runs only" chip when the plan is all running',
      (tester) async {
    final db = await _pumpPlan(tester);
    await _pump(tester, db);

    // PlanGenerator emits running sessions only — a rest day is the *absence*
    // of a run, not a RunType.rest row — so the chip would do visibly nothing.
    expect(find.text('Runs only'), findsNothing);
    expect(find.text('Remaining'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('shows a no-match empty state and clears it', (tester) async {
    final db = await _pumpPlan(tester);
    // Complete every running session so "Runs only" + "Remaining" matches
    // nothing.
    final plan = await PlanRepository(db).getActivePlan();
    final runs = await RunRepository(db).getPlannedRuns(plan!.id);
    for (final r in runs.where((r) => r.type.isRun)) {
      await RunRepository(db).updateRunStatus(r.id, RunStatus.completed);
    }
    await _pump(tester, db);

    await tester.tap(find.text('Remaining'));
    await tester.pumpAndSettle();

    expect(find.text('No runs match'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('No runs match'), findsNothing);
    expect(find.textContaining('Week'), findsWidgets);
    await _settle(tester);
  });

  testWidgets('tapping a heatmap day opens that run', (tester) async {
    final db = await _pumpPlan(tester);
    final plan = await PlanRepository(db).getActivePlan();
    final runs = await RunRepository(db).getPlannedRuns(plan!.id);
    // Which month the heatmap actually opens on: today's, clamped into the
    // plan's range. A plan generated today starts on the *next* Monday, so
    // today's month can be entirely empty (or before the plan begins) — the old
    // assumption that today has a session, or even that its month does, was
    // wrong on both counts. Take the earliest session on the displayed page and
    // resolve the day's representative run the way the cell does, so a
    // doubled-up day can't fail the assertion either.
    final t = today();
    final start = plan.startDate;
    final shown = t.isBefore(start) ? DateTime(start.year, start.month) : t;
    final monthRuns = runs
        .where((r) =>
            r.scheduledDate.year == shown.year &&
            r.scheduledDate.month == shown.month)
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    expect(monthRuns, isNotEmpty);
    final d = monthRuns.first.scheduledDate;
    final sameDay =
        monthRuns.where((r) => isSameDate(r.scheduledDate, d)).toList();
    final expected =
        sameDay.firstWhere((r) => r.type.isRun, orElse: () => sameDay.first);

    await _pump(tester, db);
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();

    final cell =
        find.byKey(ValueKey('month-day-${d.year}-${d.month}-${d.day}'));
    await tester.ensureVisible(cell);
    await tester.pumpAndSettle();
    await tester.tap(cell);
    await tester.pumpAndSettle();

    expect(find.text('run ${expected.id}'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('renders distances in miles for an imperial athlete',
      (tester) async {
    final db = await _pumpPlan(tester);
    final settings = SettingsRepository(db);
    await settings.update((await settings.getSettings())
        .copyWith(units: UnitSystem.imperial));
    await _pump(tester, db);

    expect(find.textContaining(' mi'), findsWidgets);
    expect(find.textContaining(' km'), findsNothing);
    await _settle(tester);
  });

  testWidgets('previews a structured session on its run card', (tester) async {
    // The generator only builds structured quality sessions when a goal time
    // gives it paces to work with, and only from build week 3 — so without a
    // goal there is nothing for SegmentBar to draw and this path went unproven.
    final db = await _pumpPlan(tester, goalFinishSec: 3 * 3600 + 45 * 60);
    await _pump(tester, db);

    await tester.scrollUntilVisible(find.byType(SegmentBar).first, 300);
    expect(find.byType(SegmentBar), findsWidgets);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('no overflow at 320x560 with 2x text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final db = await _pumpPlan(tester, size: const Size(320, 560));
    await _pump(tester, db);
    expect(tester.takeException(), isNull);

    // Month view too — its day cells are the overflow risk at scale.
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });
}
