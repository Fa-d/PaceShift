/// Decides which planned run — if any — a synced workout satisfies.
///
/// **PURE** — no Flutter, no IO, no Drift, same contract as `domain/engine`.
/// The repository gathers candidates and persists the result; everything
/// judgemental happens here so it can be exhaustively unit-tested.
library;

import '../../core/date_utils.dart';
import '../models/enums.dart';
import '../models/planned_run.dart';

/// How sure we are that a workout belongs to a planned run.
enum MatchConfidence {
  /// Same day, plausible distance — attach without asking.
  exact,

  /// A day either side, plausible distance, nothing better on the day itself —
  /// attach without asking. Covers the Saturday-night "Sunday" long run and
  /// workouts whose timestamps land past midnight.
  likely,

  /// Something is there, but it's a stretch (distance well off target, or two
  /// equally good candidates). Ask the user rather than guess.
  ambiguous,

  /// Nothing plausible — record it as an extra run.
  none,
}

/// The outcome of matching one workout.
class WorkoutMatch {
  const WorkoutMatch(this.plannedRunId, this.confidence);

  const WorkoutMatch.none() : plannedRunId = null, confidence = MatchConfidence.none;

  /// The planned run involved. For [MatchConfidence.ambiguous] this is a
  /// *suggestion* to confirm, not an attachment.
  final int? plannedRunId;
  final MatchConfidence confidence;

  /// Whether the caller should link the workout to [plannedRunId] outright.
  bool get isAutomatic =>
      confidence == MatchConfidence.exact || confidence == MatchConfidence.likely;

  /// Whether the caller should store [plannedRunId] as a pending suggestion.
  bool get needsConfirmation => confidence == MatchConfidence.ambiguous;
}

/// A workout counts as satisfying a planned run when it lands within this band
/// of the target distance. Deliberately generous below target (runs get cut
/// short) and above (people add a warm-up/cool-down or just feel good), but
/// tight enough that a 3 km shakeout can't silently consume a 30 km long run.
const double _minDistanceRatio = 0.6;
const double _maxDistanceRatio = 2.0;

/// How many days either side of a planned run a workout may still claim it.
const int matchWindowDays = 1;

/// Whether a workout could still satisfy [run].
///
/// [RunStatus.missed] counts, so a late sync can recover a run the day rollover
/// already wrote off. Callers should re-run the rollover after such a recovery
/// so the engine can settle the load it already redistributed.
///
/// Also used by the UI to drop stale suggestions — a pending "is this your long
/// run?" is meaningless once that run has been completed some other way.
bool isClaimableByWorkout(PlannedRun run) =>
    run.type.isRun &&
    (run.status == RunStatus.pending ||
        run.status == RunStatus.shifted ||
        run.status == RunStatus.missed);

/// Ranks how well a workout's distance fits a planned run's target: lower is
/// better. Runs with no target distance are neutral (they can't disagree).
double _distanceMiss(PlannedRun run, double distanceKm) {
  final target = run.targetDistanceKm;
  if (target == null || target <= 0) return 0;
  return (distanceKm - target).abs() / target;
}

bool _distanceFits(PlannedRun run, double distanceKm) {
  final target = run.targetDistanceKm;
  if (target == null || target <= 0) return true;
  final ratio = distanceKm / target;
  return ratio >= _minDistanceRatio && ratio <= _maxDistanceRatio;
}

/// Prefer the highest-value session when a day holds more than one candidate.
int _typeRank(RunType type) => switch (type) {
      RunType.long => 0,
      RunType.steady => 1,
      RunType.easy => 2,
      _ => 3,
    };

/// Orders candidates best-first: run type, then closeness of distance.
int _compare(PlannedRun a, PlannedRun b, double distanceKm) {
  final byType = _typeRank(a.type).compareTo(_typeRank(b.type));
  if (byType != 0) return byType;
  return _distanceMiss(a, distanceKm).compareTo(_distanceMiss(b, distanceKm));
}

/// Matches a workout of [distanceKm] performed on [workoutDate] against
/// [candidates] (any planned runs from the active plan — this filters them).
///
/// [excludeIds] lets a caller processing several workouts in one pass keep two
/// of them from claiming the same planned run.
WorkoutMatch matchWorkout({
  required double distanceKm,
  required DateTime workoutDate,
  required List<PlannedRun> candidates,
  Set<int> excludeIds = const {},
}) {
  final date = dateOnly(workoutDate);
  final open = candidates
      .where((r) => isClaimableByWorkout(r) && !excludeIds.contains(r.id))
      .toList();
  if (open.isEmpty) return const WorkoutMatch.none();

  final sameDay = open.where((r) => isSameDate(r.scheduledDate, date)).toList();
  if (sameDay.isNotEmpty) {
    return _resolve(sameDay, distanceKm, MatchConfidence.exact);
  }

  final nearby = open
      .where((r) =>
          daysBetween(dateOnly(r.scheduledDate), date).abs() <= matchWindowDays)
      .toList();
  if (nearby.isEmpty) return const WorkoutMatch.none();

  return _resolve(nearby, distanceKm, MatchConfidence.likely);
}

/// Picks a winner from same-tier candidates and grades the confidence.
///
/// Two candidates that fit equally well are genuinely ambiguous — guessing
/// would silently mark the wrong session done — so those go to the user.
WorkoutMatch _resolve(
  List<PlannedRun> tier,
  double distanceKm,
  MatchConfidence ifClean,
) {
  final fitting = tier.where((r) => _distanceFits(r, distanceKm)).toList();

  // Nothing in range: the best candidate is still worth suggesting, but the
  // distance disagrees enough that we shouldn't decide for the user.
  if (fitting.isEmpty) {
    final sorted = [...tier]..sort((a, b) => _compare(a, b, distanceKm));
    return WorkoutMatch(sorted.first.id, MatchConfidence.ambiguous);
  }

  final sorted = [...fitting]..sort((a, b) => _compare(a, b, distanceKm));
  final best = sorted.first;
  if (sorted.length > 1) {
    final runnerUp = sorted[1];
    // Same run type and near-identical distance fit — no basis to choose.
    final tied = _typeRank(best.type) == _typeRank(runnerUp.type) &&
        (_distanceMiss(best, distanceKm) - _distanceMiss(runnerUp, distanceKm))
                .abs() <
            0.1;
    if (tied) return WorkoutMatch(best.id, MatchConfidence.ambiguous);
  }
  return WorkoutMatch(best.id, ifClean);
}
