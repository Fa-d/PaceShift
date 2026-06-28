import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/domain/paces/pace_calculator.dart';
import 'package:paceshift/domain/paces/vdot.dart';

void main() {
  group('Vdot.fromPerformance (Daniels reference values)', () {
    test('5 km in 20:00 ≈ VDOT 49.8', () {
      final vdot = Vdot.fromPerformance(5.0, 20 * 60);
      expect(vdot, closeTo(49.8, 0.4));
    });

    test('faster effort over the same distance yields a higher VDOT', () {
      final slow = Vdot.fromPerformance(5.0, 25 * 60);
      final fast = Vdot.fromPerformance(5.0, 20 * 60);
      expect(fast, greaterThan(slow));
    });

    test('zero/invalid inputs are safe', () {
      expect(Vdot.fromPerformance(0, 1200), 0);
      expect(Vdot.fromPerformance(5, 0), 0);
    });
  });

  group('Vdot.riegelPredictSec', () {
    test('10 km in 40:00 predicts a half in ~88 minutes', () {
      final sec = Vdot.riegelPredictSec(
        knownSec: 40 * 60,
        knownKm: 10,
        targetKm: 21.0975,
      );
      expect(sec, closeTo(5296, 30)); // ~1:28:16
    });

    test('predicting the same distance returns the same time', () {
      final sec =
          Vdot.riegelPredictSec(knownSec: 1800, knownKm: 10, targetKm: 10);
      expect(sec, closeTo(1800, 1));
    });
  });

  group('Vdot.paceSecPerKmAtIntensity', () {
    test('higher intensity = faster pace (fewer sec/km)', () {
      const vdot = 50.0;
      final easy = Vdot.paceSecPerKmAtIntensity(vdot, 0.70);
      final threshold = Vdot.paceSecPerKmAtIntensity(vdot, 0.88);
      final interval = Vdot.paceSecPerKmAtIntensity(vdot, 0.98);
      final repetition = Vdot.paceSecPerKmAtIntensity(vdot, 1.05);
      expect(easy, greaterThan(threshold));
      expect(threshold, greaterThan(interval));
      expect(interval, greaterThan(repetition));
    });
  });

  group('PaceCalculator', () {
    const calc = PaceCalculator();

    test('fromGoalTime sets race pace to the exact goal pace', () {
      // 4:00:00 marathon → 14400 s over 42.2 km.
      final paces =
          calc.fromGoalTime(raceDistanceKm: 42.2, goalSec: 14400);
      expect(paces.race, closeTo(14400 / 42.2, 0.001));
    });

    test('zones are ordered easy → repetition (slow → fast)', () {
      final paces = calc.fromVdot(50);
      expect(paces.easy, greaterThan(paces.marathon));
      expect(paces.marathon, greaterThan(paces.threshold));
      expect(paces.threshold, greaterThan(paces.interval));
      expect(paces.interval, greaterThan(paces.repetition));
    });

    test('forZone resolves each zone', () {
      final paces = calc.fromVdot(50);
      expect(paces.forZone(PaceZone.easy), paces.easy);
      expect(paces.forZone(PaceZone.race), paces.race);
    });
  });
}
