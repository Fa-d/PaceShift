import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/presentation/stats/chart_math.dart';

void main() {
  group('niceAxisMax', () {
    test('adds headroom above the largest value', () {
      expect(niceAxisMax(50, fallback: 10), closeTo(60, 1e-9));
    });

    test('falls back when there is nothing to plot', () {
      expect(niceAxisMax(0, fallback: 10), 10);
      expect(niceAxisMax(-5, fallback: 35), 35);
      expect(niceAxisMax(double.nan, fallback: 10), 10);
    });
  });

  group('niceInterval', () {
    test('is always positive, even for degenerate input', () {
      expect(niceInterval(0), greaterThan(0));
      expect(niceInterval(-1), greaterThan(0));
      expect(niceInterval(double.nan), greaterThan(0));
      expect(niceInterval(10, ticks: 0), greaterThan(0));
    });

    test('never produces more than ticks+1 gridlines, across a wide sweep', () {
      for (var axisMax = 0.1; axisMax < 500; axisMax += 0.1) {
        final interval = niceInterval(axisMax);
        expect(interval, greaterThan(0), reason: 'axisMax=$axisMax');
        expect(axisMax / interval, lessThanOrEqualTo(5.0),
            reason: 'axisMax=$axisMax gave interval=$interval');
      }
    });

    test('stays finer than the axis for small imperial volumes', () {
      // 3 mi weeks: the old `.clamp(5, 100)` floor produced a single gridline.
      final axisMax = niceAxisMax(3.0, fallback: 10);
      final interval = niceInterval(axisMax);
      expect(interval, lessThan(axisMax));
      expect(axisMax / interval, greaterThanOrEqualTo(2.0));
    });

    test('derives from the post-fallback ceiling', () {
      // The bug: the axis rendered at the fallback 10 while the interval was
      // computed from the raw 0 and clamped up to 5.
      final axisMax = niceAxisMax(0, fallback: 10);
      expect(niceInterval(axisMax), 2.5);
    });

    test('picks round steps for typical marathon volumes', () {
      expect(niceInterval(niceAxisMax(60, fallback: 10)), 20);
      expect(niceInterval(niceAxisMax(100, fallback: 10)), 50);
    });
  });

  group('contiguousSegments', () {
    test('splits at gaps', () {
      expect(contiguousSegments([true, true, false, true]), [
        [0, 1],
        [3, 3],
      ]);
    });

    test('handles leading and trailing gaps', () {
      expect(contiguousSegments([false, true, true, false]), [
        [1, 2],
      ]);
    });

    test('returns a single run when nothing is missing', () {
      expect(contiguousSegments([true, true, true]), [
        [0, 2],
      ]);
    });

    test('returns nothing when everything is missing', () {
      expect(contiguousSegments([false, false]), isEmpty);
      expect(contiguousSegments([]), isEmpty);
    });
  });
}
