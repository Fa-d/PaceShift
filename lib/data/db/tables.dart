import 'package:drift/drift.dart';

import '../../domain/models/enums.dart';

/// Drift table definitions (spec §3). Enums are stored as **text** (their
/// `.name`) so reordering an enum never corrupts existing rows.

@DataClassName('TrainingPlanRow')
class TrainingPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get raceDate => dateTime()();
  RealColumn get raceDistanceKm => real()();
  DateTimeColumn get startDate => dateTime()();

  /// Preferred long-run weekday, Mon=1 … Sun=7.
  IntColumn get longRunDay => integer()();
  TextColumn get status => textEnum<PlanStatus>()();
  IntColumn get taperWeeks => integer().withDefault(const Constant(3))();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('PlannedRunRow')
class PlannedRuns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(TrainingPlans, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledDate => dateTime()();
  DateTimeColumn get originalDate => dateTime()();
  IntColumn get weekIndex => integer()();
  TextColumn get type => textEnum<RunType>()();
  RealColumn get targetDistanceKm => real().nullable()();
  IntColumn get targetDurationMin => integer().nullable()();
  TextColumn get runWalkRatio => text().nullable()();
  RealColumn get targetPaceSecPerKm => real().nullable()();

  /// Structured workout segments serialized as a JSON array (null = simple run).
  TextColumn get segmentsJson => text().nullable()();
  TextColumn get status => textEnum<RunStatus>()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('CompletedRunRow')
class CompletedRuns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plannedRunId =>
      integer().nullable().references(PlannedRuns, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get date => dateTime()();
  RealColumn get actualDistanceKm => real()();
  IntColumn get durationSec => integer()();
  RealColumn get avgPaceSecPerKm => real()();
  IntColumn get avgHr => integer().nullable()();
  IntColumn get maxHr => integer().nullable()();
  RealColumn get calories => real().nullable()();
  TextColumn get source => textEnum<RunSource>()();

  /// Health Connect record id, for dedup. Unique when present.
  TextColumn get externalId => text().nullable()();
}

/// Single-row settings table (id is always 0).
@DataClassName('SettingsRow')
class SettingsRows extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get units => textEnum<UnitSystem>()();
  IntColumn get reminderMorningMinutes => integer()();
  IntColumn get reminderEveningMinutes => integer()();
  TextColumn get adaptivityAggressiveness => textEnum<Aggressiveness>()();
  IntColumn get catchupWindowDays => integer()();
  IntColumn get longRunCatchupWindowDays => integer()();
  BoolColumn get cloudBackupEnabled => boolean()();

  /// Last successful Health Connect sync (null until first sync).
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
