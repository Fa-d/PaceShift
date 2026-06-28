import 'dart:io';

import 'package:health/health.dart';

/// A running/walking workout pulled from Health Connect, normalised for the app.
class WorkoutSession {
  const WorkoutSession({
    required this.externalId,
    required this.date,
    required this.distanceKm,
    required this.durationSec,
    this.avgHr,
    this.maxHr,
    this.calories,
  });

  final String externalId;
  final DateTime date;
  final double distanceKm;
  final int durationSec;
  final int? avgHr;
  final int? maxHr;
  final double? calories;
}

/// Wraps the `health` plugin (→ Health Connect). All Health-Connect specifics
/// live here so the rest of the app stays platform-agnostic and degrades
/// gracefully when Health Connect is unavailable.
class HealthService {
  HealthService([Health? health]) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const _readTypes = <HealthDataType>[
    HealthDataType.WORKOUT,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const _runningActivities = <HealthWorkoutActivityType>{
    HealthWorkoutActivityType.RUNNING,
    HealthWorkoutActivityType.RUNNING_TREADMILL,
    HealthWorkoutActivityType.WALKING,
    HealthWorkoutActivityType.WALKING_TREADMILL,
    HealthWorkoutActivityType.HIKING,
  };

  List<HealthDataAccess> get _readAccess =>
      List.filled(_readTypes.length, HealthDataAccess.READ);

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Whether Health Connect is usable on this device.
  Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    await _ensureConfigured();
    final status = await _health.getHealthConnectSdkStatus();
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  /// Opens the Play Store to install/update Health Connect.
  Future<void> installHealthConnect() => _health.installHealthConnect();

  Future<bool> hasPermissions() async {
    await _ensureConfigured();
    return await _health.hasPermissions(_readTypes, permissions: _readAccess) ??
        false;
  }

  Future<bool> requestPermissions() async {
    await _ensureConfigured();
    return _health.requestAuthorization(_readTypes, permissions: _readAccess);
  }

  /// Fetches running/walking workouts recorded between [since] and now,
  /// enriching each with average/maximum heart rate from the same window.
  Future<List<WorkoutSession>> fetchWorkouts({required DateTime since}) async {
    await _ensureConfigured();
    final now = DateTime.now();
    if (!since.isBefore(now)) return const [];

    final workouts = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WORKOUT],
      startTime: since,
      endTime: now,
    );
    final hrPoints = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.HEART_RATE],
      startTime: since,
      endTime: now,
    );

    final sessions = <WorkoutSession>[];
    for (final p in workouts) {
      final value = p.value;
      if (value is! WorkoutHealthValue) continue;
      if (!_runningActivities.contains(value.workoutActivityType)) continue;

      final distanceKm = (value.totalDistance ?? 0) / 1000.0;
      final durationSec = p.dateTo.difference(p.dateFrom).inSeconds;
      if (distanceKm <= 0 || durationSec <= 0) continue;

      final hrs = hrPoints
          .where((h) =>
              !h.dateFrom.isBefore(p.dateFrom) && !h.dateTo.isAfter(p.dateTo))
          .map((h) => h.value)
          .whereType<NumericHealthValue>()
          .map((v) => v.numericValue.toInt())
          .toList();

      sessions.add(WorkoutSession(
        externalId: p.uuid,
        date: p.dateFrom,
        distanceKm: distanceKm,
        durationSec: durationSec,
        avgHr: hrs.isEmpty ? null : (hrs.reduce((a, b) => a + b) / hrs.length).round(),
        maxHr: hrs.isEmpty ? null : hrs.reduce((a, b) => a > b ? a : b),
        calories: value.totalEnergyBurned?.toDouble(),
      ));
    }
    return sessions;
  }
}
