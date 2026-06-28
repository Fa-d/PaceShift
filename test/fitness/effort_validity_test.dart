import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/domain/fitness/effort_validity.dart';

void main() {
  group('isPhysicallyPlausibleEffort', () {
    test('accepts a normal run and a slow walk', () {
      expect(
          isPhysicallyPlausibleEffort(distanceKm: 5, durationSec: 25 * 60), isTrue);
      // 5 km walk at ~12:00/km.
      expect(
          isPhysicallyPlausibleEffort(distanceKm: 5, durationSec: 60 * 60), isTrue);
    });

    test('rejects impossible/garbage records', () {
      expect(isPhysicallyPlausibleEffort(distanceKm: 0, durationSec: 600), isFalse);
      expect(isPhysicallyPlausibleEffort(distanceKm: 5, durationSec: 0), isFalse);
      // 12 km in 2 min → ~360 km/h.
      expect(
          isPhysicallyPlausibleEffort(distanceKm: 12, durationSec: 120), isFalse);
      // Absurd distance.
      expect(
          isPhysicallyPlausibleEffort(distanceKm: 900, durationSec: 3600), isFalse);
    });
  });

  group('isPlausibleRunningEffort', () {
    test('accepts efforts inside the running pace band', () {
      // 5 km in 25:00 → 5:00/km.
      expect(
          isPlausibleRunningEffort(distanceKm: 5, durationSec: 25 * 60), isTrue);
    });

    test('rejects too-fast and too-slow paces', () {
      // 10 km in 20 min → 2:00/km, faster than the 2:30 floor.
      expect(
          isPlausibleRunningEffort(distanceKm: 10, durationSec: 20 * 60), isFalse);
      // 5 km in 90 min → 18:00/km, slower than the 15:00 ceiling (a walk).
      expect(
          isPlausibleRunningEffort(distanceKm: 5, durationSec: 90 * 60), isFalse);
    });
  });
}
