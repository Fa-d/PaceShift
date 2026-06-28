import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/domain/fitness/fitness_estimator.dart';
import 'package:paceshift/domain/fitness/race_predictor.dart';
import 'package:paceshift/domain/models/completed_run.dart';
import 'package:paceshift/domain/models/enums.dart';

CompletedRun effort(double km, int sec,
        {DateTime? date,
        int id = 0,
        ActivityType activityType = ActivityType.run}) =>
    CompletedRun(
      id: id,
      date: date ?? DateTime(2026, 1, 1),
      actualDistanceKm: km,
      durationSec: sec,
      avgPaceSecPerKm: sec / km,
      source: RunSource.manual,
      activityType: activityType,
    );

void main() {
  group('FitnessEstimator', () {
    const est = FitnessEstimator();

    test('no qualifying runs → null', () {
      expect(est.estimateVdot(const []), isNull);
      expect(est.estimateVdot([effort(1.0, 300)]), isNull); // below minQualityKm
    });

    test('estimates a plausible VDOT from efforts', () {
      final vdot = est.estimateVdot([
        effort(5, 20 * 60, id: 1),
        effort(10, 44 * 60, id: 2),
        effort(8, 40 * 60, id: 3),
      ]);
      expect(vdot, isNotNull);
      expect(vdot!, inInclusiveRange(35, 60));
    });

    test('faster efforts raise the estimate', () {
      final slow = est.estimateVdot([
        effort(5, 28 * 60, id: 1),
        effort(5, 27 * 60, id: 2),
        effort(5, 29 * 60, id: 3),
      ])!;
      final fast = est.estimateVdot([
        effort(5, 20 * 60, id: 1),
        effort(5, 21 * 60, id: 2),
        effort(5, 22 * 60, id: 3),
      ])!;
      expect(fast, greaterThan(slow));
    });

    test('a glitch effort does not inflate the estimate', () {
      final clean = [
        effort(5, 25 * 60, id: 1),
        effort(8, 42 * 60, id: 2),
        effort(10, 52 * 60, id: 3),
      ];
      final base = est.estimateVdot(clean)!;
      // Add a corrupt record: 12 km in 2 min (impossibly fast). It must be
      // ignored, so the estimate is unchanged rather than wildly inflated.
      final withGlitch = est.estimateVdot([
        ...clean,
        effort(12, 120, id: 4),
      ])!;
      expect(withGlitch, closeTo(base, 0.001));
    });

    test('walks are ignored even when long and fast enough on distance', () {
      final vdot = est.estimateVdot([
        effort(6, 70 * 60, id: 1, activityType: ActivityType.walk),
        effort(8, 90 * 60, id: 2, activityType: ActivityType.walk),
      ]);
      expect(vdot, isNull);
    });
  });

  group('RacePredictor', () {
    const predictor = RacePredictor();

    test('no data → null', () {
      expect(
        predictor.predict(raceDistanceKm: 42.2, runs: const []),
        isNull,
      );
    });

    test('garbage-only data → null (no absurd prediction)', () {
      // A single GPS-spiked record must not produce a 5-minute marathon.
      final prediction = predictor.predict(raceDistanceKm: 42.2, runs: [
        effort(12, 120, id: 1),
      ]);
      expect(prediction, isNull);
    });

    test('walks-only data → null', () {
      final prediction = predictor.predict(raceDistanceKm: 42.2, runs: [
        effort(6, 70 * 60, id: 1, activityType: ActivityType.walk),
      ]);
      expect(prediction, isNull);
    });

    test('a realistic effort yields a plausible marathon band', () {
      final p = predictor.predict(raceDistanceKm: 42.2, runs: [
        effort(10, 55 * 60, id: 1),
        effort(16, 95 * 60, id: 2),
        effort(21, 130 * 60, id: 3),
      ])!;
      // Between a ~2:00 world record and a ~7h cutoff.
      expect(p.predictedSec, inInclusiveRange(2 * 3600, 7 * 3600));
    });

    test('fitter athlete gets a faster predicted marathon', () {
      final slow = predictor.predict(raceDistanceKm: 42.2, runs: [
        effort(10, 60 * 60, id: 1),
        effort(15, 95 * 60, id: 2),
        effort(20, 130 * 60, id: 3),
      ])!;
      final fast = predictor.predict(raceDistanceKm: 42.2, runs: [
        effort(10, 45 * 60, id: 1),
        effort(15, 70 * 60, id: 2),
        effort(20, 95 * 60, id: 3),
      ])!;
      expect(fast.predictedSec, lessThan(slow.predictedSec));
    });

    test('confidence requires a long-enough effort', () {
      final shortOnly = predictor.predict(raceDistanceKm: 42.2, runs: [
        effort(8, 40 * 60, id: 1),
        effort(8, 41 * 60, id: 2),
        effort(8, 42 * 60, id: 3),
      ])!;
      expect(shortOnly.confident, isFalse);

      final withLong = predictor.predict(raceDistanceKm: 42.2, runs: [
        effort(8, 40 * 60, id: 1),
        effort(25, 140 * 60, id: 2),
        effort(8, 42 * 60, id: 3),
      ])!;
      expect(withLong.confident, isTrue);
    });
  });
}
