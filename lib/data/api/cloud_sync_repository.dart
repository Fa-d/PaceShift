import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'api_client.dart';

/// Result of a cloud sync attempt.
enum CloudSyncStatus { ok, conflict, notSignedIn, error }

class CloudSyncResult {
  const CloudSyncResult(this.status, {this.version});
  final CloudSyncStatus status;
  final int? version;
}

/// Serializes the entire local Drift database to/from the backend as an opaque
/// JSON blob (the server never interprets it — the engine stays client-side).
class CloudSyncRepository {
  CloudSyncRepository(this._db, this._api);

  final AppDatabase _db;
  final ApiClient _api;

  /// Exports every table to a single JSON map using Drift's row `toJson()`.
  Future<Map<String, dynamic>> exportState() async => {
        'version': 2,
        'trainingPlans':
            (await _db.select(_db.trainingPlans).get()).map((r) => r.toJson()).toList(),
        'plannedRuns':
            (await _db.select(_db.plannedRuns).get()).map((r) => r.toJson()).toList(),
        'completedRuns':
            (await _db.select(_db.completedRuns).get()).map((r) => r.toJson()).toList(),
        'settings':
            (await _db.select(_db.settingsRows).get()).map((r) => r.toJson()).toList(),
      };

  /// Replaces all local data with [state] (used on restore).
  Future<void> importState(Map<String, dynamic> state) async {
    await _db.transaction(() async {
      await _db.delete(_db.completedRuns).go();
      await _db.delete(_db.plannedRuns).go();
      await _db.delete(_db.trainingPlans).go();
      await _db.delete(_db.settingsRows).go();

      for (final j in (state['trainingPlans'] as List? ?? const [])) {
        await _db.into(_db.trainingPlans).insert(
            TrainingPlanRow.fromJson(j as Map<String, dynamic>),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in (state['plannedRuns'] as List? ?? const [])) {
        await _db.into(_db.plannedRuns).insert(
            PlannedRunRow.fromJson(j as Map<String, dynamic>),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in (state['completedRuns'] as List? ?? const [])) {
        await _db.into(_db.completedRuns).insert(
            CompletedRunRow.fromJson(j as Map<String, dynamic>),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in (state['settings'] as List? ?? const [])) {
        await _db.into(_db.settingsRows).insert(
            SettingsRow.fromJson(j as Map<String, dynamic>),
            mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Pushes local state to the server (last-writer-wins with conflict report).
  Future<CloudSyncResult> push() async {
    if (!await _api.hasSession) {
      return const CloudSyncResult(CloudSyncStatus.notSignedIn);
    }
    try {
      final state = jsonEncode(await exportState());
      final res = await _api.raw.put('/sync/state', data: {
        'stateJson': state,
        'baseVersion': _localVersion,
      });
      final data = res.data as Map<String, dynamic>;
      if (data['conflict'] == true) {
        return CloudSyncResult(CloudSyncStatus.conflict,
            version: data['version'] as int?);
      }
      _localVersion = data['version'] as int? ?? _localVersion;
      return CloudSyncResult(CloudSyncStatus.ok, version: _localVersion);
    } catch (_) {
      return const CloudSyncResult(CloudSyncStatus.error);
    }
  }

  /// Pulls server state and replaces local data.
  Future<CloudSyncResult> pull() async {
    if (!await _api.hasSession) {
      return const CloudSyncResult(CloudSyncStatus.notSignedIn);
    }
    try {
      final res = await _api.raw.get('/sync/state');
      if (res.statusCode == 204 || res.data == null) {
        return const CloudSyncResult(CloudSyncStatus.ok, version: 0);
      }
      final data = res.data as Map<String, dynamic>;
      final state =
          jsonDecode(data['stateJson'] as String) as Map<String, dynamic>;
      await importState(state);
      _localVersion = data['version'] as int? ?? _localVersion;
      return CloudSyncResult(CloudSyncStatus.ok, version: _localVersion);
    } catch (_) {
      return const CloudSyncResult(CloudSyncStatus.error);
    }
  }

  // The last server version this device has reconciled with (best-effort,
  // in-memory; a fuller impl would persist this alongside the local data).
  int _localVersion = 0;
}
