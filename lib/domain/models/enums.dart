// Pure domain enums shared across the data, domain, and presentation layers.
//
// These have no Flutter or IO dependencies so they can be used by the pure
// scheduling engine and plan generator and exercised in unit tests.

/// Distance units. Metric is the default.
enum UnitSystem { metric, imperial }

/// The kind of session a planned run represents.
enum RunType {
  easy,
  steady,
  long,
  rest,
  cross,
  strength;

  /// Whether the session involves actual running mileage that counts toward
  /// weekly load. Rest/strength/cross do not add running kilometres.
  bool get isRun => this == RunType.easy || this == RunType.steady || this == RunType.long;

  /// A "hard" run requires recovery afterwards (used by the min-rest rule).
  bool get isHard => this == RunType.long || this == RunType.steady;
}

/// Lifecycle of a single planned run.
enum RunStatus {
  pending,
  completed,
  missed,
  shifted,
  dropped,
}

/// Lifecycle of a training plan.
enum PlanStatus {
  active,
  completed,
  archived,
}

/// Where a completed run's data originated.
enum RunSource {
  healthConnect,
  manual,
}

/// The physical activity a completed session represents.
///
/// Only [run] sessions count toward running volume, fitness and race
/// prediction. Walks and hikes are stored (e.g. for a future cross-training
/// view) but deliberately excluded from those running stats.
enum ActivityType {
  run,
  walk,
  hike;

  /// Whether this activity counts as running mileage/fitness.
  bool get isRun => this == ActivityType.run;
}

/// How aggressively the adaptive engine redistributes missed load.
///
/// Tunes the catch-up windows and how willingly the engine reduces or drops
/// runs versus degrading the plan's ambition.
enum Aggressiveness {
  conservative,
  balanced,
  aggressive,
}

/// Priority bands used by the adaptive engine when rescheduling a missed run.
///
/// Derived from [RunType] (see [runPriority]). Higher bands are preserved more
/// strongly; lower bands are dropped before injury risk is taken on.
enum RunPriority {
  /// Long runs — must be preserved; the marathon is built here.
  high,

  /// Steady / medium runs — reschedule if it fits safely, else reduce or drop.
  medium,

  /// Easy / recovery runs — reschedule into a nearby slot, otherwise drop.
  low,

  /// Strength / cross / rest — flexible and freely droppable.
  flexible,
}

/// Maps a [RunType] to its scheduling [RunPriority] (spec §4.2).
RunPriority runPriority(RunType type) {
  switch (type) {
    case RunType.long:
      return RunPriority.high;
    case RunType.steady:
      return RunPriority.medium;
    case RunType.easy:
      return RunPriority.low;
    case RunType.rest:
    case RunType.cross:
    case RunType.strength:
      return RunPriority.flexible;
  }
}
