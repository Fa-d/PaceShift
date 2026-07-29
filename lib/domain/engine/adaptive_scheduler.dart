import 'dart:math' as math;

import '../../core/date_utils.dart';
import '../models/enums.dart';
import '../models/planned_run.dart';
import 'reschedule_outcome.dart';
import 'schedule_snapshot.dart';

/// The adaptive scheduling engine (spec §4) — the heart of PaceShift.
///
/// **Pure**: no Flutter/IO. It reads a [ScheduleSnapshot] and returns a
/// [RescheduleOutcome] describing the new state plus a changelog. The race date
/// is protected; missed load is redistributed only within the hard safety
/// guardrails, and when that is impossible the engine returns degrade options
/// rather than building unsafe weeks.
class AdaptiveScheduler {
  const AdaptiveScheduler();

  /// Roll the plan forward to [snapshot.today]: mark every still-pending run in
  /// the past as missed and redistribute it within the guardrails.
  RescheduleOutcome onDayRollover(ScheduleSnapshot snapshot) {
    final engine = _Engine(snapshot);
    final stale = snapshot.plannedRuns
        .where((r) =>
            r.status == RunStatus.pending &&
            r.scheduledDate.isBefore(snapshot.today))
        .toList()
      ..sort(_byPriorityThenDate);
    for (final run in stale) {
      engine.handleMissed(run.id, searchFrom: snapshot.today);
    }
    return engine.build();
  }

  /// The user reported they couldn't run [runId] today. Mark it missed and make
  /// it up from tomorrow onward.
  RescheduleOutcome reportCouldNotRun(ScheduleSnapshot snapshot, int runId) {
    final engine = _Engine(snapshot);
    engine.handleMissed(runId, searchFrom: addDays(snapshot.today, 1));
    return engine.build();
  }

  /// Apply the athlete's answer to a §4.6 degrade decision.
  ///
  /// The engine surfaces [DegradeOption]s when there is no safe way to fit a
  /// long run, and deliberately never chooses for the athlete. This is the
  /// other half of that conversation: it carries out the choice they made,
  /// still entirely within the guardrails, and then retries the long run that
  /// forced the question.
  ///
  /// The returned outcome never carries new [DegradeOption]s. The athlete has
  /// already answered; re-asking the same question because their answer wasn't
  /// enough would be a loop, not a conversation.
  RescheduleOutcome applyDegradeDecision(
      ScheduleSnapshot snapshot, DegradeKind kind) {
    final engine = _Engine(snapshot)..suppressDecisions();
    engine.applyDegrade(kind);
    return engine.build();
  }

  /// The choices offered when no safe redistribution exists (spec §4.6).
  ///
  /// Fixed rather than computed, so an outstanding decision can be restored
  /// from a single stored flag instead of a serialised option list.
  static const List<DegradeOption> degradeOptions = [
    DegradeOption(
      kind: DegradeKind.reducePeak,
      title: 'Reduce the peak',
      description:
          'Lower the remaining long-run targets so the rest of the plan '
          'fits safely into the time left.',
    ),
    DegradeOption(
      kind: DegradeKind.dropLowValue,
      title: 'Drop easy sessions',
      description:
          'Shed easy and strength sessions to make room for the long run.',
    ),
    DegradeOption(
      kind: DegradeKind.acceptRisk,
      title: 'Accept readiness risk',
      description:
          'Keep the plan as-is and accept that race readiness will be '
          'below target.',
    ),
  ];

  static int _byPriorityThenDate(PlannedRun a, PlannedRun b) {
    final p = a.priority.index.compareTo(b.priority.index); // high=0 first
    if (p != 0) return p;
    return a.scheduledDate.compareTo(b.scheduledDate);
  }
}

/// Mutable working state for a single engine pass.
class _Engine {
  _Engine(this.s) {
    for (final r in s.plannedRuns) {
      _runs[r.id] = r;
    }
    _ceilingFactor = switch (s.settings.adaptivityAggressiveness) {
      Aggressiveness.conservative => 1.10,
      Aggressiveness.balanced => 1.15,
      Aggressiveness.aggressive => 1.20,
    };
    _jumpFactor = _ceilingFactor;
    final maxOriginal = _allOriginalWeeks()
        .map(_originalWeekTarget)
        .fold<double>(0, math.max);
    _safeCeiling = maxOriginal * 1.25;
  }

  final ScheduleSnapshot s;
  final Map<int, PlannedRun> _runs = {};
  final List<RunChange> _changes = [];
  final List<DegradeOption> _decisions = [];
  bool _suppressDecisions = false;

  /// Stop this pass raising degrade options — used when we are already acting
  /// on the athlete's answer to one.
  void suppressDecisions() => _suppressDecisions = true;

  late final double _ceilingFactor;
  late final double _jumpFactor;
  late final double _safeCeiling;

  static const double _mediumReduceFloor = 0.6;
  static const double _longReduceFloor = 0.5;

  RescheduleOutcome build() => RescheduleOutcome(
        runs: _runs.values.toList()
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate)),
        changes: List.unmodifiable(_changes),
        decisions: List.unmodifiable(_decisions),
      );

  // ---- Missed-run handling ----------------------------------------------

  void handleMissed(int runId, {required DateTime searchFrom}) {
    final run = _runs[runId];
    if (run == null || run.status == RunStatus.completed) return;

    // Rule 4: missed taper runs are dropped, never redistributed forward.
    if (s.isTaperDate(run.scheduledDate) || s.isTaperWeek(run.weekIndex)) {
      _drop(run, 'Taper is protected — this run is set aside.');
      return;
    }

    // Catch-up window expiry (rule 6).
    final window = run.type == RunType.long
        ? s.settings.longRunCatchupWindowDays
        : s.settings.catchupWindowDays;
    final latest = addDays(run.originalDate, window);
    if (s.today.isAfter(latest)) {
      _expire(run);
      return;
    }

    switch (run.priority) {
      case RunPriority.low:
        _rescheduleLow(run, searchFrom, latest);
      case RunPriority.medium:
        _rescheduleMedium(run, searchFrom, latest);
      case RunPriority.high:
        _rescheduleHigh(run, searchFrom, latest);
      case RunPriority.flexible:
        _drop(run, 'Optional session skipped.');
    }
  }

  void _rescheduleLow(PlannedRun run, DateTime from, DateTime latest) {
    final slot = _findFreeSlot(run, from, latest, run.loadKm);
    if (slot != null) {
      _move(run, slot, run.targetDistanceKm);
    } else {
      _drop(run, 'No safe slot — easy run dropped to protect recovery.');
    }
  }

  void _rescheduleMedium(PlannedRun run, DateTime from, DateTime latest) {
    final slot = _findFreeSlot(run, from, latest, run.loadKm);
    if (slot != null) {
      _move(run, slot, run.targetDistanceKm);
      return;
    }
    // Try a reduced version in the best partial slot.
    final partial = _findPartialSlot(run, from, latest);
    if (partial != null && partial.fitKm >= _mediumReduceFloor * run.loadKm) {
      _move(run, partial.date, partial.fitKm);
    } else {
      _drop(run, 'Couldn’t fit safely — steady run dropped this time.');
    }
  }

  void _rescheduleHigh(PlannedRun run, DateTime from, DateTime latest) {
    final slot = _findLongRunSlot(run, from, latest);
    if (slot == null) {
      _degradePlan(run);
      return;
    }
    final fit = _maxDistanceThatFits(s.weekOf(slot.date), run.loadKm, ignore: run.id);
    if (fit < _longReduceFloor * run.loadKm) {
      _degradePlan(run);
      return;
    }
    // Displace any low-priority run already sitting on the chosen day.
    final occupant = _activeRunOn(slot.date);
    if (occupant != null && occupant.priority == RunPriority.low) {
      _drop(occupant, 'Made room for your long run.');
    }
    final distance = math.min(run.loadKm, fit);
    _move(run, slot.date, distance);
    if (slot.partnerLongRunId != null && distance < run.loadKm) {
      _changes.add(LongRunRebalancedChange(
        _runs[run.id]!,
        partnerRunId: slot.partnerLongRunId!,
      ));
    }
  }

  // ---- Degrade decisions (spec §4.6) -------------------------------------

  void applyDegrade(DegradeKind kind) {
    switch (kind) {
      case DegradeKind.reducePeak:
        _reducePeak();
        _retryDegradedLongRuns();
      case DegradeKind.dropLowValue:
        _dropLowValue();
        _retryDegradedLongRuns();
      case DegradeKind.acceptRisk:
        // Nothing moves. The athlete has chosen to carry the risk rather than
        // shrink the plan, and saying so out loud is the whole point of the
        // option — the caller records that the question is answered.
        break;
    }
  }

  /// Long runs the engine gave up on and that could still be made up.
  List<PlannedRun> _degradedLongRuns() {
    final out = <PlannedRun>[];
    for (final r in _runs.values) {
      if (r.type != RunType.long || r.status != RunStatus.missed) continue;
      final latest = addDays(r.originalDate, s.settings.longRunCatchupWindowDays);
      if (s.today.isAfter(latest)) continue;
      out.add(r);
    }
    out.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return out;
  }

  /// "Reduce the peak": cap the remaining long runs at what the athlete has
  /// actually demonstrated, grown one jump at a time.
  ///
  /// This is progressive overload run backwards — rather than asking for the
  /// distance the original plan assumed they'd have built to by now, it asks
  /// for the next honest step up from their longest completed run. The floor
  /// stops it collapsing a long run into a token effort.
  void _reducePeak() {
    final longs = _runs.values
        .where((r) =>
            r.type == RunType.long &&
            _isActive(r.status) &&
            !r.scheduledDate.isBefore(s.today) &&
            !s.isTaperDate(r.scheduledDate))
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    if (longs.isEmpty) return;

    final demonstrated = s.completedRuns
        .fold<double>(0, (m, c) => math.max(m, c.actualDistanceKm));
    if (demonstrated <= 0) return;

    var cap = demonstrated * _jumpFactor;
    for (final run in longs) {
      final target = run.targetDistanceKm;
      if (target == null) continue;
      if (target > cap) {
        _reduce(run, math.max(cap, _longReduceFloor * target));
      }
      cap = math.max(cap, _runs[run.id]!.targetDistanceKm ?? 0) * _jumpFactor;
    }
  }

  /// "Drop easy sessions": clear low-value work out of the window the long run
  /// still has to land in — not the whole rest of the plan.
  void _dropLowValue() {
    for (final missed in _degradedLongRuns()) {
      final latest =
          addDays(missed.originalDate, s.settings.longRunCatchupWindowDays);
      for (final run in _runs.values.toList()) {
        if (run.id == missed.id) continue;
        if (!_isActive(run.status)) continue;
        if (run.scheduledDate.isBefore(s.today)) continue;
        if (run.scheduledDate.isAfter(latest)) continue;
        if (s.isTaperDate(run.scheduledDate)) continue;
        if (run.priority == RunPriority.low ||
            run.priority == RunPriority.flexible) {
          _drop(run, 'Set aside to make room for your long run.');
        }
      }
    }
  }

  /// Having freed capacity, try once more to place the long runs that forced
  /// the decision. If they still don't fit they stay missed — but silently,
  /// because the athlete has already been asked.
  void _retryDegradedLongRuns() {
    for (final run in _degradedLongRuns()) {
      handleMissed(run.id, searchFrom: addDays(s.today, 1));
    }
  }

  // ---- Slot finding ------------------------------------------------------

  DateTime? _findFreeSlot(
      PlannedRun run, DateTime from, DateTime latest, double loadKm) {
    for (var d = dateOnly(from);
        !d.isAfter(latest);
        d = addDays(d, 1)) {
      if (!_canPlace(d, run.type, ignoreRunId: run.id)) continue;
      if (_maxDistanceThatFits(s.weekOf(d), loadKm, ignore: run.id) >= loadKm) {
        return d;
      }
    }
    return null;
  }

  _PartialSlot? _findPartialSlot(
      PlannedRun run, DateTime from, DateTime latest) {
    _PartialSlot? best;
    for (var d = dateOnly(from); !d.isAfter(latest); d = addDays(d, 1)) {
      if (!_canPlace(d, run.type, ignoreRunId: run.id)) continue;
      final fit = _maxDistanceThatFits(s.weekOf(d), run.loadKm, ignore: run.id);
      if (fit <= 0) continue;
      if (best == null || fit > best.fitKm) {
        best = _PartialSlot(d, fit);
      }
    }
    return best;
  }

  _LongSlot? _findLongRunSlot(PlannedRun run, DateTime from, DateTime latest) {
    final preferDay = s.plan.longRunDay;
    final floor = _longReduceFloor * run.loadKm;
    final candidates = <DateTime>[];
    for (var d = dateOnly(from); !d.isAfter(latest); d = addDays(d, 1)) {
      if (!_canPlaceLong(d, ignoreRunId: run.id)) continue;
      // The week must have room for at least a reduced long run.
      if (_maxDistanceThatFits(s.weekOf(d), run.loadKm, ignore: run.id) < floor) {
        continue;
      }
      candidates.add(d);
    }
    if (candidates.isEmpty) return null;

    // Prefer: matches preferred long-run day, then a week without an existing
    // long run, then the earliest date.
    candidates.sort((a, b) {
      final ap = a.weekday == preferDay ? 0 : 1;
      final bp = b.weekday == preferDay ? 0 : 1;
      if (ap != bp) return ap.compareTo(bp);
      final aFree = _weekHasOtherLongRun(s.weekOf(a), run.id) ? 1 : 0;
      final bFree = _weekHasOtherLongRun(s.weekOf(b), run.id) ? 1 : 0;
      if (aFree != bFree) return aFree.compareTo(bFree);
      return a.compareTo(b);
    });
    final chosen = candidates.first;
    final partner = _otherLongRunIdInWeek(s.weekOf(chosen), run.id);
    return _LongSlot(chosen, partnerLongRunId: partner);
  }

  // ---- Placement rules (occupancy, rest, taper, race) --------------------

  bool _canPlace(DateTime date, RunType type, {required int ignoreRunId}) {
    if (!date.isBefore(s.plan.raceDate)) return false; // never on/after race
    if (s.isTaperDate(date)) return false; // never redistribute into taper
    if (_activeRunOn(date, ignore: ignoreRunId) != null) return false;
    // Never place a run the day immediately before a long run.
    if (_hasLongRunOn(addDays(date, 1), ignore: ignoreRunId)) return false;
    if (type.isHard) {
      if (_hasHardRunOn(addDays(date, -1), ignore: ignoreRunId)) return false;
      if (_hasHardRunOn(addDays(date, 1), ignore: ignoreRunId)) return false;
    }
    return true;
  }

  bool _canPlaceLong(DateTime date, {required int ignoreRunId}) {
    if (!date.isBefore(s.plan.raceDate)) return false;
    if (s.isTaperDate(date)) return false;
    // The chosen day must be free or hold only a displaceable low-priority run.
    final occupant = _activeRunOn(date, ignore: ignoreRunId);
    if (occupant != null && occupant.priority != RunPriority.low) return false;
    // A long run is never the day after another run.
    if (_activeRunOn(addDays(date, -1), ignore: ignoreRunId) != null) {
      return false;
    }
    // No hard run the day after either.
    if (_hasHardRunOn(addDays(date, 1), ignore: ignoreRunId)) return false;
    return true;
  }

  // ---- Weekly-load maths (enforces rules 2 & 3 by construction) ----------

  /// The largest additional load that can be added to [week] without breaching
  /// the weekly ceiling or the week-over-week jump rule. The in-flight run
  /// ([ignore]) is excluded so moving a run within its own week is allowed.
  double _maxDistanceThatFits(int week, double desired, {int? ignore}) {
    final current = _currentWeekLoad(week, ignore: ignore);
    final ceiling =
        math.min(_originalWeekTarget(week) * _ceilingFactor, _safeCeiling);
    var allowed = ceiling - current;
    if (week > 1) {
      final prev = _currentWeekLoad(week - 1, ignore: ignore);
      if (prev > 0) {
        allowed = math.min(allowed, prev * _jumpFactor - current);
      }
    }
    if (allowed <= 0) return 0;
    return math.min(desired, allowed);
  }

  double _currentWeekLoad(int week, {int? ignore}) {
    var total = 0.0;
    for (final r in _runs.values) {
      if (ignore != null && r.id == ignore) continue;
      if (!_isActive(r.status)) continue;
      if (s.weekOf(r.scheduledDate) == week) total += r.loadKm;
    }
    return total;
  }

  double _originalWeekTarget(int week) {
    var total = 0.0;
    for (final r in s.plannedRuns) {
      if (s.weekOf(r.originalDate) == week) {
        total += r.type.isRun ? (r.targetDistanceKm ?? 0) : 0;
      }
    }
    return total;
  }

  Iterable<int> _allOriginalWeeks() =>
      s.plannedRuns.map((r) => s.weekOf(r.originalDate)).toSet();

  // ---- Mutations ---------------------------------------------------------

  void _move(PlannedRun run, DateTime to, double? distanceKm) {
    final from = run.scheduledDate;
    final newRun = run.copyWith(
      scheduledDate: dateOnly(to),
      weekIndex: s.weekOf(to),
      status: RunStatus.shifted,
      targetDistanceKm: distanceKm,
    );
    _runs[run.id] = newRun;
    _changes.add(RunMovedChange(newRun, from: from, to: dateOnly(to)));
    if (distanceKm != null &&
        run.targetDistanceKm != null &&
        distanceKm < run.targetDistanceKm!) {
      _changes.add(RunReducedChange(newRun,
          fromKm: run.targetDistanceKm!, toKm: distanceKm));
    }
  }

  /// Shorten a run where it stands (no move).
  void _reduce(PlannedRun run, double toKm) {
    final from = run.targetDistanceKm;
    if (from == null || toKm >= from) return;
    final newRun = run.copyWith(targetDistanceKm: toKm);
    _runs[run.id] = newRun;
    _changes.add(RunReducedChange(newRun, fromKm: from, toKm: toKm));
  }

  void _drop(PlannedRun run, String reason) {
    final newRun = run.copyWith(status: RunStatus.dropped);
    _runs[run.id] = newRun;
    _changes.add(RunDroppedChange(newRun, reason: reason));
  }

  void _expire(PlannedRun run) {
    final newRun = run.copyWith(status: RunStatus.missed);
    _runs[run.id] = newRun;
    _changes.add(RunExpiredChange(newRun));
  }

  void _degradePlan(PlannedRun run) {
    // Leave the long run marked missed; surface the choice (spec §4.6).
    _runs[run.id] = run.copyWith(status: RunStatus.missed);
    if (_suppressDecisions) return;
    if (_decisions.isEmpty) {
      _decisions.addAll(AdaptiveScheduler.degradeOptions);
    }
  }

  // ---- Queries -----------------------------------------------------------

  bool _isActive(RunStatus st) =>
      st == RunStatus.pending ||
      st == RunStatus.shifted ||
      st == RunStatus.completed;

  PlannedRun? _activeRunOn(DateTime date, {int? ignore}) {
    for (final r in _runs.values) {
      if (ignore != null && r.id == ignore) continue;
      if (!_isActive(r.status)) continue;
      if (isSameDate(r.scheduledDate, date)) return r;
    }
    return null;
  }

  bool _hasHardRunOn(DateTime date, {int? ignore}) {
    for (final r in _runs.values) {
      if (ignore != null && r.id == ignore) continue;
      if (!_isActive(r.status)) continue;
      if (r.type.isHard && isSameDate(r.scheduledDate, date)) return true;
    }
    return false;
  }

  bool _hasLongRunOn(DateTime date, {int? ignore}) {
    for (final r in _runs.values) {
      if (ignore != null && r.id == ignore) continue;
      if (!_isActive(r.status)) continue;
      if (r.type == RunType.long && isSameDate(r.scheduledDate, date)) {
        return true;
      }
    }
    return false;
  }

  bool _weekHasOtherLongRun(int week, int ignoreId) =>
      _otherLongRunIdInWeek(week, ignoreId) != null;

  int? _otherLongRunIdInWeek(int week, int ignoreId) {
    for (final r in _runs.values) {
      if (r.id == ignoreId) continue;
      if (!_isActive(r.status)) continue;
      if (r.type == RunType.long && s.weekOf(r.scheduledDate) == week) {
        return r.id;
      }
    }
    return null;
  }
}

class _PartialSlot {
  _PartialSlot(this.date, this.fitKm);
  final DateTime date;
  final double fitKm;
}

class _LongSlot {
  _LongSlot(this.date, {this.partnerLongRunId});
  final DateTime date;
  final int? partnerLongRunId;
}
