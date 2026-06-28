import '../models/planned_run.dart';

/// One thing the engine did to a run, used to build the plain-language summary
/// and to drive UI. A sealed union — switch on it with native pattern matching.
sealed class RunChange {
  const RunChange(this.run);

  /// The run in its **new** state after the change.
  final PlannedRun run;
}

/// The run was moved to a new date (kept, possibly reduced).
class RunMovedChange extends RunChange {
  const RunMovedChange(super.run, {required this.from, required this.to});
  final DateTime from;
  final DateTime to;
}

/// The run was kept but its distance reduced to fit safely.
class RunReducedChange extends RunChange {
  const RunReducedChange(super.run, {required this.fromKm, required this.toKm});
  final double fromKm;
  final double toKm;
}

/// The run was dropped (low value, or no safe slot).
class RunDroppedChange extends RunChange {
  const RunDroppedChange(super.run, {required this.reason});
  final String reason;
}

/// The run expired beyond its catch-up window and was recorded as missed.
class RunExpiredChange extends RunChange {
  const RunExpiredChange(super.run);
}

/// Two long runs were rebalanced to honour the week-over-week rule.
class LongRunRebalancedChange extends RunChange {
  const LongRunRebalancedChange(super.run, {required this.partnerRunId});
  final int partnerRunId;
}

/// A choice the engine surfaces when safe redistribution is impossible
/// (spec §4.6). The engine never applies these silently.
enum DegradeKind { reducePeak, acceptRisk, dropLowValue }

class DegradeOption {
  const DegradeOption({
    required this.kind,
    required this.title,
    required this.description,
  });
  final DegradeKind kind;
  final String title;
  final String description;
}

/// The result of an engine pass: the full updated run list plus a changelog and
/// any decision the user must make.
class RescheduleOutcome {
  RescheduleOutcome({
    required this.runs,
    required this.changes,
    this.decisions = const [],
  });

  /// The complete new state of the plan's runs (persist these).
  final List<PlannedRun> runs;

  /// What changed, in order.
  final List<RunChange> changes;

  /// Non-empty when the user must choose how to degrade the plan (spec §4.6).
  final List<DegradeOption> decisions;

  bool get needsDecision => decisions.isNotEmpty;
  bool get hasChanges => changes.isNotEmpty;
}
