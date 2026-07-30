import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/domain/progress/plan_phase.dart';

void main() {
  group('phaseForWeek — 16-week plan, 3 taper weeks', () {
    // base 1-5, build 6-10, peak 11-13, taper 14-16.
    PlanPhase phase(int week) =>
        phaseForWeek(week, totalWeeks: 16, taperWeeks: 3);

    test('base covers the first 40%', () {
      for (var w = 1; w <= 5; w++) {
        expect(phase(w), PlanPhase.base, reason: 'week $w');
      }
    });

    test('build covers the next 40%', () {
      for (var w = 6; w <= 10; w++) {
        expect(phase(w), PlanPhase.build, reason: 'week $w');
      }
    });

    test('peak is the remainder before the taper', () {
      for (var w = 11; w <= 13; w++) {
        expect(phase(w), PlanPhase.peak, reason: 'week $w');
      }
    });

    test('taper is the final 3 weeks', () {
      for (var w = 14; w <= 16; w++) {
        expect(phase(w), PlanPhase.taper, reason: 'week $w');
      }
    });

    test('every week of the plan is assigned exactly once', () {
      final phases = [for (var w = 1; w <= 16; w++) phase(w)];
      expect(
        phases,
        [
          ...List.filled(5, PlanPhase.base),
          ...List.filled(5, PlanPhase.build),
          ...List.filled(3, PlanPhase.peak),
          ...List.filled(3, PlanPhase.taper),
        ],
      );
    });
  });

  group('degenerate plans clamp instead of throwing', () {
    test('a 1-week plan is entirely taper', () {
      expect(phaseForWeek(1, totalWeeks: 1, taperWeeks: 3), PlanPhase.taper);
    });

    test('taperWeeks >= totalWeeks makes every week taper', () {
      for (var w = 1; w <= 3; w++) {
        expect(
          phaseForWeek(w, totalWeeks: 3, taperWeeks: 5),
          PlanPhase.taper,
          reason: 'week $w',
        );
      }
    });

    test('an out-of-range week clamps rather than throwing', () {
      expect(() => phaseForWeek(0, totalWeeks: 16, taperWeeks: 3), returnsNormally);
      expect(() => phaseForWeek(99, totalWeeks: 16, taperWeeks: 3), returnsNormally);
      // Clamps to week 1 (base) and week 16 (taper) respectively.
      expect(phaseForWeek(0, totalWeeks: 16, taperWeeks: 3), PlanPhase.base);
      expect(phaseForWeek(99, totalWeeks: 16, taperWeeks: 3), PlanPhase.taper);
    });

    test('minimum plan (6 weeks, 3 taper): one base, one build, one peak', () {
      expect(phaseForWeek(1, totalWeeks: 6, taperWeeks: 3), PlanPhase.base);
      expect(phaseForWeek(2, totalWeeks: 6, taperWeeks: 3), PlanPhase.build);
      expect(phaseForWeek(3, totalWeeks: 6, taperWeeks: 3), PlanPhase.peak);
      expect(phaseForWeek(4, totalWeeks: 6, taperWeeks: 3), PlanPhase.taper);
      expect(phaseForWeek(6, totalWeeks: 6, taperWeeks: 3), PlanPhase.taper);
    });
  });

  test('PlanPhase labels', () {
    expect(PlanPhase.base.label, 'Base');
    expect(PlanPhase.build.label, 'Build');
    expect(PlanPhase.peak.label, 'Peak');
    expect(PlanPhase.taper.label, 'Taper');
  });
}
