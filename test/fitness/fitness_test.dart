import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/domain/fitness/fitness_estimator.dart';
import 'package:paceshift/domain/fitness/race_predictor.dart';
import 'package:paceshift/domain/models/completed_run.dart';
import 'package:paceshift/domain/models/enums.dart';

CompletedRun effort(double km, int sec, {DateTime? date, int id = 0}) =>
    CompletedRun(
      id: id,
      date: date ?? DateTime(2026, 1, 1),
      actualDistanceKm: km,
      durationSec: sec,
      avgPaceSecPerKm: sec / km,
      source: RunSource.manual,
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
  });

  group('RacePredictor', () {
    const predictor = RacePredictor();

    test('no data → null', () {
      expect(
        predictor.predict(raceDistanceKm: 42.2, runs: const []),
        isNull,
      );
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
