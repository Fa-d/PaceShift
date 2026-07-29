import 'dart:io';

import 'package:health/health.dart';

import '../../domain/fitness/effort_validity.dart';
import '../../domain/models/enums.dart';

/// A running/walking workout pulled from Health Connect, normalised for the app.
class WorkoutSession {
  const WorkoutSession({
    required this.externalId,
    required this.date,
    required this.distanceKm,
    required this.durationSec,
    required this.activityType,
    this.avgHr,
    this.maxHr,
    this.calories,
  });

  final String externalId;
  final DateTime date;
  final double distanceKm;
  final int durationSec;
  final ActivityType activityType;
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

  /// Whether this platform has a health store we can read at all. Android uses
  /// Health Connect, iOS uses HealthKit; everything else is manual-only.
  static bool get isSupportedPlatform => Platform.isAndroid || Platform.isIOS;

  /// User-facing name of this platform's health store.
  static String get providerName =>
      Platform.isIOS ? 'Apple Health' : 'Health Connect';

  /// Types we'd *like* to read. Support differs per platform — notably distance,
  /// which is `DISTANCE_DELTA` on Health Connect and `DISTANCE_WALKING_RUNNING`
  /// on HealthKit — so this list is filtered through the plugin's own
  /// availability check before any request. Asking for a type the platform
  /// doesn't know about fails the whole authorization call.
  static const _candidateTypes = <HealthDataType>[
    HealthDataType.WORKOUT,
    HealthDataType.DISTANCE_DELTA, // Android
    HealthDataType.DISTANCE_WALKING_RUNNING, // iOS
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  List<HealthDataType> get _readTypes =>
      _candidateTypes.where(_health.isDataTypeAvailable).toList();

  /// Health Connect activity types we import, mapped to our [ActivityType].
  /// Walks/hikes are stored but excluded from running stats downstream.
  static const _trackedActivities = <HealthWorkoutActivityType, ActivityType>{
    HealthWorkoutActivityType.RUNNING: ActivityType.run,
    HealthWorkoutActivityType.RUNNING_TREADMILL: ActivityType.run,
    HealthWorkoutActivityType.WALKING: ActivityType.walk,
    HealthWorkoutActivityType.WALKING_TREADMILL: ActivityType.walk,
    HealthWorkoutActivityType.HIKING: ActivityType.hike,
  };

  List<HealthDataAccess> get _readAccess =>
      List.filled(_readTypes.length, HealthDataAccess.READ);

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Whether a readable health store exists on this device.
  Future<bool> isAvailable() async {
    if (!isSupportedPlatform) return false;
    await _ensureConfigured();
    // HealthKit ships on every iPhone — nothing to install or check.
    if (Platform.isIOS) return true;
    final status = await _health.getHealthConnectSdkStatus();
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  /// Whether Health Connect can be installed/updated from the Play Store. Always
  /// false on iOS, where there's nothing to install.
  bool get canInstallProvider => Platform.isAndroid;

  /// Opens the Play Store to install/update Health Connect. No-op off Android.
  Future<void> installHealthConnect() async {
    if (!canInstallProvider) return;
    await _health.installHealthConnect();
  }

  /// Read-permission state as the platform actually reports it:
  /// `true` granted, `false` denied, **`null` undetermined**.
  ///
  /// Apple deliberately never discloses whether READ access was granted, so this
  /// is always null on iOS. Callers must not collapse null to false — doing so
  /// makes iOS look permanently denied and re-prompts on every sync. See
  /// [SyncRepository], which resolves the tri-state against a persisted
  /// "we already asked" timestamp.
  Future<bool?> permissionStatus() async {
    if (!isSupportedPlatform) return false;
    await _ensureConfigured();
    return _health.hasPermissions(_readTypes, permissions: _readAccess);
  }

  Future<bool> requestPermissions() async {
    if (!isSupportedPlatform) return false;
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
      final activityType = _trackedActivities[value.workoutActivityType];
      if (activityType == null) continue;

      // Health Connect reports workout distance in metres.
      final distanceKm = (value.totalDistance ?? 0) / 1000.0;
      final durationSec = p.dateTo.difference(p.dateFrom).inSeconds;
      // Drop physically impossible records (GPS spikes, auto-paused sessions)
      // before they pollute totals and the fitness estimate.
      if (!isPhysicallyPlausibleEffort(
          distanceKm: distanceKm, durationSec: durationSec)) {
        continue;
      }

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
        activityType: activityType,
        avgHr: hrs.isEmpty ? null : (hrs.reduce((a, b) => a + b) / hrs.length).round(),
        maxHr: hrs.isEmpty ? null : hrs.reduce((a, b) => a > b ? a : b),
        calories: value.totalEnergyBurned?.toDouble(),
      ));
    }
    return sessions;
  }
}
