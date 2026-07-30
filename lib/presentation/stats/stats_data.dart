import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/completed_run.dart';
import '../../domain/models/planned_run.dart';
import '../../domain/progress/progress_stats.dart';
import '../providers/providers.dart';

/// The progress maths itself lives in the pure domain layer so it can be unit
/// tested without Riverpod or a database; re-exported here so the screen keeps
/// a single import.
export '../../domain/progress/progress_stats.dart';

/// Derives [ProgressStats] from the active plan, planned runs and completed runs.
final statsProvider = Provider<ProgressStats>((ref) {
  final plan = ref.watch(activePlanProvider).value;
  if (plan == null) return ProgressStats.empty;

  return const ProgressCalculator().compute(
    plan: plan,
    plannedRuns: ref.watch(plannedRunsProvider).value ?? const <PlannedRun>[],
    completedRuns:
        ref.watch(completedRunsProvider).value ?? const <CompletedRun>[],
    asOf: ref.watch(todayProvider),
  );
});
