import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/data/db/app_database.dart';
import 'package:paceshift/data/repositories/plan_repository.dart';
import 'package:paceshift/data/repositories/run_repository.dart';
import 'package:paceshift/data/repositories/settings_repository.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/plan_generator/plan_input.dart';
import 'package:paceshift/presentation/providers/providers.dart';
import 'package:paceshift/presentation/stats/stats_data.dart';

/// Covers the Riverpod wiring around [ProgressCalculator] — that the provider
/// reaches the database, resolves an active plan, and feeds `asOf` from
/// `todayProvider`. The arithmetic itself is covered by
/// `test/progress/progress_stats_test.dart`.
/// `logExtraRun` only records runs, so a walk has to be written directly —
/// which is exactly how one arrives in reality, via the health sync.
Future<void> _logWalk(
  AppDatabase db, {
  required DateTime date,
  required double km,
}) =>
    db.into(db.completedRuns).insert(CompletedRunsCompanion.insert(
          date: dateOnly(date),
          actualDistanceKm: km,
          durationSec: (km * 720).round(),
          avgPaceSecPerKm: 720,
          source: RunSource.manual,
          activityType: const Value(ActivityType.walk),
        ));

void main() {
  late AppDatabase db;

  Future<ProviderContainer> container({DateTime? asOf}) async {
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      if (asOf != null) todayProvider.overrideWithValue(asOf),
    ]);
    addTearDown(c.dispose);

    // Hold a listener open on each stream before awaiting it. Providers
    // auto-dispose, so a bare `read(p.future)` drops its subscription and the
    // drift stream is cancelled before it ever emits — the future then hangs.
    for (final p in [activePlanProvider, plannedRunsProvider, completedRunsProvider]) {
      c.listen(p, (_, _) {}, fireImmediately: true);
    }
    await c.read(activePlanProvider.future);
    await c.read(plannedRunsProvider.future);
    await c.read(completedRunsProvider.future);
    return c;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await SettingsRepository(db).ensureDefaults();
  });

  tearDown(() => db.close());

  test('with no plan, reports empty', () async {
    final c = await container();
    final stats = c.read(statsProvider);

    expect(stats.hasPlanData, isFalse);
    expect(stats.hasLoggedWork, isFalse);
  });

  test('a fresh plan is chartable but has nothing logged', () async {
    await PlanRepository(db).createPlanFromInput(PlanInput(
      raceDate: addDays(today(), 133),
      currentLongestRunKm: 18,
      preferredLongRunDay: DateTime.saturday,
    ));

    final c = await container();
    final stats = c.read(statsProvider);

    expect(stats.hasPlanData, isTrue);
    expect(stats.hasLoggedWork, isFalse);
    expect(stats.weeklyVolumes.first.week, 1);
    // Contiguous 1..N, so the chart can index by position.
    for (var i = 0; i < stats.weeklyVolumes.length; i++) {
      expect(stats.weeklyVolumes[i].week, i + 1);
    }
  });

  test('a logged run lands in the right week and the lifetime total', () async {
    await PlanRepository(db).createPlanFromInput(PlanInput(
      raceDate: addDays(today(), 133),
      currentLongestRunKm: 18,
      preferredLongRunDay: DateTime.saturday,
    ));
    final plan = await PlanRepository(db).getActivePlan();
    // Third week of the plan, so the bucket is unambiguous.
    final when = addDays(plan!.startDate, 15);
    await RunRepository(db)
        .logExtraRun(date: when, distanceKm: 5, durationSec: 1500);

    final c = await container(asOf: addDays(when, 1));
    final stats = c.read(statsProvider);

    expect(stats.hasLoggedWork, isTrue);
    expect(stats.totalCompletedKm, 5);
    expect(stats.weeklyVolumes[2].completedKm, 5);
  });

  test('a logged walk does not count toward running stats', () async {
    await PlanRepository(db).createPlanFromInput(PlanInput(
      raceDate: addDays(today(), 133),
      currentLongestRunKm: 18,
      preferredLongRunDay: DateTime.saturday,
    ));
    await _logWalk(db, date: today(), km: 15);

    final c = await container();
    final stats = c.read(statsProvider);

    expect(stats.totalCompletedKm, 0);
    expect(stats.hasLoggedWork, isFalse);
  });

  test('readiness reports no signal on a brand-new plan', () async {
    await PlanRepository(db).createPlanFromInput(PlanInput(
      raceDate: addDays(today(), 133),
      currentLongestRunKm: 18,
      preferredLongRunDay: DateTime.saturday,
    ));

    final c = await container();
    final readiness = c.read(readinessProvider);

    // The provider used to pass a hardcoded peak of 32 km and the scorer used
    // to award vacuous credit, so this read 75/100 "On track".
    expect(readiness, isNotNull);
    expect(readiness!.hasSignal, isFalse);
    expect(readiness.score, isNot(75));

    // And the AI grounding string must not quote a score either.
    expect(c.read(planSummaryProvider), contains('not yet measurable'));
  });
}
