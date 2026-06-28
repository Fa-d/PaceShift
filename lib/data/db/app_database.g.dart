// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TrainingPlansTable extends TrainingPlans
    with TableInfo<$TrainingPlansTable, TrainingPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainingPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _raceDateMeta = const VerificationMeta(
    'raceDate',
  );
  @override
  late final GeneratedColumn<DateTime> raceDate = GeneratedColumn<DateTime>(
    'race_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _raceDistanceKmMeta = const VerificationMeta(
    'raceDistanceKm',
  );
  @override
  late final GeneratedColumn<double> raceDistanceKm = GeneratedColumn<double>(
    'race_distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longRunDayMeta = const VerificationMeta(
    'longRunDay',
  );
  @override
  late final GeneratedColumn<int> longRunDay = GeneratedColumn<int>(
    'long_run_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlanStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PlanStatus>($TrainingPlansTable.$converterstatus);
  static const VerificationMeta _taperWeeksMeta = const VerificationMeta(
    'taperWeeks',
  );
  @override
  late final GeneratedColumn<int> taperWeeks = GeneratedColumn<int>(
    'taper_weeks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    raceDate,
    raceDistanceKm,
    startDate,
    longRunDay,
    status,
    taperWeeks,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'training_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrainingPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('race_date')) {
      context.handle(
        _raceDateMeta,
        raceDate.isAcceptableOrUnknown(data['race_date']!, _raceDateMeta),
      );
    } else if (isInserting) {
      context.missing(_raceDateMeta);
    }
    if (data.containsKey('race_distance_km')) {
      context.handle(
        _raceDistanceKmMeta,
        raceDistanceKm.isAcceptableOrUnknown(
          data['race_distance_km']!,
          _raceDistanceKmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_raceDistanceKmMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('long_run_day')) {
      context.handle(
        _longRunDayMeta,
        longRunDay.isAcceptableOrUnknown(
          data['long_run_day']!,
          _longRunDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_longRunDayMeta);
    }
    if (data.containsKey('taper_weeks')) {
      context.handle(
        _taperWeeksMeta,
        taperWeeks.isAcceptableOrUnknown(data['taper_weeks']!, _taperWeeksMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainingPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainingPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      raceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}race_date'],
      )!,
      raceDistanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}race_distance_km'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      longRunDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}long_run_day'],
      )!,
      status: $TrainingPlansTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      taperWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taper_weeks'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TrainingPlansTable createAlias(String alias) {
    return $TrainingPlansTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PlanStatus, String, String> $converterstatus =
      const EnumNameConverter<PlanStatus>(PlanStatus.values);
}

class TrainingPlanRow extends DataClass implements Insertable<TrainingPlanRow> {
  final int id;
  final String name;
  final DateTime raceDate;
  final double raceDistanceKm;
  final DateTime startDate;

  /// Preferred long-run weekday, Mon=1 … Sun=7.
  final int longRunDay;
  final PlanStatus status;
  final int taperWeeks;
  final DateTime createdAt;
  const TrainingPlanRow({
    required this.id,
    required this.name,
    required this.raceDate,
    required this.raceDistanceKm,
    required this.startDate,
    required this.longRunDay,
    required this.status,
    required this.taperWeeks,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['race_date'] = Variable<DateTime>(raceDate);
    map['race_distance_km'] = Variable<double>(raceDistanceKm);
    map['start_date'] = Variable<DateTime>(startDate);
    map['long_run_day'] = Variable<int>(longRunDay);
    {
      map['status'] = Variable<String>(
        $TrainingPlansTable.$converterstatus.toSql(status),
      );
    }
    map['taper_weeks'] = Variable<int>(taperWeeks);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TrainingPlansCompanion toCompanion(bool nullToAbsent) {
    return TrainingPlansCompanion(
      id: Value(id),
      name: Value(name),
      raceDate: Value(raceDate),
      raceDistanceKm: Value(raceDistanceKm),
      startDate: Value(startDate),
      longRunDay: Value(longRunDay),
      status: Value(status),
      taperWeeks: Value(taperWeeks),
      createdAt: Value(createdAt),
    );
  }

  factory TrainingPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainingPlanRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      raceDate: serializer.fromJson<DateTime>(json['raceDate']),
      raceDistanceKm: serializer.fromJson<double>(json['raceDistanceKm']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      longRunDay: serializer.fromJson<int>(json['longRunDay']),
      status: $TrainingPlansTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      taperWeeks: serializer.fromJson<int>(json['taperWeeks']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'raceDate': serializer.toJson<DateTime>(raceDate),
      'raceDistanceKm': serializer.toJson<double>(raceDistanceKm),
      'startDate': serializer.toJson<DateTime>(startDate),
      'longRunDay': serializer.toJson<int>(longRunDay),
      'status': serializer.toJson<String>(
        $TrainingPlansTable.$converterstatus.toJson(status),
      ),
      'taperWeeks': serializer.toJson<int>(taperWeeks),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TrainingPlanRow copyWith({
    int? id,
    String? name,
    DateTime? raceDate,
    double? raceDistanceKm,
    DateTime? startDate,
    int? longRunDay,
    PlanStatus? status,
    int? taperWeeks,
    DateTime? createdAt,
  }) => TrainingPlanRow(
    id: id ?? this.id,
    name: name ?? this.name,
    raceDate: raceDate ?? this.raceDate,
    raceDistanceKm: raceDistanceKm ?? this.raceDistanceKm,
    startDate: startDate ?? this.startDate,
    longRunDay: longRunDay ?? this.longRunDay,
    status: status ?? this.status,
    taperWeeks: taperWeeks ?? this.taperWeeks,
    createdAt: createdAt ?? this.createdAt,
  );
  TrainingPlanRow copyWithCompanion(TrainingPlansCompanion data) {
    return TrainingPlanRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      raceDate: data.raceDate.present ? data.raceDate.value : this.raceDate,
      raceDistanceKm: data.raceDistanceKm.present
          ? data.raceDistanceKm.value
          : this.raceDistanceKm,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      longRunDay: data.longRunDay.present
          ? data.longRunDay.value
          : this.longRunDay,
      status: data.status.present ? data.status.value : this.status,
      taperWeeks: data.taperWeeks.present
          ? data.taperWeeks.value
          : this.taperWeeks,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainingPlanRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('raceDate: $raceDate, ')
          ..write('raceDistanceKm: $raceDistanceKm, ')
          ..write('startDate: $startDate, ')
          ..write('longRunDay: $longRunDay, ')
          ..write('status: $status, ')
          ..write('taperWeeks: $taperWeeks, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    raceDate,
    raceDistanceKm,
    startDate,
    longRunDay,
    status,
    taperWeeks,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainingPlanRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.raceDate == this.raceDate &&
          other.raceDistanceKm == this.raceDistanceKm &&
          other.startDate == this.startDate &&
          other.longRunDay == this.longRunDay &&
          other.status == this.status &&
          other.taperWeeks == this.taperWeeks &&
          other.createdAt == this.createdAt);
}

class TrainingPlansCompanion extends UpdateCompanion<TrainingPlanRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> raceDate;
  final Value<double> raceDistanceKm;
  final Value<DateTime> startDate;
  final Value<int> longRunDay;
  final Value<PlanStatus> status;
  final Value<int> taperWeeks;
  final Value<DateTime> createdAt;
  const TrainingPlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.raceDate = const Value.absent(),
    this.raceDistanceKm = const Value.absent(),
    this.startDate = const Value.absent(),
    this.longRunDay = const Value.absent(),
    this.status = const Value.absent(),
    this.taperWeeks = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TrainingPlansCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime raceDate,
    required double raceDistanceKm,
    required DateTime startDate,
    required int longRunDay,
    required PlanStatus status,
    this.taperWeeks = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       raceDate = Value(raceDate),
       raceDistanceKm = Value(raceDistanceKm),
       startDate = Value(startDate),
       longRunDay = Value(longRunDay),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<TrainingPlanRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? raceDate,
    Expression<double>? raceDistanceKm,
    Expression<DateTime>? startDate,
    Expression<int>? longRunDay,
    Expression<String>? status,
    Expression<int>? taperWeeks,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (raceDate != null) 'race_date': raceDate,
      if (raceDistanceKm != null) 'race_distance_km': raceDistanceKm,
      if (startDate != null) 'start_date': startDate,
      if (longRunDay != null) 'long_run_day': longRunDay,
      if (status != null) 'status': status,
      if (taperWeeks != null) 'taper_weeks': taperWeeks,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TrainingPlansCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? raceDate,
    Value<double>? raceDistanceKm,
    Value<DateTime>? startDate,
    Value<int>? longRunDay,
    Value<PlanStatus>? status,
    Value<int>? taperWeeks,
    Value<DateTime>? createdAt,
  }) {
    return TrainingPlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      raceDate: raceDate ?? this.raceDate,
      raceDistanceKm: raceDistanceKm ?? this.raceDistanceKm,
      startDate: startDate ?? this.startDate,
      longRunDay: longRunDay ?? this.longRunDay,
      status: status ?? this.status,
      taperWeeks: taperWeeks ?? this.taperWeeks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (raceDate.present) {
      map['race_date'] = Variable<DateTime>(raceDate.value);
    }
    if (raceDistanceKm.present) {
      map['race_distance_km'] = Variable<double>(raceDistanceKm.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (longRunDay.present) {
      map['long_run_day'] = Variable<int>(longRunDay.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TrainingPlansTable.$converterstatus.toSql(status.value),
      );
    }
    if (taperWeeks.present) {
      map['taper_weeks'] = Variable<int>(taperWeeks.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainingPlansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('raceDate: $raceDate, ')
          ..write('raceDistanceKm: $raceDistanceKm, ')
          ..write('startDate: $startDate, ')
          ..write('longRunDay: $longRunDay, ')
          ..write('status: $status, ')
          ..write('taperWeeks: $taperWeeks, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlannedRunsTable extends PlannedRuns
    with TableInfo<$PlannedRunsTable, PlannedRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES training_plans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _originalDateMeta = const VerificationMeta(
    'originalDate',
  );
  @override
  late final GeneratedColumn<DateTime> originalDate = GeneratedColumn<DateTime>(
    'original_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekIndexMeta = const VerificationMeta(
    'weekIndex',
  );
  @override
  late final GeneratedColumn<int> weekIndex = GeneratedColumn<int>(
    'week_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RunType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RunType>($PlannedRunsTable.$convertertype);
  static const VerificationMeta _targetDistanceKmMeta = const VerificationMeta(
    'targetDistanceKm',
  );
  @override
  late final GeneratedColumn<double> targetDistanceKm = GeneratedColumn<double>(
    'target_distance_km',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDurationMinMeta = const VerificationMeta(
    'targetDurationMin',
  );
  @override
  late final GeneratedColumn<int> targetDurationMin = GeneratedColumn<int>(
    'target_duration_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runWalkRatioMeta = const VerificationMeta(
    'runWalkRatio',
  );
  @override
  late final GeneratedColumn<String> runWalkRatio = GeneratedColumn<String>(
    'run_walk_ratio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetPaceSecPerKmMeta =
      const VerificationMeta('targetPaceSecPerKm');
  @override
  late final GeneratedColumn<double> targetPaceSecPerKm =
      GeneratedColumn<double>(
        'target_pace_sec_per_km',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _segmentsJsonMeta = const VerificationMeta(
    'segmentsJson',
  );
  @override
  late final GeneratedColumn<String> segmentsJson = GeneratedColumn<String>(
    'segments_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RunStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RunStatus>($PlannedRunsTable.$converterstatus);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    scheduledDate,
    originalDate,
    weekIndex,
    type,
    targetDistanceKm,
    targetDurationMin,
    runWalkRatio,
    targetPaceSecPerKm,
    segmentsJson,
    status,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('original_date')) {
      context.handle(
        _originalDateMeta,
        originalDate.isAcceptableOrUnknown(
          data['original_date']!,
          _originalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalDateMeta);
    }
    if (data.containsKey('week_index')) {
      context.handle(
        _weekIndexMeta,
        weekIndex.isAcceptableOrUnknown(data['week_index']!, _weekIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_weekIndexMeta);
    }
    if (data.containsKey('target_distance_km')) {
      context.handle(
        _targetDistanceKmMeta,
        targetDistanceKm.isAcceptableOrUnknown(
          data['target_distance_km']!,
          _targetDistanceKmMeta,
        ),
      );
    }
    if (data.containsKey('target_duration_min')) {
      context.handle(
        _targetDurationMinMeta,
        targetDurationMin.isAcceptableOrUnknown(
          data['target_duration_min']!,
          _targetDurationMinMeta,
        ),
      );
    }
    if (data.containsKey('run_walk_ratio')) {
      context.handle(
        _runWalkRatioMeta,
        runWalkRatio.isAcceptableOrUnknown(
          data['run_walk_ratio']!,
          _runWalkRatioMeta,
        ),
      );
    }
    if (data.containsKey('target_pace_sec_per_km')) {
      context.handle(
        _targetPaceSecPerKmMeta,
        targetPaceSecPerKm.isAcceptableOrUnknown(
          data['target_pace_sec_per_km']!,
          _targetPaceSecPerKmMeta,
        ),
      );
    }
    if (data.containsKey('segments_json')) {
      context.handle(
        _segmentsJsonMeta,
        segmentsJson.isAcceptableOrUnknown(
          data['segments_json']!,
          _segmentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      )!,
      originalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}original_date'],
      )!,
      weekIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_index'],
      )!,
      type: $PlannedRunsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      targetDistanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_distance_km'],
      ),
      targetDurationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_duration_min'],
      ),
      runWalkRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_walk_ratio'],
      ),
      targetPaceSecPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_pace_sec_per_km'],
      ),
      segmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segments_json'],
      ),
      status: $PlannedRunsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $PlannedRunsTable createAlias(String alias) {
    return $PlannedRunsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RunType, String, String> $convertertype =
      const EnumNameConverter<RunType>(RunType.values);
  static JsonTypeConverter2<RunStatus, String, String> $converterstatus =
      const EnumNameConverter<RunStatus>(RunStatus.values);
}

class PlannedRunRow extends DataClass implements Insertable<PlannedRunRow> {
  final int id;
  final int planId;
  final DateTime scheduledDate;
  final DateTime originalDate;
  final int weekIndex;
  final RunType type;
  final double? targetDistanceKm;
  final int? targetDurationMin;
  final String? runWalkRatio;
  final double? targetPaceSecPerKm;

  /// Structured workout segments serialized as a JSON array (null = simple run).
  final String? segmentsJson;
  final RunStatus status;
  final String? notes;
  const PlannedRunRow({
    required this.id,
    required this.planId,
    required this.scheduledDate,
    required this.originalDate,
    required this.weekIndex,
    required this.type,
    this.targetDistanceKm,
    this.targetDurationMin,
    this.runWalkRatio,
    this.targetPaceSecPerKm,
    this.segmentsJson,
    required this.status,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    map['original_date'] = Variable<DateTime>(originalDate);
    map['week_index'] = Variable<int>(weekIndex);
    {
      map['type'] = Variable<String>(
        $PlannedRunsTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || targetDistanceKm != null) {
      map['target_distance_km'] = Variable<double>(targetDistanceKm);
    }
    if (!nullToAbsent || targetDurationMin != null) {
      map['target_duration_min'] = Variable<int>(targetDurationMin);
    }
    if (!nullToAbsent || runWalkRatio != null) {
      map['run_walk_ratio'] = Variable<String>(runWalkRatio);
    }
    if (!nullToAbsent || targetPaceSecPerKm != null) {
      map['target_pace_sec_per_km'] = Variable<double>(targetPaceSecPerKm);
    }
    if (!nullToAbsent || segmentsJson != null) {
      map['segments_json'] = Variable<String>(segmentsJson);
    }
    {
      map['status'] = Variable<String>(
        $PlannedRunsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  PlannedRunsCompanion toCompanion(bool nullToAbsent) {
    return PlannedRunsCompanion(
      id: Value(id),
      planId: Value(planId),
      scheduledDate: Value(scheduledDate),
      originalDate: Value(originalDate),
      weekIndex: Value(weekIndex),
      type: Value(type),
      targetDistanceKm: targetDistanceKm == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDistanceKm),
      targetDurationMin: targetDurationMin == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDurationMin),
      runWalkRatio: runWalkRatio == null && nullToAbsent
          ? const Value.absent()
          : Value(runWalkRatio),
      targetPaceSecPerKm: targetPaceSecPerKm == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPaceSecPerKm),
      segmentsJson: segmentsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(segmentsJson),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory PlannedRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedRunRow(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      scheduledDate: serializer.fromJson<DateTime>(json['scheduledDate']),
      originalDate: serializer.fromJson<DateTime>(json['originalDate']),
      weekIndex: serializer.fromJson<int>(json['weekIndex']),
      type: $PlannedRunsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      targetDistanceKm: serializer.fromJson<double?>(json['targetDistanceKm']),
      targetDurationMin: serializer.fromJson<int?>(json['targetDurationMin']),
      runWalkRatio: serializer.fromJson<String?>(json['runWalkRatio']),
      targetPaceSecPerKm: serializer.fromJson<double?>(
        json['targetPaceSecPerKm'],
      ),
      segmentsJson: serializer.fromJson<String?>(json['segmentsJson']),
      status: $PlannedRunsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'scheduledDate': serializer.toJson<DateTime>(scheduledDate),
      'originalDate': serializer.toJson<DateTime>(originalDate),
      'weekIndex': serializer.toJson<int>(weekIndex),
      'type': serializer.toJson<String>(
        $PlannedRunsTable.$convertertype.toJson(type),
      ),
      'targetDistanceKm': serializer.toJson<double?>(targetDistanceKm),
      'targetDurationMin': serializer.toJson<int?>(targetDurationMin),
      'runWalkRatio': serializer.toJson<String?>(runWalkRatio),
      'targetPaceSecPerKm': serializer.toJson<double?>(targetPaceSecPerKm),
      'segmentsJson': serializer.toJson<String?>(segmentsJson),
      'status': serializer.toJson<String>(
        $PlannedRunsTable.$converterstatus.toJson(status),
      ),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  PlannedRunRow copyWith({
    int? id,
    int? planId,
    DateTime? scheduledDate,
    DateTime? originalDate,
    int? weekIndex,
    RunType? type,
    Value<double?> targetDistanceKm = const Value.absent(),
    Value<int?> targetDurationMin = const Value.absent(),
    Value<String?> runWalkRatio = const Value.absent(),
    Value<double?> targetPaceSecPerKm = const Value.absent(),
    Value<String?> segmentsJson = const Value.absent(),
    RunStatus? status,
    Value<String?> notes = const Value.absent(),
  }) => PlannedRunRow(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    originalDate: originalDate ?? this.originalDate,
    weekIndex: weekIndex ?? this.weekIndex,
    type: type ?? this.type,
    targetDistanceKm: targetDistanceKm.present
        ? targetDistanceKm.value
        : this.targetDistanceKm,
    targetDurationMin: targetDurationMin.present
        ? targetDurationMin.value
        : this.targetDurationMin,
    runWalkRatio: runWalkRatio.present ? runWalkRatio.value : this.runWalkRatio,
    targetPaceSecPerKm: targetPaceSecPerKm.present
        ? targetPaceSecPerKm.value
        : this.targetPaceSecPerKm,
    segmentsJson: segmentsJson.present ? segmentsJson.value : this.segmentsJson,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
  );
  PlannedRunRow copyWithCompanion(PlannedRunsCompanion data) {
    return PlannedRunRow(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      originalDate: data.originalDate.present
          ? data.originalDate.value
          : this.originalDate,
      weekIndex: data.weekIndex.present ? data.weekIndex.value : this.weekIndex,
      type: data.type.present ? data.type.value : this.type,
      targetDistanceKm: data.targetDistanceKm.present
          ? data.targetDistanceKm.value
          : this.targetDistanceKm,
      targetDurationMin: data.targetDurationMin.present
          ? data.targetDurationMin.value
          : this.targetDurationMin,
      runWalkRatio: data.runWalkRatio.present
          ? data.runWalkRatio.value
          : this.runWalkRatio,
      targetPaceSecPerKm: data.targetPaceSecPerKm.present
          ? data.targetPaceSecPerKm.value
          : this.targetPaceSecPerKm,
      segmentsJson: data.segmentsJson.present
          ? data.segmentsJson.value
          : this.segmentsJson,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedRunRow(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('originalDate: $originalDate, ')
          ..write('weekIndex: $weekIndex, ')
          ..write('type: $type, ')
          ..write('targetDistanceKm: $targetDistanceKm, ')
          ..write('targetDurationMin: $targetDurationMin, ')
          ..write('runWalkRatio: $runWalkRatio, ')
          ..write('targetPaceSecPerKm: $targetPaceSecPerKm, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('status: $status, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    scheduledDate,
    originalDate,
    weekIndex,
    type,
    targetDistanceKm,
    targetDurationMin,
    runWalkRatio,
    targetPaceSecPerKm,
    segmentsJson,
    status,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedRunRow &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.scheduledDate == this.scheduledDate &&
          other.originalDate == this.originalDate &&
          other.weekIndex == this.weekIndex &&
          other.type == this.type &&
          other.targetDistanceKm == this.targetDistanceKm &&
          other.targetDurationMin == this.targetDurationMin &&
          other.runWalkRatio == this.runWalkRatio &&
          other.targetPaceSecPerKm == this.targetPaceSecPerKm &&
          other.segmentsJson == this.segmentsJson &&
          other.status == this.status &&
          other.notes == this.notes);
}

class PlannedRunsCompanion extends UpdateCompanion<PlannedRunRow> {
  final Value<int> id;
  final Value<int> planId;
  final Value<DateTime> scheduledDate;
  final Value<DateTime> originalDate;
  final Value<int> weekIndex;
  final Value<RunType> type;
  final Value<double?> targetDistanceKm;
  final Value<int?> targetDurationMin;
  final Value<String?> runWalkRatio;
  final Value<double?> targetPaceSecPerKm;
  final Value<String?> segmentsJson;
  final Value<RunStatus> status;
  final Value<String?> notes;
  const PlannedRunsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.originalDate = const Value.absent(),
    this.weekIndex = const Value.absent(),
    this.type = const Value.absent(),
    this.targetDistanceKm = const Value.absent(),
    this.targetDurationMin = const Value.absent(),
    this.runWalkRatio = const Value.absent(),
    this.targetPaceSecPerKm = const Value.absent(),
    this.segmentsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
  });
  PlannedRunsCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required DateTime scheduledDate,
    required DateTime originalDate,
    required int weekIndex,
    required RunType type,
    this.targetDistanceKm = const Value.absent(),
    this.targetDurationMin = const Value.absent(),
    this.runWalkRatio = const Value.absent(),
    this.targetPaceSecPerKm = const Value.absent(),
    this.segmentsJson = const Value.absent(),
    required RunStatus status,
    this.notes = const Value.absent(),
  }) : planId = Value(planId),
       scheduledDate = Value(scheduledDate),
       originalDate = Value(originalDate),
       weekIndex = Value(weekIndex),
       type = Value(type),
       status = Value(status);
  static Insertable<PlannedRunRow> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<DateTime>? scheduledDate,
    Expression<DateTime>? originalDate,
    Expression<int>? weekIndex,
    Expression<String>? type,
    Expression<double>? targetDistanceKm,
    Expression<int>? targetDurationMin,
    Expression<String>? runWalkRatio,
    Expression<double>? targetPaceSecPerKm,
    Expression<String>? segmentsJson,
    Expression<String>? status,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (originalDate != null) 'original_date': originalDate,
      if (weekIndex != null) 'week_index': weekIndex,
      if (type != null) 'type': type,
      if (targetDistanceKm != null) 'target_distance_km': targetDistanceKm,
      if (targetDurationMin != null) 'target_duration_min': targetDurationMin,
      if (runWalkRatio != null) 'run_walk_ratio': runWalkRatio,
      if (targetPaceSecPerKm != null)
        'target_pace_sec_per_km': targetPaceSecPerKm,
      if (segmentsJson != null) 'segments_json': segmentsJson,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
    });
  }

  PlannedRunsCompanion copyWith({
    Value<int>? id,
    Value<int>? planId,
    Value<DateTime>? scheduledDate,
    Value<DateTime>? originalDate,
    Value<int>? weekIndex,
    Value<RunType>? type,
    Value<double?>? targetDistanceKm,
    Value<int?>? targetDurationMin,
    Value<String?>? runWalkRatio,
    Value<double?>? targetPaceSecPerKm,
    Value<String?>? segmentsJson,
    Value<RunStatus>? status,
    Value<String?>? notes,
  }) {
    return PlannedRunsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      originalDate: originalDate ?? this.originalDate,
      weekIndex: weekIndex ?? this.weekIndex,
      type: type ?? this.type,
      targetDistanceKm: targetDistanceKm ?? this.targetDistanceKm,
      targetDurationMin: targetDurationMin ?? this.targetDurationMin,
      runWalkRatio: runWalkRatio ?? this.runWalkRatio,
      targetPaceSecPerKm: targetPaceSecPerKm ?? this.targetPaceSecPerKm,
      segmentsJson: segmentsJson ?? this.segmentsJson,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (originalDate.present) {
      map['original_date'] = Variable<DateTime>(originalDate.value);
    }
    if (weekIndex.present) {
      map['week_index'] = Variable<int>(weekIndex.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $PlannedRunsTable.$convertertype.toSql(type.value),
      );
    }
    if (targetDistanceKm.present) {
      map['target_distance_km'] = Variable<double>(targetDistanceKm.value);
    }
    if (targetDurationMin.present) {
      map['target_duration_min'] = Variable<int>(targetDurationMin.value);
    }
    if (runWalkRatio.present) {
      map['run_walk_ratio'] = Variable<String>(runWalkRatio.value);
    }
    if (targetPaceSecPerKm.present) {
      map['target_pace_sec_per_km'] = Variable<double>(
        targetPaceSecPerKm.value,
      );
    }
    if (segmentsJson.present) {
      map['segments_json'] = Variable<String>(segmentsJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PlannedRunsTable.$converterstatus.toSql(status.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedRunsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('originalDate: $originalDate, ')
          ..write('weekIndex: $weekIndex, ')
          ..write('type: $type, ')
          ..write('targetDistanceKm: $targetDistanceKm, ')
          ..write('targetDurationMin: $targetDurationMin, ')
          ..write('runWalkRatio: $runWalkRatio, ')
          ..write('targetPaceSecPerKm: $targetPaceSecPerKm, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('status: $status, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $CompletedRunsTable extends CompletedRuns
    with TableInfo<$CompletedRunsTable, CompletedRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletedRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _plannedRunIdMeta = const VerificationMeta(
    'plannedRunId',
  );
  @override
  late final GeneratedColumn<int> plannedRunId = GeneratedColumn<int>(
    'planned_run_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES planned_runs (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualDistanceKmMeta = const VerificationMeta(
    'actualDistanceKm',
  );
  @override
  late final GeneratedColumn<double> actualDistanceKm = GeneratedColumn<double>(
    'actual_distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgPaceSecPerKmMeta = const VerificationMeta(
    'avgPaceSecPerKm',
  );
  @override
  late final GeneratedColumn<double> avgPaceSecPerKm = GeneratedColumn<double>(
    'avg_pace_sec_per_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgHrMeta = const VerificationMeta('avgHr');
  @override
  late final GeneratedColumn<int> avgHr = GeneratedColumn<int>(
    'avg_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxHrMeta = const VerificationMeta('maxHr');
  @override
  late final GeneratedColumn<int> maxHr = GeneratedColumn<int>(
    'max_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
    'calories',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RunSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RunSource>($CompletedRunsTable.$convertersource);
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plannedRunId,
    date,
    actualDistanceKm,
    durationSec,
    avgPaceSecPerKm,
    avgHr,
    maxHr,
    calories,
    source,
    externalId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completed_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletedRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('planned_run_id')) {
      context.handle(
        _plannedRunIdMeta,
        plannedRunId.isAcceptableOrUnknown(
          data['planned_run_id']!,
          _plannedRunIdMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('actual_distance_km')) {
      context.handle(
        _actualDistanceKmMeta,
        actualDistanceKm.isAcceptableOrUnknown(
          data['actual_distance_km']!,
          _actualDistanceKmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualDistanceKmMeta);
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecMeta);
    }
    if (data.containsKey('avg_pace_sec_per_km')) {
      context.handle(
        _avgPaceSecPerKmMeta,
        avgPaceSecPerKm.isAcceptableOrUnknown(
          data['avg_pace_sec_per_km']!,
          _avgPaceSecPerKmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgPaceSecPerKmMeta);
    }
    if (data.containsKey('avg_hr')) {
      context.handle(
        _avgHrMeta,
        avgHr.isAcceptableOrUnknown(data['avg_hr']!, _avgHrMeta),
      );
    }
    if (data.containsKey('max_hr')) {
      context.handle(
        _maxHrMeta,
        maxHr.isAcceptableOrUnknown(data['max_hr']!, _maxHrMeta),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletedRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletedRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      plannedRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_run_id'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      actualDistanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}actual_distance_km'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      avgPaceSecPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_pace_sec_per_km'],
      )!,
      avgHr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_hr'],
      ),
      maxHr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_hr'],
      ),
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories'],
      ),
      source: $CompletedRunsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
    );
  }

  @override
  $CompletedRunsTable createAlias(String alias) {
    return $CompletedRunsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RunSource, String, String> $convertersource =
      const EnumNameConverter<RunSource>(RunSource.values);
}

class CompletedRunRow extends DataClass implements Insertable<CompletedRunRow> {
  final int id;
  final int? plannedRunId;
  final DateTime date;
  final double actualDistanceKm;
  final int durationSec;
  final double avgPaceSecPerKm;
  final int? avgHr;
  final int? maxHr;
  final double? calories;
  final RunSource source;

  /// Health Connect record id, for dedup. Unique when present.
  final String? externalId;
  const CompletedRunRow({
    required this.id,
    this.plannedRunId,
    required this.date,
    required this.actualDistanceKm,
    required this.durationSec,
    required this.avgPaceSecPerKm,
    this.avgHr,
    this.maxHr,
    this.calories,
    required this.source,
    this.externalId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || plannedRunId != null) {
      map['planned_run_id'] = Variable<int>(plannedRunId);
    }
    map['date'] = Variable<DateTime>(date);
    map['actual_distance_km'] = Variable<double>(actualDistanceKm);
    map['duration_sec'] = Variable<int>(durationSec);
    map['avg_pace_sec_per_km'] = Variable<double>(avgPaceSecPerKm);
    if (!nullToAbsent || avgHr != null) {
      map['avg_hr'] = Variable<int>(avgHr);
    }
    if (!nullToAbsent || maxHr != null) {
      map['max_hr'] = Variable<int>(maxHr);
    }
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<double>(calories);
    }
    {
      map['source'] = Variable<String>(
        $CompletedRunsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    return map;
  }

  CompletedRunsCompanion toCompanion(bool nullToAbsent) {
    return CompletedRunsCompanion(
      id: Value(id),
      plannedRunId: plannedRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedRunId),
      date: Value(date),
      actualDistanceKm: Value(actualDistanceKm),
      durationSec: Value(durationSec),
      avgPaceSecPerKm: Value(avgPaceSecPerKm),
      avgHr: avgHr == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHr),
      maxHr: maxHr == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHr),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      source: Value(source),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
    );
  }

  factory CompletedRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletedRunRow(
      id: serializer.fromJson<int>(json['id']),
      plannedRunId: serializer.fromJson<int?>(json['plannedRunId']),
      date: serializer.fromJson<DateTime>(json['date']),
      actualDistanceKm: serializer.fromJson<double>(json['actualDistanceKm']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      avgPaceSecPerKm: serializer.fromJson<double>(json['avgPaceSecPerKm']),
      avgHr: serializer.fromJson<int?>(json['avgHr']),
      maxHr: serializer.fromJson<int?>(json['maxHr']),
      calories: serializer.fromJson<double?>(json['calories']),
      source: $CompletedRunsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      externalId: serializer.fromJson<String?>(json['externalId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plannedRunId': serializer.toJson<int?>(plannedRunId),
      'date': serializer.toJson<DateTime>(date),
      'actualDistanceKm': serializer.toJson<double>(actualDistanceKm),
      'durationSec': serializer.toJson<int>(durationSec),
      'avgPaceSecPerKm': serializer.toJson<double>(avgPaceSecPerKm),
      'avgHr': serializer.toJson<int?>(avgHr),
      'maxHr': serializer.toJson<int?>(maxHr),
      'calories': serializer.toJson<double?>(calories),
      'source': serializer.toJson<String>(
        $CompletedRunsTable.$convertersource.toJson(source),
      ),
      'externalId': serializer.toJson<String?>(externalId),
    };
  }

  CompletedRunRow copyWith({
    int? id,
    Value<int?> plannedRunId = const Value.absent(),
    DateTime? date,
    double? actualDistanceKm,
    int? durationSec,
    double? avgPaceSecPerKm,
    Value<int?> avgHr = const Value.absent(),
    Value<int?> maxHr = const Value.absent(),
    Value<double?> calories = const Value.absent(),
    RunSource? source,
    Value<String?> externalId = const Value.absent(),
  }) => CompletedRunRow(
    id: id ?? this.id,
    plannedRunId: plannedRunId.present ? plannedRunId.value : this.plannedRunId,
    date: date ?? this.date,
    actualDistanceKm: actualDistanceKm ?? this.actualDistanceKm,
    durationSec: durationSec ?? this.durationSec,
    avgPaceSecPerKm: avgPaceSecPerKm ?? this.avgPaceSecPerKm,
    avgHr: avgHr.present ? avgHr.value : this.avgHr,
    maxHr: maxHr.present ? maxHr.value : this.maxHr,
    calories: calories.present ? calories.value : this.calories,
    source: source ?? this.source,
    externalId: externalId.present ? externalId.value : this.externalId,
  );
  CompletedRunRow copyWithCompanion(CompletedRunsCompanion data) {
    return CompletedRunRow(
      id: data.id.present ? data.id.value : this.id,
      plannedRunId: data.plannedRunId.present
          ? data.plannedRunId.value
          : this.plannedRunId,
      date: data.date.present ? data.date.value : this.date,
      actualDistanceKm: data.actualDistanceKm.present
          ? data.actualDistanceKm.value
          : this.actualDistanceKm,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      avgPaceSecPerKm: data.avgPaceSecPerKm.present
          ? data.avgPaceSecPerKm.value
          : this.avgPaceSecPerKm,
      avgHr: data.avgHr.present ? data.avgHr.value : this.avgHr,
      maxHr: data.maxHr.present ? data.maxHr.value : this.maxHr,
      calories: data.calories.present ? data.calories.value : this.calories,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletedRunRow(')
          ..write('id: $id, ')
          ..write('plannedRunId: $plannedRunId, ')
          ..write('date: $date, ')
          ..write('actualDistanceKm: $actualDistanceKm, ')
          ..write('durationSec: $durationSec, ')
          ..write('avgPaceSecPerKm: $avgPaceSecPerKm, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('calories: $calories, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plannedRunId,
    date,
    actualDistanceKm,
    durationSec,
    avgPaceSecPerKm,
    avgHr,
    maxHr,
    calories,
    source,
    externalId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletedRunRow &&
          other.id == this.id &&
          other.plannedRunId == this.plannedRunId &&
          other.date == this.date &&
          other.actualDistanceKm == this.actualDistanceKm &&
          other.durationSec == this.durationSec &&
          other.avgPaceSecPerKm == this.avgPaceSecPerKm &&
          other.avgHr == this.avgHr &&
          other.maxHr == this.maxHr &&
          other.calories == this.calories &&
          other.source == this.source &&
          other.externalId == this.externalId);
}

class CompletedRunsCompanion extends UpdateCompanion<CompletedRunRow> {
  final Value<int> id;
  final Value<int?> plannedRunId;
  final Value<DateTime> date;
  final Value<double> actualDistanceKm;
  final Value<int> durationSec;
  final Value<double> avgPaceSecPerKm;
  final Value<int?> avgHr;
  final Value<int?> maxHr;
  final Value<double?> calories;
  final Value<RunSource> source;
  final Value<String?> externalId;
  const CompletedRunsCompanion({
    this.id = const Value.absent(),
    this.plannedRunId = const Value.absent(),
    this.date = const Value.absent(),
    this.actualDistanceKm = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.avgPaceSecPerKm = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.calories = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
  });
  CompletedRunsCompanion.insert({
    this.id = const Value.absent(),
    this.plannedRunId = const Value.absent(),
    required DateTime date,
    required double actualDistanceKm,
    required int durationSec,
    required double avgPaceSecPerKm,
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.calories = const Value.absent(),
    required RunSource source,
    this.externalId = const Value.absent(),
  }) : date = Value(date),
       actualDistanceKm = Value(actualDistanceKm),
       durationSec = Value(durationSec),
       avgPaceSecPerKm = Value(avgPaceSecPerKm),
       source = Value(source);
  static Insertable<CompletedRunRow> custom({
    Expression<int>? id,
    Expression<int>? plannedRunId,
    Expression<DateTime>? date,
    Expression<double>? actualDistanceKm,
    Expression<int>? durationSec,
    Expression<double>? avgPaceSecPerKm,
    Expression<int>? avgHr,
    Expression<int>? maxHr,
    Expression<double>? calories,
    Expression<String>? source,
    Expression<String>? externalId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plannedRunId != null) 'planned_run_id': plannedRunId,
      if (date != null) 'date': date,
      if (actualDistanceKm != null) 'actual_distance_km': actualDistanceKm,
      if (durationSec != null) 'duration_sec': durationSec,
      if (avgPaceSecPerKm != null) 'avg_pace_sec_per_km': avgPaceSecPerKm,
      if (avgHr != null) 'avg_hr': avgHr,
      if (maxHr != null) 'max_hr': maxHr,
      if (calories != null) 'calories': calories,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
    });
  }

  CompletedRunsCompanion copyWith({
    Value<int>? id,
    Value<int?>? plannedRunId,
    Value<DateTime>? date,
    Value<double>? actualDistanceKm,
    Value<int>? durationSec,
    Value<double>? avgPaceSecPerKm,
    Value<int?>? avgHr,
    Value<int?>? maxHr,
    Value<double?>? calories,
    Value<RunSource>? source,
    Value<String?>? externalId,
  }) {
    return CompletedRunsCompanion(
      id: id ?? this.id,
      plannedRunId: plannedRunId ?? this.plannedRunId,
      date: date ?? this.date,
      actualDistanceKm: actualDistanceKm ?? this.actualDistanceKm,
      durationSec: durationSec ?? this.durationSec,
      avgPaceSecPerKm: avgPaceSecPerKm ?? this.avgPaceSecPerKm,
      avgHr: avgHr ?? this.avgHr,
      maxHr: maxHr ?? this.maxHr,
      calories: calories ?? this.calories,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plannedRunId.present) {
      map['planned_run_id'] = Variable<int>(plannedRunId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (actualDistanceKm.present) {
      map['actual_distance_km'] = Variable<double>(actualDistanceKm.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (avgPaceSecPerKm.present) {
      map['avg_pace_sec_per_km'] = Variable<double>(avgPaceSecPerKm.value);
    }
    if (avgHr.present) {
      map['avg_hr'] = Variable<int>(avgHr.value);
    }
    if (maxHr.present) {
      map['max_hr'] = Variable<int>(maxHr.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $CompletedRunsTable.$convertersource.toSql(source.value),
      );
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletedRunsCompanion(')
          ..write('id: $id, ')
          ..write('plannedRunId: $plannedRunId, ')
          ..write('date: $date, ')
          ..write('actualDistanceKm: $actualDistanceKm, ')
          ..write('durationSec: $durationSec, ')
          ..write('avgPaceSecPerKm: $avgPaceSecPerKm, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('calories: $calories, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId')
          ..write(')'))
        .toString();
  }
}

class $SettingsRowsTable extends SettingsRows
    with TableInfo<$SettingsRowsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<UnitSystem, String> units =
      GeneratedColumn<String>(
        'units',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<UnitSystem>($SettingsRowsTable.$converterunits);
  static const VerificationMeta _reminderMorningMinutesMeta =
      const VerificationMeta('reminderMorningMinutes');
  @override
  late final GeneratedColumn<int> reminderMorningMinutes = GeneratedColumn<int>(
    'reminder_morning_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderEveningMinutesMeta =
      const VerificationMeta('reminderEveningMinutes');
  @override
  late final GeneratedColumn<int> reminderEveningMinutes = GeneratedColumn<int>(
    'reminder_evening_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Aggressiveness, String>
  adaptivityAggressiveness =
      GeneratedColumn<String>(
        'adaptivity_aggressiveness',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Aggressiveness>(
        $SettingsRowsTable.$converteradaptivityAggressiveness,
      );
  static const VerificationMeta _catchupWindowDaysMeta = const VerificationMeta(
    'catchupWindowDays',
  );
  @override
  late final GeneratedColumn<int> catchupWindowDays = GeneratedColumn<int>(
    'catchup_window_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longRunCatchupWindowDaysMeta =
      const VerificationMeta('longRunCatchupWindowDays');
  @override
  late final GeneratedColumn<int> longRunCatchupWindowDays =
      GeneratedColumn<int>(
        'long_run_catchup_window_days',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cloudBackupEnabledMeta =
      const VerificationMeta('cloudBackupEnabled');
  @override
  late final GeneratedColumn<bool> cloudBackupEnabled = GeneratedColumn<bool>(
    'cloud_backup_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cloud_backup_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    units,
    reminderMorningMinutes,
    reminderEveningMinutes,
    adaptivityAggressiveness,
    catchupWindowDays,
    longRunCatchupWindowDays,
    cloudBackupEnabled,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reminder_morning_minutes')) {
      context.handle(
        _reminderMorningMinutesMeta,
        reminderMorningMinutes.isAcceptableOrUnknown(
          data['reminder_morning_minutes']!,
          _reminderMorningMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderMorningMinutesMeta);
    }
    if (data.containsKey('reminder_evening_minutes')) {
      context.handle(
        _reminderEveningMinutesMeta,
        reminderEveningMinutes.isAcceptableOrUnknown(
          data['reminder_evening_minutes']!,
          _reminderEveningMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderEveningMinutesMeta);
    }
    if (data.containsKey('catchup_window_days')) {
      context.handle(
        _catchupWindowDaysMeta,
        catchupWindowDays.isAcceptableOrUnknown(
          data['catchup_window_days']!,
          _catchupWindowDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catchupWindowDaysMeta);
    }
    if (data.containsKey('long_run_catchup_window_days')) {
      context.handle(
        _longRunCatchupWindowDaysMeta,
        longRunCatchupWindowDays.isAcceptableOrUnknown(
          data['long_run_catchup_window_days']!,
          _longRunCatchupWindowDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_longRunCatchupWindowDaysMeta);
    }
    if (data.containsKey('cloud_backup_enabled')) {
      context.handle(
        _cloudBackupEnabledMeta,
        cloudBackupEnabled.isAcceptableOrUnknown(
          data['cloud_backup_enabled']!,
          _cloudBackupEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cloudBackupEnabledMeta);
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      units: $SettingsRowsTable.$converterunits.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}units'],
        )!,
      ),
      reminderMorningMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_morning_minutes'],
      )!,
      reminderEveningMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_evening_minutes'],
      )!,
      adaptivityAggressiveness: $SettingsRowsTable
          .$converteradaptivityAggressiveness
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}adaptivity_aggressiveness'],
            )!,
          ),
      catchupWindowDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catchup_window_days'],
      )!,
      longRunCatchupWindowDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}long_run_catchup_window_days'],
      )!,
      cloudBackupEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cloud_backup_enabled'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $SettingsRowsTable createAlias(String alias) {
    return $SettingsRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UnitSystem, String, String> $converterunits =
      const EnumNameConverter<UnitSystem>(UnitSystem.values);
  static JsonTypeConverter2<Aggressiveness, String, String>
  $converteradaptivityAggressiveness = const EnumNameConverter<Aggressiveness>(
    Aggressiveness.values,
  );
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final UnitSystem units;
  final int reminderMorningMinutes;
  final int reminderEveningMinutes;
  final Aggressiveness adaptivityAggressiveness;
  final int catchupWindowDays;
  final int longRunCatchupWindowDays;
  final bool cloudBackupEnabled;

  /// Last successful Health Connect sync (null until first sync).
  final DateTime? lastSyncAt;
  const SettingsRow({
    required this.id,
    required this.units,
    required this.reminderMorningMinutes,
    required this.reminderEveningMinutes,
    required this.adaptivityAggressiveness,
    required this.catchupWindowDays,
    required this.longRunCatchupWindowDays,
    required this.cloudBackupEnabled,
    this.lastSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['units'] = Variable<String>(
        $SettingsRowsTable.$converterunits.toSql(units),
      );
    }
    map['reminder_morning_minutes'] = Variable<int>(reminderMorningMinutes);
    map['reminder_evening_minutes'] = Variable<int>(reminderEveningMinutes);
    {
      map['adaptivity_aggressiveness'] = Variable<String>(
        $SettingsRowsTable.$converteradaptivityAggressiveness.toSql(
          adaptivityAggressiveness,
        ),
      );
    }
    map['catchup_window_days'] = Variable<int>(catchupWindowDays);
    map['long_run_catchup_window_days'] = Variable<int>(
      longRunCatchupWindowDays,
    );
    map['cloud_backup_enabled'] = Variable<bool>(cloudBackupEnabled);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  SettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRowsCompanion(
      id: Value(id),
      units: Value(units),
      reminderMorningMinutes: Value(reminderMorningMinutes),
      reminderEveningMinutes: Value(reminderEveningMinutes),
      adaptivityAggressiveness: Value(adaptivityAggressiveness),
      catchupWindowDays: Value(catchupWindowDays),
      longRunCatchupWindowDays: Value(longRunCatchupWindowDays),
      cloudBackupEnabled: Value(cloudBackupEnabled),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      units: $SettingsRowsTable.$converterunits.fromJson(
        serializer.fromJson<String>(json['units']),
      ),
      reminderMorningMinutes: serializer.fromJson<int>(
        json['reminderMorningMinutes'],
      ),
      reminderEveningMinutes: serializer.fromJson<int>(
        json['reminderEveningMinutes'],
      ),
      adaptivityAggressiveness: $SettingsRowsTable
          .$converteradaptivityAggressiveness
          .fromJson(
            serializer.fromJson<String>(json['adaptivityAggressiveness']),
          ),
      catchupWindowDays: serializer.fromJson<int>(json['catchupWindowDays']),
      longRunCatchupWindowDays: serializer.fromJson<int>(
        json['longRunCatchupWindowDays'],
      ),
      cloudBackupEnabled: serializer.fromJson<bool>(json['cloudBackupEnabled']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'units': serializer.toJson<String>(
        $SettingsRowsTable.$converterunits.toJson(units),
      ),
      'reminderMorningMinutes': serializer.toJson<int>(reminderMorningMinutes),
      'reminderEveningMinutes': serializer.toJson<int>(reminderEveningMinutes),
      'adaptivityAggressiveness': serializer.toJson<String>(
        $SettingsRowsTable.$converteradaptivityAggressiveness.toJson(
          adaptivityAggressiveness,
        ),
      ),
      'catchupWindowDays': serializer.toJson<int>(catchupWindowDays),
      'longRunCatchupWindowDays': serializer.toJson<int>(
        longRunCatchupWindowDays,
      ),
      'cloudBackupEnabled': serializer.toJson<bool>(cloudBackupEnabled),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  SettingsRow copyWith({
    int? id,
    UnitSystem? units,
    int? reminderMorningMinutes,
    int? reminderEveningMinutes,
    Aggressiveness? adaptivityAggressiveness,
    int? catchupWindowDays,
    int? longRunCatchupWindowDays,
    bool? cloudBackupEnabled,
    Value<DateTime?> lastSyncAt = const Value.absent(),
  }) => SettingsRow(
    id: id ?? this.id,
    units: units ?? this.units,
    reminderMorningMinutes:
        reminderMorningMinutes ?? this.reminderMorningMinutes,
    reminderEveningMinutes:
        reminderEveningMinutes ?? this.reminderEveningMinutes,
    adaptivityAggressiveness:
        adaptivityAggressiveness ?? this.adaptivityAggressiveness,
    catchupWindowDays: catchupWindowDays ?? this.catchupWindowDays,
    longRunCatchupWindowDays:
        longRunCatchupWindowDays ?? this.longRunCatchupWindowDays,
    cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  SettingsRow copyWithCompanion(SettingsRowsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      units: data.units.present ? data.units.value : this.units,
      reminderMorningMinutes: data.reminderMorningMinutes.present
          ? data.reminderMorningMinutes.value
          : this.reminderMorningMinutes,
      reminderEveningMinutes: data.reminderEveningMinutes.present
          ? data.reminderEveningMinutes.value
          : this.reminderEveningMinutes,
      adaptivityAggressiveness: data.adaptivityAggressiveness.present
          ? data.adaptivityAggressiveness.value
          : this.adaptivityAggressiveness,
      catchupWindowDays: data.catchupWindowDays.present
          ? data.catchupWindowDays.value
          : this.catchupWindowDays,
      longRunCatchupWindowDays: data.longRunCatchupWindowDays.present
          ? data.longRunCatchupWindowDays.value
          : this.longRunCatchupWindowDays,
      cloudBackupEnabled: data.cloudBackupEnabled.present
          ? data.cloudBackupEnabled.value
          : this.cloudBackupEnabled,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('units: $units, ')
          ..write('reminderMorningMinutes: $reminderMorningMinutes, ')
          ..write('reminderEveningMinutes: $reminderEveningMinutes, ')
          ..write('adaptivityAggressiveness: $adaptivityAggressiveness, ')
          ..write('catchupWindowDays: $catchupWindowDays, ')
          ..write('longRunCatchupWindowDays: $longRunCatchupWindowDays, ')
          ..write('cloudBackupEnabled: $cloudBackupEnabled, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    units,
    reminderMorningMinutes,
    reminderEveningMinutes,
    adaptivityAggressiveness,
    catchupWindowDays,
    longRunCatchupWindowDays,
    cloudBackupEnabled,
    lastSyncAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.units == this.units &&
          other.reminderMorningMinutes == this.reminderMorningMinutes &&
          other.reminderEveningMinutes == this.reminderEveningMinutes &&
          other.adaptivityAggressiveness == this.adaptivityAggressiveness &&
          other.catchupWindowDays == this.catchupWindowDays &&
          other.longRunCatchupWindowDays == this.longRunCatchupWindowDays &&
          other.cloudBackupEnabled == this.cloudBackupEnabled &&
          other.lastSyncAt == this.lastSyncAt);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<UnitSystem> units;
  final Value<int> reminderMorningMinutes;
  final Value<int> reminderEveningMinutes;
  final Value<Aggressiveness> adaptivityAggressiveness;
  final Value<int> catchupWindowDays;
  final Value<int> longRunCatchupWindowDays;
  final Value<bool> cloudBackupEnabled;
  final Value<DateTime?> lastSyncAt;
  const SettingsRowsCompanion({
    this.id = const Value.absent(),
    this.units = const Value.absent(),
    this.reminderMorningMinutes = const Value.absent(),
    this.reminderEveningMinutes = const Value.absent(),
    this.adaptivityAggressiveness = const Value.absent(),
    this.catchupWindowDays = const Value.absent(),
    this.longRunCatchupWindowDays = const Value.absent(),
    this.cloudBackupEnabled = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    required UnitSystem units,
    required int reminderMorningMinutes,
    required int reminderEveningMinutes,
    required Aggressiveness adaptivityAggressiveness,
    required int catchupWindowDays,
    required int longRunCatchupWindowDays,
    required bool cloudBackupEnabled,
    this.lastSyncAt = const Value.absent(),
  }) : units = Value(units),
       reminderMorningMinutes = Value(reminderMorningMinutes),
       reminderEveningMinutes = Value(reminderEveningMinutes),
       adaptivityAggressiveness = Value(adaptivityAggressiveness),
       catchupWindowDays = Value(catchupWindowDays),
       longRunCatchupWindowDays = Value(longRunCatchupWindowDays),
       cloudBackupEnabled = Value(cloudBackupEnabled);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? units,
    Expression<int>? reminderMorningMinutes,
    Expression<int>? reminderEveningMinutes,
    Expression<String>? adaptivityAggressiveness,
    Expression<int>? catchupWindowDays,
    Expression<int>? longRunCatchupWindowDays,
    Expression<bool>? cloudBackupEnabled,
    Expression<DateTime>? lastSyncAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (units != null) 'units': units,
      if (reminderMorningMinutes != null)
        'reminder_morning_minutes': reminderMorningMinutes,
      if (reminderEveningMinutes != null)
        'reminder_evening_minutes': reminderEveningMinutes,
      if (adaptivityAggressiveness != null)
        'adaptivity_aggressiveness': adaptivityAggressiveness,
      if (catchupWindowDays != null) 'catchup_window_days': catchupWindowDays,
      if (longRunCatchupWindowDays != null)
        'long_run_catchup_window_days': longRunCatchupWindowDays,
      if (cloudBackupEnabled != null)
        'cloud_backup_enabled': cloudBackupEnabled,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<UnitSystem>? units,
    Value<int>? reminderMorningMinutes,
    Value<int>? reminderEveningMinutes,
    Value<Aggressiveness>? adaptivityAggressiveness,
    Value<int>? catchupWindowDays,
    Value<int>? longRunCatchupWindowDays,
    Value<bool>? cloudBackupEnabled,
    Value<DateTime?>? lastSyncAt,
  }) {
    return SettingsRowsCompanion(
      id: id ?? this.id,
      units: units ?? this.units,
      reminderMorningMinutes:
          reminderMorningMinutes ?? this.reminderMorningMinutes,
      reminderEveningMinutes:
          reminderEveningMinutes ?? this.reminderEveningMinutes,
      adaptivityAggressiveness:
          adaptivityAggressiveness ?? this.adaptivityAggressiveness,
      catchupWindowDays: catchupWindowDays ?? this.catchupWindowDays,
      longRunCatchupWindowDays:
          longRunCatchupWindowDays ?? this.longRunCatchupWindowDays,
      cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (units.present) {
      map['units'] = Variable<String>(
        $SettingsRowsTable.$converterunits.toSql(units.value),
      );
    }
    if (reminderMorningMinutes.present) {
      map['reminder_morning_minutes'] = Variable<int>(
        reminderMorningMinutes.value,
      );
    }
    if (reminderEveningMinutes.present) {
      map['reminder_evening_minutes'] = Variable<int>(
        reminderEveningMinutes.value,
      );
    }
    if (adaptivityAggressiveness.present) {
      map['adaptivity_aggressiveness'] = Variable<String>(
        $SettingsRowsTable.$converteradaptivityAggressiveness.toSql(
          adaptivityAggressiveness.value,
        ),
      );
    }
    if (catchupWindowDays.present) {
      map['catchup_window_days'] = Variable<int>(catchupWindowDays.value);
    }
    if (longRunCatchupWindowDays.present) {
      map['long_run_catchup_window_days'] = Variable<int>(
        longRunCatchupWindowDays.value,
      );
    }
    if (cloudBackupEnabled.present) {
      map['cloud_backup_enabled'] = Variable<bool>(cloudBackupEnabled.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('units: $units, ')
          ..write('reminderMorningMinutes: $reminderMorningMinutes, ')
          ..write('reminderEveningMinutes: $reminderEveningMinutes, ')
          ..write('adaptivityAggressiveness: $adaptivityAggressiveness, ')
          ..write('catchupWindowDays: $catchupWindowDays, ')
          ..write('longRunCatchupWindowDays: $longRunCatchupWindowDays, ')
          ..write('cloudBackupEnabled: $cloudBackupEnabled, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TrainingPlansTable trainingPlans = $TrainingPlansTable(this);
  late final $PlannedRunsTable plannedRuns = $PlannedRunsTable(this);
  late final $CompletedRunsTable completedRuns = $CompletedRunsTable(this);
  late final $SettingsRowsTable settingsRows = $SettingsRowsTable(this);
  late final PlanDao planDao = PlanDao(this as AppDatabase);
  late final RunsDao runsDao = RunsDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trainingPlans,
    plannedRuns,
    completedRuns,
    settingsRows,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'training_plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('planned_runs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'planned_runs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('completed_runs', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$TrainingPlansTableCreateCompanionBuilder =
    TrainingPlansCompanion Function({
      Value<int> id,
      required String name,
      required DateTime raceDate,
      required double raceDistanceKm,
      required DateTime startDate,
      required int longRunDay,
      required PlanStatus status,
      Value<int> taperWeeks,
      required DateTime createdAt,
    });
typedef $$TrainingPlansTableUpdateCompanionBuilder =
    TrainingPlansCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> raceDate,
      Value<double> raceDistanceKm,
      Value<DateTime> startDate,
      Value<int> longRunDay,
      Value<PlanStatus> status,
      Value<int> taperWeeks,
      Value<DateTime> createdAt,
    });

final class $$TrainingPlansTableReferences
    extends
        BaseReferences<_$AppDatabase, $TrainingPlansTable, TrainingPlanRow> {
  $$TrainingPlansTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PlannedRunsTable, List<PlannedRunRow>>
  _plannedRunsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plannedRuns,
    aliasName: 'training_plans__id__planned_runs__plan_id',
  );

  $$PlannedRunsTableProcessedTableManager get plannedRunsRefs {
    final manager = $$PlannedRunsTableTableManager(
      $_db,
      $_db.plannedRuns,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_plannedRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TrainingPlansTableFilterComposer
    extends Composer<_$AppDatabase, $TrainingPlansTable> {
  $$TrainingPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get raceDate => $composableBuilder(
    column: $table.raceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get raceDistanceKm => $composableBuilder(
    column: $table.raceDistanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longRunDay => $composableBuilder(
    column: $table.longRunDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlanStatus, PlanStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get taperWeeks => $composableBuilder(
    column: $table.taperWeeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> plannedRunsRefs(
    Expression<bool> Function($$PlannedRunsTableFilterComposer f) f,
  ) {
    final $$PlannedRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedRuns,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedRunsTableFilterComposer(
            $db: $db,
            $table: $db.plannedRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TrainingPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainingPlansTable> {
  $$TrainingPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get raceDate => $composableBuilder(
    column: $table.raceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get raceDistanceKm => $composableBuilder(
    column: $table.raceDistanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longRunDay => $composableBuilder(
    column: $table.longRunDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taperWeeks => $composableBuilder(
    column: $table.taperWeeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrainingPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainingPlansTable> {
  $$TrainingPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get raceDate =>
      $composableBuilder(column: $table.raceDate, builder: (column) => column);

  GeneratedColumn<double> get raceDistanceKm => $composableBuilder(
    column: $table.raceDistanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get longRunDay => $composableBuilder(
    column: $table.longRunDay,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PlanStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get taperWeeks => $composableBuilder(
    column: $table.taperWeeks,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> plannedRunsRefs<T extends Object>(
    Expression<T> Function($$PlannedRunsTableAnnotationComposer a) f,
  ) {
    final $$PlannedRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedRuns,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TrainingPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainingPlansTable,
          TrainingPlanRow,
          $$TrainingPlansTableFilterComposer,
          $$TrainingPlansTableOrderingComposer,
          $$TrainingPlansTableAnnotationComposer,
          $$TrainingPlansTableCreateCompanionBuilder,
          $$TrainingPlansTableUpdateCompanionBuilder,
          (TrainingPlanRow, $$TrainingPlansTableReferences),
          TrainingPlanRow,
          PrefetchHooks Function({bool plannedRunsRefs})
        > {
  $$TrainingPlansTableTableManager(_$AppDatabase db, $TrainingPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainingPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainingPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainingPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> raceDate = const Value.absent(),
                Value<double> raceDistanceKm = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<int> longRunDay = const Value.absent(),
                Value<PlanStatus> status = const Value.absent(),
                Value<int> taperWeeks = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TrainingPlansCompanion(
                id: id,
                name: name,
                raceDate: raceDate,
                raceDistanceKm: raceDistanceKm,
                startDate: startDate,
                longRunDay: longRunDay,
                status: status,
                taperWeeks: taperWeeks,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime raceDate,
                required double raceDistanceKm,
                required DateTime startDate,
                required int longRunDay,
                required PlanStatus status,
                Value<int> taperWeeks = const Value.absent(),
                required DateTime createdAt,
              }) => TrainingPlansCompanion.insert(
                id: id,
                name: name,
                raceDate: raceDate,
                raceDistanceKm: raceDistanceKm,
                startDate: startDate,
                longRunDay: longRunDay,
                status: status,
                taperWeeks: taperWeeks,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrainingPlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({plannedRunsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (plannedRunsRefs) db.plannedRuns],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (plannedRunsRefs)
                    await $_getPrefetchedData<
                      TrainingPlanRow,
                      $TrainingPlansTable,
                      PlannedRunRow
                    >(
                      currentTable: table,
                      referencedTable: $$TrainingPlansTableReferences
                          ._plannedRunsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TrainingPlansTableReferences(
                            db,
                            table,
                            p0,
                          ).plannedRunsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.planId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TrainingPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainingPlansTable,
      TrainingPlanRow,
      $$TrainingPlansTableFilterComposer,
      $$TrainingPlansTableOrderingComposer,
      $$TrainingPlansTableAnnotationComposer,
      $$TrainingPlansTableCreateCompanionBuilder,
      $$TrainingPlansTableUpdateCompanionBuilder,
      (TrainingPlanRow, $$TrainingPlansTableReferences),
      TrainingPlanRow,
      PrefetchHooks Function({bool plannedRunsRefs})
    >;
typedef $$PlannedRunsTableCreateCompanionBuilder =
    PlannedRunsCompanion Function({
      Value<int> id,
      required int planId,
      required DateTime scheduledDate,
      required DateTime originalDate,
      required int weekIndex,
      required RunType type,
      Value<double?> targetDistanceKm,
      Value<int?> targetDurationMin,
      Value<String?> runWalkRatio,
      Value<double?> targetPaceSecPerKm,
      Value<String?> segmentsJson,
      required RunStatus status,
      Value<String?> notes,
    });
typedef $$PlannedRunsTableUpdateCompanionBuilder =
    PlannedRunsCompanion Function({
      Value<int> id,
      Value<int> planId,
      Value<DateTime> scheduledDate,
      Value<DateTime> originalDate,
      Value<int> weekIndex,
      Value<RunType> type,
      Value<double?> targetDistanceKm,
      Value<int?> targetDurationMin,
      Value<String?> runWalkRatio,
      Value<double?> targetPaceSecPerKm,
      Value<String?> segmentsJson,
      Value<RunStatus> status,
      Value<String?> notes,
    });

final class $$PlannedRunsTableReferences
    extends BaseReferences<_$AppDatabase, $PlannedRunsTable, PlannedRunRow> {
  $$PlannedRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TrainingPlansTable _planIdTable(_$AppDatabase db) =>
      db.trainingPlans.createAlias('planned_runs__plan_id__training_plans__id');

  $$TrainingPlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<int>('plan_id')!;

    final manager = $$TrainingPlansTableTableManager(
      $_db,
      $_db.trainingPlans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CompletedRunsTable, List<CompletedRunRow>>
  _completedRunsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.completedRuns,
    aliasName: 'planned_runs__id__completed_runs__planned_run_id',
  );

  $$CompletedRunsTableProcessedTableManager get completedRunsRefs {
    final manager = $$CompletedRunsTableTableManager(
      $_db,
      $_db.completedRuns,
    ).filter((f) => f.plannedRunId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_completedRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlannedRunsTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedRunsTable> {
  $$PlannedRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekIndex => $composableBuilder(
    column: $table.weekIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RunType, RunType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get targetDistanceKm => $composableBuilder(
    column: $table.targetDistanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDurationMin => $composableBuilder(
    column: $table.targetDurationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runWalkRatio => $composableBuilder(
    column: $table.runWalkRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetPaceSecPerKm => $composableBuilder(
    column: $table.targetPaceSecPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RunStatus, RunStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$TrainingPlansTableFilterComposer get planId {
    final $$TrainingPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.trainingPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingPlansTableFilterComposer(
            $db: $db,
            $table: $db.trainingPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> completedRunsRefs(
    Expression<bool> Function($$CompletedRunsTableFilterComposer f) f,
  ) {
    final $$CompletedRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedRuns,
      getReferencedColumn: (t) => t.plannedRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedRunsTableFilterComposer(
            $db: $db,
            $table: $db.completedRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedRunsTable> {
  $$PlannedRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekIndex => $composableBuilder(
    column: $table.weekIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetDistanceKm => $composableBuilder(
    column: $table.targetDistanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDurationMin => $composableBuilder(
    column: $table.targetDurationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runWalkRatio => $composableBuilder(
    column: $table.runWalkRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetPaceSecPerKm => $composableBuilder(
    column: $table.targetPaceSecPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$TrainingPlansTableOrderingComposer get planId {
    final $$TrainingPlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.trainingPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingPlansTableOrderingComposer(
            $db: $db,
            $table: $db.trainingPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedRunsTable> {
  $$PlannedRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weekIndex =>
      $composableBuilder(column: $table.weekIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RunType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get targetDistanceKm => $composableBuilder(
    column: $table.targetDistanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetDurationMin => $composableBuilder(
    column: $table.targetDurationMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get runWalkRatio => $composableBuilder(
    column: $table.runWalkRatio,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetPaceSecPerKm => $composableBuilder(
    column: $table.targetPaceSecPerKm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RunStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$TrainingPlansTableAnnotationComposer get planId {
    final $$TrainingPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.trainingPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrainingPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.trainingPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> completedRunsRefs<T extends Object>(
    Expression<T> Function($$CompletedRunsTableAnnotationComposer a) f,
  ) {
    final $$CompletedRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedRuns,
      getReferencedColumn: (t) => t.plannedRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.completedRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedRunsTable,
          PlannedRunRow,
          $$PlannedRunsTableFilterComposer,
          $$PlannedRunsTableOrderingComposer,
          $$PlannedRunsTableAnnotationComposer,
          $$PlannedRunsTableCreateCompanionBuilder,
          $$PlannedRunsTableUpdateCompanionBuilder,
          (PlannedRunRow, $$PlannedRunsTableReferences),
          PlannedRunRow,
          PrefetchHooks Function({bool planId, bool completedRunsRefs})
        > {
  $$PlannedRunsTableTableManager(_$AppDatabase db, $PlannedRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<DateTime> scheduledDate = const Value.absent(),
                Value<DateTime> originalDate = const Value.absent(),
                Value<int> weekIndex = const Value.absent(),
                Value<RunType> type = const Value.absent(),
                Value<double?> targetDistanceKm = const Value.absent(),
                Value<int?> targetDurationMin = const Value.absent(),
                Value<String?> runWalkRatio = const Value.absent(),
                Value<double?> targetPaceSecPerKm = const Value.absent(),
                Value<String?> segmentsJson = const Value.absent(),
                Value<RunStatus> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => PlannedRunsCompanion(
                id: id,
                planId: planId,
                scheduledDate: scheduledDate,
                originalDate: originalDate,
                weekIndex: weekIndex,
                type: type,
                targetDistanceKm: targetDistanceKm,
                targetDurationMin: targetDurationMin,
                runWalkRatio: runWalkRatio,
                targetPaceSecPerKm: targetPaceSecPerKm,
                segmentsJson: segmentsJson,
                status: status,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planId,
                required DateTime scheduledDate,
                required DateTime originalDate,
                required int weekIndex,
                required RunType type,
                Value<double?> targetDistanceKm = const Value.absent(),
                Value<int?> targetDurationMin = const Value.absent(),
                Value<String?> runWalkRatio = const Value.absent(),
                Value<double?> targetPaceSecPerKm = const Value.absent(),
                Value<String?> segmentsJson = const Value.absent(),
                required RunStatus status,
                Value<String?> notes = const Value.absent(),
              }) => PlannedRunsCompanion.insert(
                id: id,
                planId: planId,
                scheduledDate: scheduledDate,
                originalDate: originalDate,
                weekIndex: weekIndex,
                type: type,
                targetDistanceKm: targetDistanceKm,
                targetDurationMin: targetDurationMin,
                runWalkRatio: runWalkRatio,
                targetPaceSecPerKm: targetPaceSecPerKm,
                segmentsJson: segmentsJson,
                status: status,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlannedRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false, completedRunsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (completedRunsRefs) db.completedRuns,
              ],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.planId,
                                referencedTable: $$PlannedRunsTableReferences
                                    ._planIdTable(db),
                                referencedColumn: $$PlannedRunsTableReferences
                                    ._planIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (completedRunsRefs)
                    await $_getPrefetchedData<
                      PlannedRunRow,
                      $PlannedRunsTable,
                      CompletedRunRow
                    >(
                      currentTable: table,
                      referencedTable: $$PlannedRunsTableReferences
                          ._completedRunsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlannedRunsTableReferences(
                            db,
                            table,
                            p0,
                          ).completedRunsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.plannedRunId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlannedRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedRunsTable,
      PlannedRunRow,
      $$PlannedRunsTableFilterComposer,
      $$PlannedRunsTableOrderingComposer,
      $$PlannedRunsTableAnnotationComposer,
      $$PlannedRunsTableCreateCompanionBuilder,
      $$PlannedRunsTableUpdateCompanionBuilder,
      (PlannedRunRow, $$PlannedRunsTableReferences),
      PlannedRunRow,
      PrefetchHooks Function({bool planId, bool completedRunsRefs})
    >;
typedef $$CompletedRunsTableCreateCompanionBuilder =
    CompletedRunsCompanion Function({
      Value<int> id,
      Value<int?> plannedRunId,
      required DateTime date,
      required double actualDistanceKm,
      required int durationSec,
      required double avgPaceSecPerKm,
      Value<int?> avgHr,
      Value<int?> maxHr,
      Value<double?> calories,
      required RunSource source,
      Value<String?> externalId,
    });
typedef $$CompletedRunsTableUpdateCompanionBuilder =
    CompletedRunsCompanion Function({
      Value<int> id,
      Value<int?> plannedRunId,
      Value<DateTime> date,
      Value<double> actualDistanceKm,
      Value<int> durationSec,
      Value<double> avgPaceSecPerKm,
      Value<int?> avgHr,
      Value<int?> maxHr,
      Value<double?> calories,
      Value<RunSource> source,
      Value<String?> externalId,
    });

final class $$CompletedRunsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CompletedRunsTable, CompletedRunRow> {
  $$CompletedRunsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlannedRunsTable _plannedRunIdTable(_$AppDatabase db) => db
      .plannedRuns
      .createAlias('completed_runs__planned_run_id__planned_runs__id');

  $$PlannedRunsTableProcessedTableManager? get plannedRunId {
    final $_column = $_itemColumn<int>('planned_run_id');
    if ($_column == null) return null;
    final manager = $$PlannedRunsTableTableManager(
      $_db,
      $_db.plannedRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plannedRunIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CompletedRunsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletedRunsTable> {
  $$CompletedRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get actualDistanceKm => $composableBuilder(
    column: $table.actualDistanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgPaceSecPerKm => $composableBuilder(
    column: $table.avgPaceSecPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgHr => $composableBuilder(
    column: $table.avgHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxHr => $composableBuilder(
    column: $table.maxHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RunSource, RunSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  $$PlannedRunsTableFilterComposer get plannedRunId {
    final $$PlannedRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedRunId,
      referencedTable: $db.plannedRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedRunsTableFilterComposer(
            $db: $db,
            $table: $db.plannedRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletedRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletedRunsTable> {
  $$CompletedRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get actualDistanceKm => $composableBuilder(
    column: $table.actualDistanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgPaceSecPerKm => $composableBuilder(
    column: $table.avgPaceSecPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgHr => $composableBuilder(
    column: $table.avgHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxHr => $composableBuilder(
    column: $table.maxHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlannedRunsTableOrderingComposer get plannedRunId {
    final $$PlannedRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedRunId,
      referencedTable: $db.plannedRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedRunsTableOrderingComposer(
            $db: $db,
            $table: $db.plannedRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletedRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletedRunsTable> {
  $$CompletedRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get actualDistanceKm => $composableBuilder(
    column: $table.actualDistanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgPaceSecPerKm => $composableBuilder(
    column: $table.avgPaceSecPerKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avgHr =>
      $composableBuilder(column: $table.avgHr, builder: (column) => column);

  GeneratedColumn<int> get maxHr =>
      $composableBuilder(column: $table.maxHr, builder: (column) => column);

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RunSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  $$PlannedRunsTableAnnotationComposer get plannedRunId {
    final $$PlannedRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedRunId,
      referencedTable: $db.plannedRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletedRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletedRunsTable,
          CompletedRunRow,
          $$CompletedRunsTableFilterComposer,
          $$CompletedRunsTableOrderingComposer,
          $$CompletedRunsTableAnnotationComposer,
          $$CompletedRunsTableCreateCompanionBuilder,
          $$CompletedRunsTableUpdateCompanionBuilder,
          (CompletedRunRow, $$CompletedRunsTableReferences),
          CompletedRunRow,
          PrefetchHooks Function({bool plannedRunId})
        > {
  $$CompletedRunsTableTableManager(_$AppDatabase db, $CompletedRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletedRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletedRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletedRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> plannedRunId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> actualDistanceKm = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<double> avgPaceSecPerKm = const Value.absent(),
                Value<int?> avgHr = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<double?> calories = const Value.absent(),
                Value<RunSource> source = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
              }) => CompletedRunsCompanion(
                id: id,
                plannedRunId: plannedRunId,
                date: date,
                actualDistanceKm: actualDistanceKm,
                durationSec: durationSec,
                avgPaceSecPerKm: avgPaceSecPerKm,
                avgHr: avgHr,
                maxHr: maxHr,
                calories: calories,
                source: source,
                externalId: externalId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> plannedRunId = const Value.absent(),
                required DateTime date,
                required double actualDistanceKm,
                required int durationSec,
                required double avgPaceSecPerKm,
                Value<int?> avgHr = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<double?> calories = const Value.absent(),
                required RunSource source,
                Value<String?> externalId = const Value.absent(),
              }) => CompletedRunsCompanion.insert(
                id: id,
                plannedRunId: plannedRunId,
                date: date,
                actualDistanceKm: actualDistanceKm,
                durationSec: durationSec,
                avgPaceSecPerKm: avgPaceSecPerKm,
                avgHr: avgHr,
                maxHr: maxHr,
                calories: calories,
                source: source,
                externalId: externalId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompletedRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({plannedRunId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (plannedRunId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.plannedRunId,
                                referencedTable: $$CompletedRunsTableReferences
                                    ._plannedRunIdTable(db),
                                referencedColumn: $$CompletedRunsTableReferences
                                    ._plannedRunIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CompletedRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletedRunsTable,
      CompletedRunRow,
      $$CompletedRunsTableFilterComposer,
      $$CompletedRunsTableOrderingComposer,
      $$CompletedRunsTableAnnotationComposer,
      $$CompletedRunsTableCreateCompanionBuilder,
      $$CompletedRunsTableUpdateCompanionBuilder,
      (CompletedRunRow, $$CompletedRunsTableReferences),
      CompletedRunRow,
      PrefetchHooks Function({bool plannedRunId})
    >;
typedef $$SettingsRowsTableCreateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      required UnitSystem units,
      required int reminderMorningMinutes,
      required int reminderEveningMinutes,
      required Aggressiveness adaptivityAggressiveness,
      required int catchupWindowDays,
      required int longRunCatchupWindowDays,
      required bool cloudBackupEnabled,
      Value<DateTime?> lastSyncAt,
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<UnitSystem> units,
      Value<int> reminderMorningMinutes,
      Value<int> reminderEveningMinutes,
      Value<Aggressiveness> adaptivityAggressiveness,
      Value<int> catchupWindowDays,
      Value<int> longRunCatchupWindowDays,
      Value<bool> cloudBackupEnabled,
      Value<DateTime?> lastSyncAt,
    });

class $$SettingsRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<UnitSystem, UnitSystem, String> get units =>
      $composableBuilder(
        column: $table.units,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get reminderMorningMinutes => $composableBuilder(
    column: $table.reminderMorningMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderEveningMinutes => $composableBuilder(
    column: $table.reminderEveningMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Aggressiveness, Aggressiveness, String>
  get adaptivityAggressiveness => $composableBuilder(
    column: $table.adaptivityAggressiveness,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get catchupWindowDays => $composableBuilder(
    column: $table.catchupWindowDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longRunCatchupWindowDays => $composableBuilder(
    column: $table.longRunCatchupWindowDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cloudBackupEnabled => $composableBuilder(
    column: $table.cloudBackupEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMorningMinutes => $composableBuilder(
    column: $table.reminderMorningMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderEveningMinutes => $composableBuilder(
    column: $table.reminderEveningMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adaptivityAggressiveness => $composableBuilder(
    column: $table.adaptivityAggressiveness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get catchupWindowDays => $composableBuilder(
    column: $table.catchupWindowDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longRunCatchupWindowDays => $composableBuilder(
    column: $table.longRunCatchupWindowDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cloudBackupEnabled => $composableBuilder(
    column: $table.cloudBackupEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UnitSystem, String> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<int> get reminderMorningMinutes => $composableBuilder(
    column: $table.reminderMorningMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderEveningMinutes => $composableBuilder(
    column: $table.reminderEveningMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Aggressiveness, String>
  get adaptivityAggressiveness => $composableBuilder(
    column: $table.adaptivityAggressiveness,
    builder: (column) => column,
  );

  GeneratedColumn<int> get catchupWindowDays => $composableBuilder(
    column: $table.catchupWindowDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longRunCatchupWindowDays => $composableBuilder(
    column: $table.longRunCatchupWindowDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cloudBackupEnabled => $composableBuilder(
    column: $table.cloudBackupEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );
}

class $$SettingsRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsRowsTable,
          SettingsRow,
          $$SettingsRowsTableFilterComposer,
          $$SettingsRowsTableOrderingComposer,
          $$SettingsRowsTableAnnotationComposer,
          $$SettingsRowsTableCreateCompanionBuilder,
          $$SettingsRowsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsRowsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsRowsTableTableManager(_$AppDatabase db, $SettingsRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<UnitSystem> units = const Value.absent(),
                Value<int> reminderMorningMinutes = const Value.absent(),
                Value<int> reminderEveningMinutes = const Value.absent(),
                Value<Aggressiveness> adaptivityAggressiveness =
                    const Value.absent(),
                Value<int> catchupWindowDays = const Value.absent(),
                Value<int> longRunCatchupWindowDays = const Value.absent(),
                Value<bool> cloudBackupEnabled = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
              }) => SettingsRowsCompanion(
                id: id,
                units: units,
                reminderMorningMinutes: reminderMorningMinutes,
                reminderEveningMinutes: reminderEveningMinutes,
                adaptivityAggressiveness: adaptivityAggressiveness,
                catchupWindowDays: catchupWindowDays,
                longRunCatchupWindowDays: longRunCatchupWindowDays,
                cloudBackupEnabled: cloudBackupEnabled,
                lastSyncAt: lastSyncAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required UnitSystem units,
                required int reminderMorningMinutes,
                required int reminderEveningMinutes,
                required Aggressiveness adaptivityAggressiveness,
                required int catchupWindowDays,
                required int longRunCatchupWindowDays,
                required bool cloudBackupEnabled,
                Value<DateTime?> lastSyncAt = const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                id: id,
                units: units,
                reminderMorningMinutes: reminderMorningMinutes,
                reminderEveningMinutes: reminderEveningMinutes,
                adaptivityAggressiveness: adaptivityAggressiveness,
                catchupWindowDays: catchupWindowDays,
                longRunCatchupWindowDays: longRunCatchupWindowDays,
                cloudBackupEnabled: cloudBackupEnabled,
                lastSyncAt: lastSyncAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsRowsTable,
      SettingsRow,
      $$SettingsRowsTableFilterComposer,
      $$SettingsRowsTableOrderingComposer,
      $$SettingsRowsTableAnnotationComposer,
      $$SettingsRowsTableCreateCompanionBuilder,
      $$SettingsRowsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $SettingsRowsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TrainingPlansTableTableManager get trainingPlans =>
      $$TrainingPlansTableTableManager(_db, _db.trainingPlans);
  $$PlannedRunsTableTableManager get plannedRuns =>
      $$PlannedRunsTableTableManager(_db, _db.plannedRuns);
  $$CompletedRunsTableTableManager get completedRuns =>
      $$CompletedRunsTableTableManager(_db, _db.completedRuns);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db, _db.settingsRows);
}

mixin _$PlanDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrainingPlansTable get trainingPlans => attachedDatabase.trainingPlans;
  $PlannedRunsTable get plannedRuns => attachedDatabase.plannedRuns;
  PlanDaoManager get managers => PlanDaoManager(this);
}

class PlanDaoManager {
  final _$PlanDaoMixin _db;
  PlanDaoManager(this._db);
  $$TrainingPlansTableTableManager get trainingPlans =>
      $$TrainingPlansTableTableManager(_db.attachedDatabase, _db.trainingPlans);
  $$PlannedRunsTableTableManager get plannedRuns =>
      $$PlannedRunsTableTableManager(_db.attachedDatabase, _db.plannedRuns);
}

mixin _$RunsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrainingPlansTable get trainingPlans => attachedDatabase.trainingPlans;
  $PlannedRunsTable get plannedRuns => attachedDatabase.plannedRuns;
  $CompletedRunsTable get completedRuns => attachedDatabase.completedRuns;
  RunsDaoManager get managers => RunsDaoManager(this);
}

class RunsDaoManager {
  final _$RunsDaoMixin _db;
  RunsDaoManager(this._db);
  $$TrainingPlansTableTableManager get trainingPlans =>
      $$TrainingPlansTableTableManager(_db.attachedDatabase, _db.trainingPlans);
  $$PlannedRunsTableTableManager get plannedRuns =>
      $$PlannedRunsTableTableManager(_db.attachedDatabase, _db.plannedRuns);
  $$CompletedRunsTableTableManager get completedRuns =>
      $$CompletedRunsTableTableManager(_db.attachedDatabase, _db.completedRuns);
}

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsRowsTable get settingsRows => attachedDatabase.settingsRows;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db.attachedDatabase, _db.settingsRows);
}
