import 'package:paceshift/core/date_utils.dart';
import 'package:paceshift/domain/engine/schedule_snapshot.dart';
import 'package:paceshift/domain/models/app_settings.dart';
import 'package:paceshift/domain/models/completed_run.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/domain/models/planned_run.dart';
import 'package:paceshift/domain/models/training_plan.dart';

/// A fixed Monday used as the plan start in engine tests (2026-01-05 is a Monday).
final DateTime kStart = DateTime(2026, 1, 5);

/// Builds a test plan: [weeks] long, race on the final week's Monday.
TrainingPlan testPlan({
  int weeks = 10,
  int taperWeeks = 3,
  int longRunDay = DateTime.saturday,
}) {
  final race = addDays(kStart, (weeks - 1) * 7);
  return TrainingPlan(
    id: 1,
    name: 'Test',
    raceDate: race,
    raceDistanceKm: 42.2,
    startDate: kStart,
    longRunDay: longRunDay,
    status: PlanStatus.active,
    createdAt: kStart,
    taperWeeks: taperWeeks,
  );
}

/// The date of [weekday] (Mon=1…Sun=7) within 1-based training [week].
DateTime dayIn(int week, int weekday) =>
    addDays(kStart, (week - 1) * 7 + (weekday - 1));

int _weekOf(DateTime d) => (daysBetween(kStart, d) ~/ 7) + 1;

int _id = 0;

/// Builds a planned run on a specific date. Ids auto-increment unless given.
PlannedRun run({
  int? id,
  required DateTime date,
  required RunType type,
  double? km,
  RunStatus status = RunStatus.pending,
  DateTime? original,
}) {
  final d = dateOnly(date);
  return PlannedRun(
    id: id ?? (++_id),
    planId: 1,
    scheduledDate: d,
    originalDate: dateOnly(original ?? date),
    weekIndex: _weekOf(d),
    type: type,
    targetDistanceKm: km,
    status: status,
  );
}

void resetIds() => _id = 0;

/// Builds a snapshot. [today] defaults to the plan start.
ScheduleSnapshot snapshot({
  required TrainingPlan plan,
  required List<PlannedRun> runs,
  List<CompletedRun> completed = const [],
  AppSettings settings = const AppSettings(),
  required DateTime today,
}) =>
    ScheduleSnapshot(
      plan: plan,
      plannedRuns: runs,
      completedRuns: completed,
      settings: settings,
      today: dateOnly(today),
    );

/// Convenience: a standard 3-runs-per-week block (easy Mon, steady Wed, long Sat)
/// for [week] with the given distances.
List<PlannedRun> standardWeek(
  int week, {
  double easyKm = 6,
  double steadyKm = 10,
  double longKm = 20,
}) =>
    [
      run(date: dayIn(week, DateTime.monday), type: RunType.easy, km: easyKm),
      run(date: dayIn(week, DateTime.wednesday), type: RunType.steady, km: steadyKm),
      run(date: dayIn(week, DateTime.saturday), type: RunType.long, km: longKm),
    ];

extension RunListLookup on List<PlannedRun> {
  PlannedRun byId(int id) => firstWhere((r) => r.id == id);
}
