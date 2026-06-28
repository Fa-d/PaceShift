import '../../core/date_utils.dart';
import '../models/app_settings.dart';
import '../models/completed_run.dart';
import '../models/planned_run.dart';
import '../models/training_plan.dart';

/// An immutable, in-memory view of everything the [AdaptiveScheduler] needs.
///
/// The engine is **pure**: it reads a snapshot and returns a diff. The
/// repository is responsible for building this from the database and persisting
/// the result.
class ScheduleSnapshot {
  ScheduleSnapshot({
    required this.plan,
    required this.plannedRuns,
    required this.completedRuns,
    required this.settings,
    required this.today,
  });

  final TrainingPlan plan;
  final List<PlannedRun> plannedRuns;
  final List<CompletedRun> completedRuns;
  final AppSettings settings;
  final DateTime today;

  /// 1-based training week containing [date], derived from the plan's start.
  int weekOf(DateTime date) {
    final days = daysBetween(plan.startDate, date);
    if (days < 0) return 1;
    return (days ~/ 7) + 1;
  }

  /// The week index of race week (the final week).
  int get raceWeek => weekOf(plan.raceDate);

  /// First week index considered part of the taper (inclusive). Runs in weeks
  /// >= this are taper-locked (spec §4.3 rule 4).
  int get firstTaperWeek => raceWeek - plan.taperWeeks;

  bool isTaperWeek(int week) => week >= firstTaperWeek && week <= raceWeek;

  bool isTaperDate(DateTime date) => isTaperWeek(weekOf(date));
}
