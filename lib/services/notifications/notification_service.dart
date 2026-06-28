import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/formatting.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';

/// Stable notification ids and action ids used across the app.
class NotificationIds {
  static const morning = 1001;
  static const evening = 1002;
  static const weekly = 1003;
  static const postSync = 1004;

  static const channelReminders = 'paceshift_reminders';
  static const channelUpdates = 'paceshift_updates';

  static const actionMarkDone = 'mark_done';
  static const actionCouldNotRun = 'could_not_run';
}

/// Wraps `flutter_local_notifications`: scheduled daily reminders, the evening
/// check-in (with actions), the post-sync confirmation, and the weekly summary
/// (spec §7). Tap/action routing is delegated to [onAction].
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// Called when the user taps a notification or one of its actions. The
  /// [actionId] is null for a plain tap.
  static void Function(String? actionId, String? payload)? onAction;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC if the platform timezone can't be resolved.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS/macOS: defer permission prompts to requestPermissions() so onboarding
    // controls timing.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (resp) =>
          onAction?.call(resp.actionId, resp.payload),
    );
    _ready = true;
  }

  Future<bool> requestPermissions() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? true;
      await android.requestExactAlarmsPermission();
      return granted;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  static const _iosDetails = DarwinNotificationDetails();

  // ---- Channels ----------------------------------------------------------

  AndroidNotificationDetails get _reminderDetails =>
      const AndroidNotificationDetails(
        NotificationIds.channelReminders,
        'Training reminders',
        channelDescription: 'Daily run reminders and evening check-ins',
        importance: Importance.high,
        priority: Priority.high,
      );

  AndroidNotificationDetails _eveningDetails() =>
      const AndroidNotificationDetails(
        NotificationIds.channelReminders,
        'Training reminders',
        channelDescription: 'Daily run reminders and evening check-ins',
        importance: Importance.high,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
              NotificationIds.actionMarkDone, 'Mark done',
              showsUserInterface: true),
          AndroidNotificationAction(
              NotificationIds.actionCouldNotRun, 'Couldn’t run today',
              showsUserInterface: true),
        ],
      );

  AndroidNotificationDetails get _updateDetails =>
      const AndroidNotificationDetails(
        NotificationIds.channelUpdates,
        'Updates',
        channelDescription: 'Sync confirmations and weekly summaries',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

  // ---- Scheduling --------------------------------------------------------

  /// Schedules the daily morning reminder and evening check-in at the times in
  /// [settings]. [todaysRun] tailors the morning copy (null = rest day).
  Future<void> scheduleDailyReminders(
    AppSettings settings, {
    PlannedRun? todaysRun,
  }) async {
    await init();
    await _plugin.cancel(id: NotificationIds.morning);
    await _plugin.cancel(id: NotificationIds.evening);

    final morningBody = todaysRun == null || todaysRun.type == RunType.rest
        ? 'Rest day — recovery is training too. Enjoy it.'
        : '${runTypeLabel(todaysRun.type)}: '
            '${formatKm(todaysRun.targetDistanceKm)}'
            '${todaysRun.runWalkRatio != null ? ' · ${todaysRun.runWalkRatio} run/walk' : ''}';

    await _zoned(
      id: NotificationIds.morning,
      title: 'Today’s run',
      body: morningBody,
      hour: settings.reminderMorningHour,
      minute: settings.reminderMorningMinute,
      details: _reminderDetails,
    );

    await _zoned(
      id: NotificationIds.evening,
      title: 'Did you get your run in?',
      body: 'Log it, or tell PaceShift if you couldn’t — your plan adapts.',
      hour: settings.reminderEveningHour,
      minute: settings.reminderEveningMinute,
      details: _eveningDetails(),
    );
  }

  /// Immediate confirmation after a sync (spec §7).
  Future<void> showPostSync(String message) async {
    await init();
    await _plugin.show(
      id: NotificationIds.postSync,
      title: 'Run synced',
      body: message,
      notificationDetails: NotificationDetails(android: _updateDetails, iOS: _iosDetails),
    );
  }

  /// Weekly summary (called Sunday evening by the background worker).
  Future<void> showWeeklySummary(String message) async {
    await init();
    await _plugin.show(
      id: NotificationIds.weekly,
      title: 'Your week in review',
      body: message,
      notificationDetails: NotificationDetails(android: _updateDetails, iOS: _iosDetails),
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> _zoned({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required AndroidNotificationDetails details,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOf(hour, minute),
      notificationDetails: NotificationDetails(android: details, iOS: _iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
