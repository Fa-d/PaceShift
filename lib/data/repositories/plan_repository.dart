import 'package:drift/drift.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/training_plan.dart';
import '../../domain/plan_generator/plan_generator.dart';
import '../../domain/plan_generator/plan_input.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Persists and exposes the active training plan and its runs.
class PlanRepository {
  PlanRepository(this._db, {PlanGenerator generator = const PlanGenerator()})
      : _generator = generator;

  final AppDatabase _db;
  final PlanGenerator _generator;

  PlanDao get _plans => _db.planDao;
  RunsDao get _runs => _db.runsDao;

  /// Reactive stream of the currently active plan (null if none).
  Stream<TrainingPlan?> watchActivePlan() =>
      _plans.watchActivePlan().map((row) => row?.toDomain());

  Future<TrainingPlan?> getActivePlan() async =>
      (await _plans.getActivePlan())?.toDomain();

  /// Generates a plan from [input], archives any existing active plan, and
  /// persists the new plan with all its planned runs in one transaction.
  /// Returns the new plan id.
  Future<int> createPlanFromInput(PlanInput input) async {
    final generated = _generator.generate(input);
    return _db.transaction(() async {
      await _plans.archiveAllActivePlans();
      final planId = await _plans.insertPlan(generated.plan.toCompanion());
      final companions = generated.runs
          .map((r) => r.copyWith(planId: planId).toCompanion())
          .toList();
      await _runs.insertPlannedRuns(companions);
      return planId;
    });
  }

  /// Rebuilds the plan from new [input], keeping the athlete's history.
  ///
  /// Race dates move, injuries happen, and people change their minds about how
  /// many days a week they can run. Until now [createPlanFromInput] had exactly
  /// one call site — the last step of onboarding — so every one of those
  /// answers was permanent from the first minute of using the app.
  ///
  /// Completed runs are **kept and re-attached** to whichever run in the new
  /// plan falls on the same day. A workout the athlete actually did is a fact
  /// about them, not about the plan that happened to ask for it; anything with
  /// no counterpart in the new plan survives as an unattached extra run rather
  /// than being deleted.
  Future<int> regeneratePlan(PlanInput input) async {
    final generated = _generator.generate(input);
    return _db.transaction(() async {
      final completed = await _runs.watchCompletedRuns().first;

      await _plans.archiveAllActivePlans();
      final planId = await _plans.insertPlan(generated.plan.toCompanion());
      await _runs.insertPlannedRuns(
        generated.runs.map((r) => r.copyWith(planId: planId).toCompanion())
            .toList(),
      );

      // Re-link history by date against the plan we just wrote.
      final fresh = await _runs.getPlannedRuns(planId);
      for (final row in completed) {
        final match = fresh
            .where((p) => _sameDay(p.scheduledDate, row.date) && p.type.isRun)
            .firstOrNull;
        await _runs.updateCompletedRun(
          row.id,
          CompletedRunsCompanion(
            plannedRunId: Value(match?.id),
            suggestedPlannedRunId: const Value(null),
          ),
        );
        if (match != null) {
          await _runs.updatePlannedRun(
            match.id,
            const PlannedRunsCompanion(status: Value(RunStatus.completed)),
          );
        }
      }
      return planId;
    });
  }

  /// How much history a regeneration would carry over — shown in the
  /// confirmation before anything is rewritten.
  Future<int> completedRunCount() async =>
      (await _runs.watchCompletedRuns().first).length;

  /// Archives the plan and deletes its runs, returning the athlete to
  /// onboarding. Completed runs are left alone.
  Future<void> deleteActivePlan() async {
    final plan = await _plans.getActivePlan();
    await _db.transaction(() async {
      if (plan != null) await _runs.deletePlannedRunsForPlan(plan.id);
      await _plans.archiveAllActivePlans();
    });
  }

  Future<void> archiveActivePlan() => _plans.archiveAllActivePlans();

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
