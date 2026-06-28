import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/presentation/stats/stats_data.dart';

void main() {
  group('weekOffset', () {
    final start = DateTime(2026, 3, 2); // a Monday, plan week 1.

    test('plan start and first 6 days are week 1', () {
      expect(weekOffset(start, start), 1);
      expect(weekOffset(start, start.add(const Duration(days: 6))), 1);
    });

    test('subsequent weeks increment', () {
      expect(weekOffset(start, start.add(const Duration(days: 7))), 2);
      expect(weekOffset(start, start.add(const Duration(days: 20))), 3);
    });

    test('pre-plan dates spread across week 0, -1, … (not collapsed to 1)', () {
      expect(weekOffset(start, start.subtract(const Duration(days: 1))), 0);
      expect(weekOffset(start, start.subtract(const Duration(days: 7))), 0);
      expect(weekOffset(start, start.subtract(const Duration(days: 8))), -1);
      expect(weekOffset(start, start.subtract(const Duration(days: 21))), -2);
    });
  });
}
