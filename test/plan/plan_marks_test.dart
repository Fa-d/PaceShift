import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/design.dart';
import 'package:paceshift/presentation/plan/plan_marks.dart';

void main() {
  group('intensityAlpha', () {
    test('a zero-distance day returns the floor', () {
      expect(intensityAlpha(0, 42), Alpha.tint);
    });

    test('at the plan max returns the top of the ramp', () {
      expect(intensityAlpha(42, 42), closeTo(0.60, 1e-9));
    });

    test('above the plan max clamps to the top', () {
      expect(intensityAlpha(100, 42), closeTo(0.60, 1e-9));
    });

    test('max == 0 returns the floor (nothing to scale against)', () {
      expect(intensityAlpha(5, 0), Alpha.tint);
    });

    test('a non-finite value returns the floor', () {
      expect(intensityAlpha(double.nan, 42), Alpha.tint);
      expect(intensityAlpha(double.infinity, 42), Alpha.tint);
    });

    test('a half-max day lerps halfway between floor and top', () {
      // floor (Alpha.tint = 0.14) → 0.60; midpoint at value = max / 2.
      final expected = (Alpha.tint + 0.60) / 2;
      expect(intensityAlpha(21, 42), closeTo(expected, 1e-9));
    });

    test('monotonically increases with value', () {
      var prev = intensityAlpha(0, 42);
      for (var v = 1; v <= 42; v++) {
        final next = intensityAlpha(v.toDouble(), 42);
        expect(next, greaterThanOrEqualTo(prev));
        prev = next;
      }
    });
  });
}
