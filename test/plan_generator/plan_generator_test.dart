import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/models/workout_segment.dart';
import 'package:paceshift/domain/plan_generator/plan_generator.dart';
import 'package:paceshift/domain/plan_generator/plan_input.dart';

void main() {
  const generator = PlanGenerator();

  PlanInput inputFor(DateTime race, {int longDay = DateTime.saturday}) => PlanInput(
        raceDate: race,
        currentLongestRunKm: 18,
        preferredLongRunDay: longDay,
      );

  group('PlanGenerator structure', () {
    final race = DateTime(2026, 11, 1); // a Sunday
    final result = generator.generate(inputFor(race));

    test('plan is anchored to the race date', () {
      expect(isSameDate(result.plan.raceDate, race), isTrue);
      expect(result.plan.status, PlanStatus.active);
      expect(result.plan.taperWeeks, 3);
    });

    test('race week ends with the race long run on race day', () {
      final raceRun = result.runs.singleWhere(
        (r) => r.type == RunType.long && isSameDate(r.scheduledDate, race),
      );
      expect(raceRun.targetDistanceKm, 42.2);
      expect(raceRun.weekIndex, 19);
    });

    test('canonical 19-week seed ladder with 32km peak at week 15', () {
      final longRuns = result.runs.where((r) => r.type == RunType.long).toList()
        ..sort((a, b) => a.weekIndex.compareTo(b.weekIndex));
      final byWeek = {for (final r in longRuns) r.weekIndex: r.targetDistanceKm};
      expect(byWeek[1], 14);
      expect(byWeek[15], 32); // PEAK
      expect(byWeek[19], 42.2); // race
    });

    test('peak long run is at least taperWeeks before the race', () {
      final peak = result.runs.firstWhere((r) => r.targetDistanceKm == 32);
      final weeksBeforeRace = daysBetween(peak.scheduledDate, race) / 7;
      expect(weeksBeforeRace >= result.plan.taperWeeks, isTrue);
    });

    test('taper long runs descend after the peak', () {
      final longRuns = result.runs.where((r) => r.type == RunType.long).toList()
        ..sort((a, b) => a.weekIndex.compareTo(b.weekIndex));
      final w16 = longRuns.firstWhere((r) => r.weekIndex == 16).targetDistanceKm!;
      final w17 = longRuns.firstWhere((r) => r.weekIndex == 17).targetDistanceKm!;
      final w18 = longRuns.firstWhere((r) => r.weekIndex == 18).targetDistanceKm!;
      expect(w16 > w17, isTrue);
      expect(w17 > w18, isTrue);
    });

    test('three runs per week in a build week', () {
      final week5 = result.runs.where((r) => r.weekIndex == 5).toList();
      expect(week5.length, 3);
      expect(week5.where((r) => r.type == RunType.long).length, 1);
      expect(week5.where((r) => r.type == RunType.steady).length, 1);
      expect(week5.where((r) => r.type == RunType.easy).length, 1);
    });

    test('non-race long runs fall on the preferred long-run day', () {
      final longRuns = result.runs
          .where((r) => r.type == RunType.long && r.weekIndex != 19)
          .toList();
      for (final r in longRuns) {
        expect(r.scheduledDate.weekday, DateTime.saturday);
      }
    });
  });

  group('min-rest invariants (spec §4.3)', () {
    final result = generator.generate(inputFor(DateTime(2026, 11, 1)));

    test('no two hard runs on adjacent days', () {
      final hard = result.runs.where((r) => r.type.isHard).toList()
        ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      for (var i = 1; i < hard.length; i++) {
        final gap = daysBetween(hard[i - 1].scheduledDate, hard[i].scheduledDate);
        expect(gap >= 2, isTrue,
            reason: 'hard runs ${hard[i - 1].scheduledDate} & ${hard[i].scheduledDate} too close');
      }
    });

    test('a long run is never the day after another run', () {
      final byDate = {
        for (final r in result.runs) dateOnly(r.scheduledDate): r,
      };
      for (final r in result.runs.where((r) => r.type == RunType.long)) {
        final prevDay = addDays(r.scheduledDate, -1);
        expect(byDate.containsKey(prevDay), isFalse,
            reason: 'run found the day before long run on ${r.scheduledDate}');
      }
    });
  });

  group('reflow on race-date change', () {
    test('moving the race date re-anchors the whole plan and taper', () {
      final a = generator.generate(inputFor(DateTime(2026, 11, 1)));
      final b = generator.generate(inputFor(DateTime(2026, 12, 6)));

      expect(isSameDate(b.plan.raceDate, DateTime(2026, 12, 6)), isTrue);
      // Start date shifts by the same 5 weeks the race moved.
      final shiftDays = daysBetween(a.plan.startDate, b.plan.startDate);
      expect(shiftDays, 35);

      // Race long run sits on the new race day.
      final raceRun = b.runs.firstWhere((r) => r.weekIndex == 19 && r.type == RunType.long);
      expect(isSameDate(raceRun.scheduledDate, DateTime(2026, 12, 6)), isTrue);
    });
  });

  group('start long run clamp', () {
    test('weekly long runs never start absurdly below current longest', () {
      // Non-canonical length forces parametric generation.
      final input = PlanInput(
        raceDate: DateTime(2026, 10, 4),
        currentLongestRunKm: 22,
        preferredLongRunDay: DateTime.sunday,
        planWeeks: 16,
      );
      final result = generator.generate(input);
      final firstLong = result.runs
          .where((r) => r.type == RunType.long)
          .reduce((a, b) => a.weekIndex < b.weekIndex ? a : b);
      expect(firstLong.targetDistanceKm! >= 18, isTrue); // >= currentLongest - 4
    });
  });

  group('goal-time paces & structured workouts (Phase 6)', () {
    PlanInput goalInput() => PlanInput(
          raceDate: DateTime(2026, 11, 1),
          currentLongestRunKm: 22,
          preferredLongRunDay: DateTime.saturday,
          goalFinishSec: 4 * 3600, // sub-4 marathon
        );

    test('no goal time → no paces or segments (back-compat)', () {
      final result = generator.generate(inputFor(DateTime(2026, 11, 1)));
      expect(result.runs.every((r) => r.targetPaceSecPerKm == null), isTrue);
      expect(result.runs.every((r) => !r.isStructured), isTrue);
    });

    test('with a goal time, runs get paces and easy < race pace', () {
      final result = generator.generate(goalInput());
      final easy = result.runs.firstWhere((r) => r.type == RunType.easy);
      final raceRun =
          result.runs.firstWhere((r) => r.weekIndex == 19 && r.type == RunType.long);
      expect(easy.targetPaceSecPerKm, isNotNull);
      expect(raceRun.targetPaceSecPerKm, closeTo(4 * 3600 / 42.2, 0.5));
      // Easy pace is slower (more sec/km) than goal race pace.
      expect(easy.targetPaceSecPerKm!, greaterThan(raceRun.targetPaceSecPerKm!));
    });

    test('build-week steady runs become structured quality sessions', () {
      final result = generator.generate(goalInput());
      final structured =
          result.runs.where((r) => r.type == RunType.steady && r.isStructured);
      expect(structured, isNotEmpty);
      // A structured session has a warm-up and a cool-down.
      final sample = structured.first;
      expect(sample.segments!.first.kind, SegmentKind.warmup);
      expect(sample.segments!.last.kind, SegmentKind.cooldown);
    });

    test('adding paces does not change run count, types, or min-rest', () {
      final plain = generator.generate(inputFor(DateTime(2026, 11, 1)));
      final paced = generator.generate(goalInput());
      expect(paced.runs.length, plain.runs.length);

      // Hard runs still never land on adjacent days (§4.3 preserved).
      final hard = paced.runs.where((r) => r.type.isHard).toList()
        ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      for (var i = 1; i < hard.length; i++) {
        expect(daysBetween(hard[i - 1].scheduledDate, hard[i].scheduledDate) >= 2,
            isTrue);
      }
    });
  });

  group('plan length derived from the race date', () {
    final from = DateTime(2026, 3, 2); // a Monday

    test('a race 8 weeks out yields a 9-week plan starting this week', () {
      final race = addDays(from, 8 * 7); // race week is 8 weeks after this one
      final weeks = PlanInput.weeksUntilRace(from, race);
      expect(weeks, 9);

      final result = generator.generate(PlanInput(
        raceDate: race,
        currentLongestRunKm: 18,
        preferredLongRunDay: DateTime.saturday,
        planWeeks: weeks,
      ));

      // The whole point: the plan must not start in the past.
      expect(result.plan.startDate, previousOrSameWeekday(from, DateTime.monday));
      expect(result.plan.totalWeeks, 9);
      expect(
        result.runs.every((r) => !r.scheduledDate.isBefore(result.plan.startDate)),
        isTrue,
      );
    });

    test('the default 19 would have started such a plan in the past', () {
      final race = addDays(from, 8 * 7);
      final withDefault = generator.generate(PlanInput(
        raceDate: race,
        currentLongestRunKm: 18,
        preferredLongRunDay: DateTime.saturday,
      ));
      // The regression this fixes: ten weeks of runs the athlete never had a
      // chance to do, all marked missed on the first rollover.
      expect(withDefault.plan.startDate.isBefore(from), isTrue);
    });

    test('clamps a very near race up to the minimum plan length', () {
      final race = addDays(from, 7);
      expect(PlanInput.weeksUntilRace(from, race), PlanInput.minPlanWeeks);
    });

    test('clamps a very distant race down to the maximum', () {
      final race = addDays(from, 60 * 7);
      expect(PlanInput.weeksUntilRace(from, race), PlanInput.maxPlanWeeks);
    });

    test('race week itself counts as one week', () {
      expect(PlanInput.weeksUntilRace(from, addDays(from, 3)),
          PlanInput.minPlanWeeks);
    });
  });

  group('peak long run derived from race distance', () {
    test('a marathon keeps the canonical 32 km peak', () {
      expect(PlanInput.defaultPeakLongRunKm(42.2), 32);
    });

    test('a half marathon peaks near 19 km, not 32', () {
      expect(PlanInput.defaultPeakLongRunKm(21.1), 19);
    });

    test('a 10k peaks above race distance', () {
      expect(PlanInput.defaultPeakLongRunKm(10), 13);
    });

    test('a generated half-marathon plan never schedules a 32 km long run', () {
      final race = DateTime(2026, 10, 4);
      final result = generator.generate(PlanInput(
        raceDate: race,
        raceDistanceKm: 21.1,
        currentLongestRunKm: 14,
        preferredLongRunDay: DateTime.sunday,
        planWeeks: PlanInput.weeksUntilRace(DateTime(2026, 8, 3), race),
        peakLongRunKm: PlanInput.defaultPeakLongRunKm(21.1),
      ));

      final longs = result.runs
          .where((r) => r.type == RunType.long && !isSameDate(r.scheduledDate, race))
          .map((r) => r.targetDistanceKm!)
          .toList();
      expect(longs, isNotEmpty);
      // Previously every plan peaked at 32 km — 1.5x this race distance.
      expect(longs.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(19.0));
    });

    test('the marathon default still produces the spec seed ladder', () {
      final race = DateTime(2026, 11, 1);
      final canonical = generator.generate(inputFor(race));
      final explicit = generator.generate(PlanInput(
        raceDate: race,
        currentLongestRunKm: 18,
        preferredLongRunDay: DateTime.saturday,
        peakLongRunKm: PlanInput.defaultPeakLongRunKm(42.2),
      ));

      expect(explicit.runs.length, canonical.runs.length);
      final a = canonical.runs.where((r) => r.type == RunType.long).toList();
      final b = explicit.runs.where((r) => r.type == RunType.long).toList();
      for (var i = 0; i < a.length; i++) {
        expect(b[i].targetDistanceKm, a[i].targetDistanceKm);
      }
    });
  });
}
