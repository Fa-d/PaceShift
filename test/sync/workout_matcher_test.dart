import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/models/planned_run.dart';
import 'package:paceshift/domain/sync/workout_matcher.dart';

/// Fixed reference day so nothing here depends on the wall clock.
final _monday = DateTime(2026, 3, 2);

PlannedRun _run({
  required int id,
  required DateTime date,
  RunType type = RunType.easy,
  double? km = 10,
  RunStatus status = RunStatus.pending,
}) =>
    PlannedRun(
      id: id,
      planId: 1,
      scheduledDate: date,
      originalDate: date,
      weekIndex: 1,
      type: type,
      targetDistanceKm: km,
      status: status,
    );

void main() {
  group('same-day matching', () {
    test('attaches a plausible workout to the day\'s run', () {
      final match = matchWorkout(
        distanceKm: 10.2,
        workoutDate: _monday,
        candidates: [_run(id: 1, date: _monday)],
      );
      expect(match.plannedRunId, 1);
      expect(match.confidence, MatchConfidence.exact);
      expect(match.isAutomatic, isTrue);
    });

    test('ignores the time of day on the workout timestamp', () {
      final match = matchWorkout(
        distanceKm: 10,
        workoutDate: DateTime(2026, 3, 2, 21, 45),
        candidates: [_run(id: 1, date: _monday)],
      );
      expect(match.plannedRunId, 1);
      expect(match.confidence, MatchConfidence.exact);
    });

    test('prefers the highest-value session when a day holds several', () {
      final match = matchWorkout(
        distanceKm: 20,
        workoutDate: _monday,
        candidates: [
          _run(id: 1, date: _monday, type: RunType.easy, km: 20),
          _run(id: 2, date: _monday, type: RunType.long, km: 20),
        ],
      );
      expect(match.plannedRunId, 2, reason: 'long outranks easy');
      expect(match.confidence, MatchConfidence.exact);
    });

    test('a wildly short workout does not silently consume a long run', () {
      final match = matchWorkout(
        distanceKm: 3,
        workoutDate: _monday,
        candidates: [_run(id: 1, date: _monday, type: RunType.long, km: 30)],
      );
      expect(match.confidence, MatchConfidence.ambiguous);
      expect(match.plannedRunId, 1, reason: 'still worth suggesting');
      expect(match.isAutomatic, isFalse);
      expect(match.needsConfirmation, isTrue);
    });

    test('two equally good candidates are ambiguous, not a coin flip', () {
      final match = matchWorkout(
        distanceKm: 10,
        workoutDate: _monday,
        candidates: [
          _run(id: 1, date: _monday, type: RunType.easy, km: 10),
          _run(id: 2, date: _monday, type: RunType.easy, km: 10),
        ],
      );
      expect(match.confidence, MatchConfidence.ambiguous);
    });

    test('same type but clearly different targets is not ambiguous', () {
      final match = matchWorkout(
        distanceKm: 16,
        workoutDate: _monday,
        candidates: [
          _run(id: 1, date: _monday, type: RunType.easy, km: 8),
          _run(id: 2, date: _monday, type: RunType.easy, km: 16),
        ],
      );
      expect(match.plannedRunId, 2);
      expect(match.confidence, MatchConfidence.exact);
    });
  });

  group('±1 day window', () {
    test('a Saturday-night run claims Sunday\'s long run', () {
      final sunday = _monday.subtract(const Duration(days: 1));
      final saturday = _monday.subtract(const Duration(days: 2));
      final match = matchWorkout(
        distanceKm: 24,
        workoutDate: saturday,
        candidates: [_run(id: 7, date: sunday, type: RunType.long, km: 25)],
      );
      expect(match.plannedRunId, 7);
      expect(match.confidence, MatchConfidence.likely);
      expect(match.isAutomatic, isTrue);
    });

    test('a same-day candidate always beats a neighbouring one', () {
      final tuesday = _monday.add(const Duration(days: 1));
      final match = matchWorkout(
        distanceKm: 10,
        workoutDate: _monday,
        candidates: [
          _run(id: 1, date: tuesday, type: RunType.long, km: 10),
          _run(id: 2, date: _monday, type: RunType.easy, km: 10),
        ],
      );
      expect(match.plannedRunId, 2);
      expect(match.confidence, MatchConfidence.exact);
    });

    test('two days out is beyond the window', () {
      final thursday = _monday.add(const Duration(days: 3));
      final match = matchWorkout(
        distanceKm: 10,
        workoutDate: _monday,
        candidates: [_run(id: 1, date: thursday)],
      );
      expect(match.confidence, MatchConfidence.none);
      expect(match.plannedRunId, isNull);
    });
  });

  group('claimable runs', () {
    test('rest, cross and strength days never match', () {
      for (final type in [RunType.rest, RunType.cross, RunType.strength]) {
        final match = matchWorkout(
          distanceKm: 10,
          workoutDate: _monday,
          candidates: [_run(id: 1, date: _monday, type: type, km: null)],
        );
        expect(match.confidence, MatchConfidence.none, reason: '$type');
      }
    });

    test('already-completed and dropped runs never match', () {
      for (final status in [RunStatus.completed, RunStatus.dropped]) {
        final match = matchWorkout(
          distanceKm: 10,
          workoutDate: _monday,
          candidates: [_run(id: 1, date: _monday, status: status)],
        );
        expect(match.confidence, MatchConfidence.none, reason: '$status');
      }
    });

    test('a missed run is recoverable by a late sync', () {
      final match = matchWorkout(
        distanceKm: 10,
        workoutDate: _monday,
        candidates: [_run(id: 1, date: _monday, status: RunStatus.missed)],
      );
      expect(match.plannedRunId, 1);
      expect(match.confidence, MatchConfidence.exact);
    });

    test('shifted runs are claimable', () {
      final match = matchWorkout(
        distanceKm: 10,
        workoutDate: _monday,
        candidates: [_run(id: 1, date: _monday, status: RunStatus.shifted)],
      );
      expect(match.confidence, MatchConfidence.exact);
    });

    test('excludeIds stops two workouts claiming one planned run', () {
      final match = matchWorkout(
        distanceKm: 10,
        workoutDate: _monday,
        candidates: [_run(id: 1, date: _monday)],
        excludeIds: {1},
      );
      expect(match.confidence, MatchConfidence.none);
    });

    test('no candidates at all', () {
      final match = matchWorkout(
        distanceKm: 10,
        workoutDate: _monday,
        candidates: const [],
      );
      expect(match.confidence, MatchConfidence.none);
      expect(match.plannedRunId, isNull);
    });
  });

  group('distance tolerance', () {
    test('a run with no target distance accepts any plausible effort', () {
      final match = matchWorkout(
        distanceKm: 7,
        workoutDate: _monday,
        candidates: [_run(id: 1, date: _monday, km: null)],
      );
      expect(match.plannedRunId, 1);
      expect(match.confidence, MatchConfidence.exact);
    });

    test('a modest overshoot still counts', () {
      final match = matchWorkout(
        distanceKm: 12,
        workoutDate: _monday,
        candidates: [_run(id: 1, date: _monday, km: 10)],
      );
      expect(match.confidence, MatchConfidence.exact);
    });

    test('cutting a run slightly short still counts', () {
      final match = matchWorkout(
        distanceKm: 7,
        workoutDate: _monday,
        candidates: [_run(id: 1, date: _monday, km: 10)],
      );
      expect(match.confidence, MatchConfidence.exact);
    });

    test('more than double the target asks first', () {
      final match = matchWorkout(
        distanceKm: 25,
        workoutDate: _monday,
        candidates: [_run(id: 1, date: _monday, km: 10)],
      );
      expect(match.confidence, MatchConfidence.ambiguous);
    });
  });
}
