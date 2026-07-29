import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'app_settings.freezed.dart';

/// User-tunable app settings (spec §3 Settings).
///
/// Reminder times are stored as **minutes since local midnight** to keep this
/// model free of Flutter's `TimeOfDay`.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(UnitSystem.metric) UnitSystem units,

    /// Morning reminder time, minutes since midnight (default 07:00).
    @Default(7 * 60) int reminderMorningMinutes,

    /// Evening check-in time, minutes since midnight (default 20:00).
    @Default(20 * 60) int reminderEveningMinutes,
    @Default(Aggressiveness.balanced) Aggressiveness adaptivityAggressiveness,

    /// Days within which an ordinary missed run can still be made up.
    @Default(7) int catchupWindowDays,

    /// Longer make-up window for long runs.
    @Default(10) int longRunCatchupWindowDays,
    @Default(false) bool cloudBackupEnabled,

    /// Display name captured during onboarding (empty = not provided).
    @Default('') String userName,

    /// Last successful health sync (null = never synced). Read-only here: the
    /// sync repository owns the write, so a stale copy can't clobber it.
    DateTime? lastSyncAt,

    /// When we last asked the user to connect health data (null = never asked).
    /// Read-only here, for the same reason as [lastSyncAt].
    DateTime? healthPromptedAt,
  }) = _AppSettings;

  const AppSettings._();

  int get reminderMorningHour => reminderMorningMinutes ~/ 60;
  int get reminderMorningMinute => reminderMorningMinutes % 60;
  int get reminderEveningHour => reminderEveningMinutes ~/ 60;
  int get reminderEveningMinute => reminderEveningMinutes % 60;
}
