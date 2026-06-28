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

  Future<void> archiveActivePlan() => _plans.archiveAllActivePlans();
}
