import 'dart:math' as math;

import '../../core/date_utils.dart';
import '../models/enums.dart';
import '../models/planned_run.dart';
import '../models/training_plan.dart';
import '../models/workout_segment.dart';
import '../paces/pace_calculator.dart';
import 'plan_input.dart';

/// Result of generating a plan: the plan plus its planned runs. Ids are
/// placeholders (the repository assigns real ones on insert).
class GeneratedPlan {
  const GeneratedPlan({required this.plan, required this.runs});
  final TrainingPlan plan;
  final List<PlannedRun> runs;
}

/// Builds a structured marathon plan from user inputs (spec §5).
///
/// **Pure** — no Flutter/IO. The race date is the anchor: the final week is race
/// week, the taper re-anchors to race day, and changing the race date reflows
/// the whole calendar. The canonical 19-week marathon plan uses the spec's seed
/// long-run ladder; other lengths are generated parametrically (3 build weeks →
/// 1 cutback, ~2km/week increase, peak then taper).
class PlanGenerator {
  const PlanGenerator();

  /// The spec §5 default seed long-run ladder for the build phase
  /// (weeks 1..15) of a canonical 19-week plan, in km. Index 0 == week 1.
  static const List<double> _seedBuildLadder = [
    14, 16, 19, 14, 21, 23, 18, 25, 27, 20, 28, 30, 22, 31, 32,
  ];

  /// The spec §5 taper long-run ladder (weeks 16..18) of the canonical plan.
  static const List<double> _seedTaperLadder = [24, 19, 13];

  GeneratedPlan generate(PlanInput input) {
    final taperWeeks = math.max(1, input.taperWeeks);
    final totalWeeks = math.max(taperWeeks + 3, input.planWeeks);
    final buildWeeks = totalWeeks - taperWeeks - 1; // weeks 1..buildWeeks
    final raceWeek = totalWeeks;

    // Training paces (VDOT) when the athlete supplied a goal time.
    final paces = input.goalFinishSec == null
        ? null
        : const PaceCalculator().fromGoalTime(
            raceDistanceKm: input.raceDistanceKm,
            goalSec: input.goalFinishSec!,
          );

    final startLongRunKm = _resolveStartLongRun(input);
    final ladder = _buildLongRunLadder(
      totalWeeks: totalWeeks,
      buildWeeks: buildWeeks,
      taperWeeks: taperWeeks,
      peak: input.peakLongRunKm,
      startLongRunKm: startLongRunKm,
    );

    // Anchor weeks to the race. Race week's Monday is derived from race day; each
    // earlier week is a 7-day block back from it, so the taper re-anchors to race.
    final raceWeekMonday = previousOrSameWeekday(input.raceDate, DateTime.monday);
    final startDate = addDays(raceWeekMonday, -(totalWeeks - 1) * 7);

    final plan = TrainingPlan(
      id: 0,
      name: input.planName ?? _defaultName(input.raceDate),
      raceDate: dateOnly(input.raceDate),
      raceDistanceKm: input.raceDistanceKm,
      startDate: startDate,
      longRunDay: input.preferredLongRunDay,
      status: PlanStatus.active,
      createdAt: DateTime.now(),
      taperWeeks: taperWeeks,
    );

    final runs = <PlannedRun>[];
    for (var week = 1; week <= totalWeeks; week++) {
      final weekMonday = addDays(raceWeekMonday, -(totalWeeks - week) * 7);
      runs.addAll(_buildWeek(
        input: input,
        week: week,
        weekMonday: weekMonday,
        raceWeek: raceWeek,
        buildWeeks: buildWeeks,
        longRunKm: ladder[week - 1],
        paces: paces,
      ));
    }

    // Sort by date and assign sequential placeholder ids.
    runs.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final withIds = <PlannedRun>[];
    for (var i = 0; i < runs.length; i++) {
      withIds.add(runs[i].copyWith(id: i + 1));
    }
    return GeneratedPlan(plan: plan, runs: withIds);
  }

  String _defaultName(DateTime raceDate) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Marathon — ${months[raceDate.month - 1]} ${raceDate.year}';
  }

  /// startLongRunKm ≈ 0.55 × raceDistance, clamped to ≥ currentLongest − 4 (spec §5).
  double _resolveStartLongRun(PlanInput input) {
    final base = 0.55 * input.raceDistanceKm;
    final floor = input.currentLongestRunKm - 4;
    return math.max(base, floor).clamp(8.0, input.peakLongRunKm);
  }

  /// Builds the per-week long-run distances. Uses the spec seed for the canonical
  /// 19-week/3-taper plan; otherwise generates a 3-build→1-cutback ladder.
  List<double> _buildLongRunLadder({
    required int totalWeeks,
    required int buildWeeks,
    required int taperWeeks,
    required double peak,
    required double startLongRunKm,
  }) {
    final isCanonical = totalWeeks == 19 && taperWeeks == 3 && peak == 32;
    if (isCanonical) {
      return [..._seedBuildLadder, ..._seedTaperLadder, 42.2];
    }

    final ladder = <double>[];

    // Build phase: rise ~2km per build week, every 4th week a cutback (~0.7×),
    // ending at the peak on the final build week.
    var current = startLongRunKm;
    var lastBuildValue = startLongRunKm;
    for (var w = 1; w <= buildWeeks; w++) {
      final isPeakWeek = w == buildWeeks;
      final isCutback = (w % 4 == 0) && !isPeakWeek;
      if (isPeakWeek) {
        current = peak;
      } else if (isCutback) {
        current = (lastBuildValue * 0.7).roundToDouble();
      } else {
        current = math.min(lastBuildValue + 2, peak);
        lastBuildValue = current;
      }
      ladder.add(current);
    }
    if (ladder.isEmpty) ladder.add(peak);

    // Taper weeks: descend from ~0.75×peak toward race.
    for (var t = 0; t < taperWeeks; t++) {
      final factor = 0.75 - (t * (0.45 / math.max(1, taperWeeks)));
      ladder.add((peak * factor).roundToDouble());
    }

    // Race week.
    ladder.add(42.2);
    return ladder;
  }

  /// Builds the sessions for one training week.
  List<PlannedRun> _buildWeek({
    required PlanInput input,
    required int week,
    required DateTime weekMonday,
    required int raceWeek,
    required int buildWeeks,
    required double longRunKm,
    TrainingPaces? paces,
  }) {
    final runs = <PlannedRun>[];
    final longDay = input.preferredLongRunDay;

    // Long runs are run easy→moderate (between easy and marathon pace).
    final longPace = paces == null ? null : (paces.easy + paces.marathon) / 2;

    if (week == raceWeek) {
      // Race week: a short shakeout easy, then the race itself on race day.
      final raceDate = dateOnly(input.raceDate);
      final shakeoutDay = _weekdayInWeek(weekMonday, _shiftWeekday(longDay, -3));
      if (shakeoutDay.isBefore(raceDate)) {
        runs.add(_run(
          planId: 0,
          date: shakeoutDay,
          week: week,
          type: RunType.easy,
          distanceKm: 5,
          ratio: input.currentLongestRunKm < 20 ? '4:1' : null,
          paceSecPerKm: paces?.easy,
        ));
      }
      runs.add(_run(
        planId: 0,
        date: raceDate,
        week: week,
        type: RunType.long,
        distanceKm: input.raceDistanceKm,
        notes: 'Race day 🏁',
        paceSecPerKm: paces?.race,
      ));
      return runs;
    }

    final isTaper = week > buildWeeks;
    final buildProgress = buildWeeks <= 1 ? 1.0 : (week - 1) / (buildWeeks - 1);

    // Long run on the preferred day.
    runs.add(_run(
      planId: 0,
      date: _weekdayInWeek(weekMonday, longDay),
      week: week,
      type: RunType.long,
      distanceKm: longRunKm,
      ratio: input.currentLongestRunKm < 20 ? '4:1' : null,
      paceSecPerKm: longPace,
    ));

    // Steady (medium) midweek run — scales 8 → 16 over the build, eases in taper.
    final steadyKm = isTaper
        ? (12 - (week - buildWeeks) * 2).clamp(6, 12).toDouble()
        : (8 + buildProgress * 8).roundToDouble();
    // On build weeks, make it a structured quality session when paces are known.
    final structured = (paces != null && !isTaper && week >= 3)
        ? _qualitySession(week, steadyKm, paces)
        : null;
    runs.add(_run(
      planId: 0,
      date: _weekdayInWeek(weekMonday, _shiftWeekday(longDay, -3)),
      week: week,
      type: RunType.steady,
      distanceKm: steadyKm,
      // Average target pace ≈ marathon/threshold; segments carry the detail.
      paceSecPerKm: paces?.marathon,
      segments: structured,
    ));

    // Easy/recovery run(s) ~5–7km, slightly shorter in taper.
    final easyDays = math.max(1, input.daysPerWeek - 2);
    final easyOffsets = _easyOffsets(longDay, easyDays);
    for (final off in easyOffsets) {
      runs.add(_run(
        planId: 0,
        date: _weekdayInWeek(weekMonday, off),
        week: week,
        type: RunType.easy,
        distanceKm: isTaper ? 5 : 6,
        paceSecPerKm: paces?.easy,
      ));
    }

    return runs;
  }

  /// Builds a structured quality session (alternating tempo & intervals by week)
  /// whose blocks roughly sum to [totalKm]. Pure.
  List<WorkoutSegment> _qualitySession(
      int week, double totalKm, TrainingPaces paces) {
    const warmupKm = 2.0;
    const cooldownKm = 1.0;
    final workKm = math.max(2.0, totalKm - warmupKm - cooldownKm);

    if (week.isEven) {
      // Tempo: continuous threshold block.
      return [
        WorkoutSegment(
            kind: SegmentKind.warmup,
            distanceKm: warmupKm,
            targetPaceSecPerKm: paces.easy,
            label: 'Warm-up'),
        WorkoutSegment(
            kind: SegmentKind.tempo,
            distanceKm: double.parse(workKm.toStringAsFixed(1)),
            targetPaceSecPerKm: paces.threshold,
            label: 'Tempo @ threshold'),
        WorkoutSegment(
            kind: SegmentKind.cooldown,
            distanceKm: cooldownKm,
            targetPaceSecPerKm: paces.easy,
            label: 'Cool-down'),
      ];
    }

    // Intervals: N × (800 m hard / 400 m recovery) to roughly fill workKm.
    final reps = math.max(3, (workKm / 1.2).round());
    return [
      WorkoutSegment(
          kind: SegmentKind.warmup,
          distanceKm: warmupKm,
          targetPaceSecPerKm: paces.easy,
          label: 'Warm-up'),
      WorkoutSegment(
          kind: SegmentKind.hard,
          reps: reps,
          distanceKm: 0.8,
          targetPaceSecPerKm: paces.interval,
          label: '$reps × 800 m @ interval'),
      WorkoutSegment(
          kind: SegmentKind.recovery,
          reps: reps,
          distanceKm: 0.4,
          targetPaceSecPerKm: paces.easy,
          label: '400 m jog recovery'),
      WorkoutSegment(
          kind: SegmentKind.cooldown,
          distanceKm: cooldownKm,
          targetPaceSecPerKm: paces.easy,
          label: 'Cool-down'),
    ];
  }

  /// Weekdays (Mon=1…Sun=7) for the easy run(s), avoiding adjacency to the long
  /// run and the steady run so the min-rest rule holds.
  List<int> _easyOffsets(int longDay, int count) {
    // Preferred easy slots relative to the long day: 5 and 1 days earlier.
    final candidates = <int>[
      _shiftWeekday(longDay, -5),
      _shiftWeekday(longDay, -1),
      _shiftWeekday(longDay, -2),
    ];
    final steadyDay = _shiftWeekday(longDay, -3);
    final result = <int>[];
    for (final c in candidates) {
      if (result.length >= count) break;
      if (c == longDay || c == steadyDay) continue;
      if (_isAdjacent(c, longDay)) continue;
      result.add(c);
    }
    // Fallback: fill remaining from any non-conflicting weekday.
    for (var d = 1; d <= 7 && result.length < count; d++) {
      if (d == longDay || d == steadyDay || result.contains(d)) continue;
      if (_isAdjacent(d, longDay)) continue;
      result.add(d);
    }
    return result;
  }

  bool _isAdjacent(int a, int b) {
    final diff = (a - b).abs();
    return diff == 1 || diff == 6; // 6 covers Sun(7)↔Sat(6) handled by abs; keep simple
  }

  /// Shifts an ISO weekday by [delta] days, wrapping into 1..7.
  int _shiftWeekday(int weekday, int delta) {
    var d = (weekday - 1 + delta) % 7;
    if (d < 0) d += 7;
    return d + 1;
  }

  /// The date of [weekday] (Mon=1…Sun=7) within the week beginning [weekMonday].
  DateTime _weekdayInWeek(DateTime weekMonday, int weekday) =>
      addDays(weekMonday, weekday - DateTime.monday);

  PlannedRun _run({
    required int planId,
    required DateTime date,
    required int week,
    required RunType type,
    double? distanceKm,
    String? ratio,
    String? notes,
    double? paceSecPerKm,
    List<WorkoutSegment>? segments,
  }) {
    final d = dateOnly(date);
    return PlannedRun(
      id: 0,
      planId: planId,
      scheduledDate: d,
      originalDate: d,
      weekIndex: week,
      type: type,
      targetDistanceKm: distanceKm,
      runWalkRatio: ratio,
      targetPaceSecPerKm: paceSecPerKm,
      segments: segments,
      status: RunStatus.pending,
      notes: notes,
    );
  }
}
