import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      final darwin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await darwin?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    if (reminder.scheduledAt.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(reminder.scheduledAt, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'aprilai_reminders',
      'April AI Reminders',
      channelDescription: 'Reminder notifications from April AI',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const linuxDetails = LinuxNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
      linux: linuxDetails,
    );

    if (reminder.repeat == ReminderRepeat.none) {
      await _plugin.zonedSchedule(
        reminder.notificationId,
        'April AI Reminder',
        reminder.title,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      final repeatInterval = _repeatInterval(reminder.repeat);
      if (repeatInterval != null) {
        await _plugin.periodicallyShow(
          reminder.notificationId,
          'April AI Reminder',
          reminder.title,
          repeatInterval,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  RepeatInterval? _repeatInterval(ReminderRepeat repeat) {
    switch (repeat) {
      case ReminderRepeat.daily:
        return RepeatInterval.daily;
      case ReminderRepeat.weekly:
        return RepeatInterval.weekly;
      default:
        return null;
    }
  }

  Future<void> cancelReminder(int notificationId) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();
    await _plugin.cancelAll();
  }

  /// Shows an immediate notification (useful for confirming a voice-set reminder).
  Future<void> showInstant({required String title, required String body}) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'aprilai_instant',
        'April AI Instant',
        channelDescription: 'Instant confirmations',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
    );

    await _plugin.show(0, title, body, details);
  }
}
