import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/date_utils.dart';

void main() {
  group('daysBetween', () {
    test('counts whole calendar days in both directions', () {
      final a = DateTime(2026, 3, 2);
      expect(daysBetween(a, a), 0);
      expect(daysBetween(a, DateTime(2026, 3, 9)), 7);
      expect(daysBetween(DateTime(2026, 3, 9), a), -7);
    });

    test('ignores time of day', () {
      expect(
        daysBetween(DateTime(2026, 3, 2, 23, 59), DateTime(2026, 3, 3, 0, 1)),
        1,
      );
    });

    test('is unaffected by a DST transition', () {
      // Europe/London springs forward on 2026-03-29; that day is 23h long, so
      // an unnormalised `.inDays` would report 6 for this 7-day span.
      expect(daysBetween(DateTime(2026, 3, 26), DateTime(2026, 4, 2)), 7);
      // …and falls back on 2026-10-25 (25h), which would report 8.
      expect(daysBetween(DateTime(2026, 10, 22), DateTime(2026, 10, 29)), 7);
    });
  });

  group('planWeek', () {
    final start = DateTime(2026, 3, 2); // a Monday, plan week 1.

    test('plan start and first 6 days are week 1', () {
      expect(planWeek(start, start), 1);
      expect(planWeek(start, start.add(const Duration(days: 6))), 1);
    });

    test('subsequent weeks increment', () {
      expect(planWeek(start, start.add(const Duration(days: 7))), 2);
      expect(planWeek(start, start.add(const Duration(days: 20))), 3);
    });

    test('pre-plan dates spread across week 0, -1, … (not collapsed to 1)', () {
      expect(planWeek(start, start.subtract(const Duration(days: 1))), 0);
      expect(planWeek(start, start.subtract(const Duration(days: 7))), 0);
      expect(planWeek(start, start.subtract(const Duration(days: 8))), -1);
      expect(planWeek(start, start.subtract(const Duration(days: 21))), -2);
    });

    test('floor, not truncation: day -1 and day -6 share a week', () {
      // `~/` would round both toward zero and answer 1 for each — the bug this
      // helper exists to remove.
      expect(planWeek(start, addDays(start, -1)), 0);
      expect(planWeek(start, addDays(start, -6)), 0);
      expect(planWeek(start, addDays(start, -7)), 0);
      expect(planWeek(start, addDays(start, -8)), -1);
    });
  });

  group('planWeekClamped', () {
    final start = DateTime(2026, 3, 2);

    test('matches planWeek from the plan start onward', () {
      for (var d = 0; d < 40; d++) {
        final date = addDays(start, d);
        expect(planWeekClamped(start, date), planWeek(start, date));
      }
    });

    test('floors pre-plan dates at week 1', () {
      expect(planWeekClamped(start, addDays(start, -1)), 1);
      expect(planWeekClamped(start, addDays(start, -60)), 1);
    });
  });

  group('planWeekStart', () {
    final start = DateTime(2026, 3, 2);

    test('week 1 starts on the plan start date', () {
      expect(planWeekStart(start, 1), start);
    });

    test('round-trips with planWeek across a 200-day sweep', () {
      for (var d = -60; d < 200; d++) {
        final date = addDays(start, d);
        final weekStart = planWeekStart(start, planWeek(start, date));
        expect(!date.isBefore(weekStart), isTrue,
            reason: 'day $d fell before its own week start');
        expect(date.isBefore(addDays(weekStart, 7)), isTrue,
            reason: 'day $d fell past its own week end');
      }
    });
  });

  group('weekday helpers', () {
    test('previousOrSameWeekday is identity on the weekday itself', () {
      final monday = DateTime(2026, 3, 2);
      expect(previousOrSameWeekday(monday, DateTime.monday), monday);
      expect(previousOrSameWeekday(addDays(monday, 6), DateTime.monday), monday);
    });

    test('nextOrSameWeekday is identity on the weekday itself', () {
      final sunday = DateTime(2026, 3, 8);
      expect(nextOrSameWeekday(sunday, DateTime.sunday), sunday);
      expect(nextOrSameWeekday(DateTime(2026, 3, 2), DateTime.sunday), sunday);
    });
  });
}
