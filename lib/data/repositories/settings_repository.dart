import '../../domain/models/app_settings.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Persists and exposes user settings (single-row table).
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  SettingsDao get _dao => _db.settingsDao;

  /// Reactive settings stream, always emitting non-null defaults.
  Stream<AppSettings> watchSettings() =>
      _dao.watchSettings().map((row) => row?.toDomain() ?? const AppSettings());

  Future<AppSettings> getSettings() async =>
      (await _dao.getSettings())?.toDomain() ?? const AppSettings();

  /// Ensures a settings row exists (called on first launch).
  Future<void> ensureDefaults() async {
    if (await _dao.getSettings() == null) {
      await _dao.upsertSettings(const AppSettings().toCompanion());
    }
  }

  Future<void> update(AppSettings settings) => _dao.upsertSettings(settings.toCompanion());

  Future<void> markSynced(DateTime when) => _dao.updateLastSync(when);

  Future<DateTime?> lastSync() async => (await _dao.getSettings())?.lastSyncAt;
}
