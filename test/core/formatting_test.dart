import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/formatting.dart';
import 'package:paceshift/domain/models/enums.dart';

void main() {
  const metric = UnitSystem.metric;
  const imperial = UnitSystem.imperial;

  group('formatDecimal', () {
    test('keeps one decimal for fractional values', () {
      expect(formatDecimal(3.44), '3.4');
      expect(formatDecimal(3.45), '3.5');
      // The regression: a sub-1 total used to render as a bare "0".
      expect(formatDecimal(0.6), '0.6');
      expect(formatDecimal(0.04), '0');
    });

    test('trims a trailing .0', () {
      expect(formatDecimal(12.0), '12');
      expect(formatDecimal(12.02), '12');
      expect(formatDecimal(0), '0');
    });

    test('honours a custom precision', () {
      expect(formatDecimal(3.456, decimals: 2), '3.46');
    });

    test('handles negatives', () {
      expect(formatDecimal(-2.5), '-2.5');
    });
  });

  group('toDisplay / fromDisplay', () {
    test('metric is the identity in both directions', () {
      expect(metric.toDisplay(13.1), 13.1);
      expect(metric.fromDisplay(13.1), 13.1);
    });

    test('imperial converts km to miles for display', () {
      expect(imperial.toDisplay(21.0975), closeTo(13.109, 0.001));
      expect(imperial.toDisplay(1.609344), closeTo(1.0, 1e-9));
    });

    test('fromDisplay converts typed miles back to stored km', () {
      // The manual-log-sheet bug: "13.1" typed by an imperial athlete is a
      // half marathon (~21.08 km), not 13.1 km.
      expect(imperial.fromDisplay(13.1), closeTo(21.082, 0.001));
      expect(imperial.fromDisplay(1.0), closeTo(1.609344, 1e-9));
    });

    test('round-trips exactly in both unit systems', () {
      for (final units in [metric, imperial]) {
        for (final km in [0.0, 0.6, 5.0, 13.1, 21.0975, 42.195, 137.4]) {
          expect(units.fromDisplay(units.toDisplay(km)), closeTo(km, 1e-9),
              reason: '$units round-trip failed for $km');
          expect(units.toDisplay(units.fromDisplay(km)), closeTo(km, 1e-9),
              reason: '$units inverse round-trip failed for $km');
        }
      }
    });
  });

  group('distance / distanceValue', () {
    test('append the right unit label', () {
      expect(metric.distance(12.5), '12.5 km');
      expect(imperial.distance(1.609344), '1 mi');
    });

    test('trim a trailing .0', () {
      expect(metric.distance(12.0), '12 km');
      expect(metric.distanceValue(12.0), '12');
    });

    test('keep one decimal for small values rather than collapsing to 0', () {
      expect(metric.distanceValue(0.6), '0.6');
      expect(metric.distance(3.44), '3.4 km');
    });

    test('render null as an em dash', () {
      expect(metric.distance(null), '—');
      expect(metric.distanceValue(null), '—');
    });

    test('distance is distanceValue plus the label', () {
      for (final units in [metric, imperial]) {
        for (final km in [0.6, 5.0, 21.0975]) {
          expect(units.distance(km),
              '${units.distanceValue(km)} ${units.distanceLabel}');
        }
      }
    });
  });

  group('pace', () {
    test('formats sec/km as mm:ss with the metric suffix', () {
      expect(metric.pace(342), '5:42 /km');
      expect(metric.pace(300), '5:00 /km');
    });

    test('converts to sec/mile for imperial', () {
      // 5:00/km is 482.8 s/mi, which rounds to 8:03.
      expect(imperial.pace(300), '8:03 /mi');
      expect(imperial.pace(372.82), '10:00 /mi');
    });

    test('renders a missing pace as an em dash', () {
      expect(metric.pace(0), '—');
      expect(metric.pace(-1), '—');
    });
  });

  group('duration formatting', () {
    test('formatDuration splits hours and minutes', () {
      expect(formatDuration(4320), '1h 12m');
      expect(formatDuration(2880), '48m');
      expect(formatDuration(0), '0m');
    });

    test('formatFinishTime pads minutes and seconds', () {
      expect(formatFinishTime(13512), '3:45:12');
      expect(formatFinishTime(3600), '1:00:00');
    });
  });
}
