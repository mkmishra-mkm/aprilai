import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder.dart';
import '../services/google_calendar_service.dart';
import '../services/notification_service.dart';
import 'user_configuration_provider.dart';

const _kRemindersKey = 'aprilai_reminders';

final _googleCalendarService = GoogleCalendarService();
final _notificationService = NotificationService();

class ReminderNotifier extends Notifier<List<Reminder>> {
  @override
  List<Reminder> build() {
    _loadFromPrefs();
    return [];
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRemindersKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      state = list.map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      state = [];
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.map((r) => r.toJson()).toList());
    await prefs.setString(_kRemindersKey, json);
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  Future<Reminder> addReminder({
    required String title,
    String? note,
    required DateTime scheduledAt,
    ReminderRepeat repeat = ReminderRepeat.none,
  }) async {
    final id = _generateId();
    final notificationId = _generateNotificationId();

    var reminder = Reminder(
      id: id,
      title: title,
      note: note,
      scheduledAt: scheduledAt,
      repeat: repeat,
      notificationId: notificationId,
    );

    // Schedule local notification
    await _notificationService.scheduleReminder(reminder);

    // Sync to Google Calendar if connected
    final gcalConnected = ref.read(userConfigurationProvider).googleCalendarConnected;
    if (gcalConnected) {
      final eventId = await _googleCalendarService.createEvent(reminder);
      if (eventId != null) {
        reminder = reminder.copyWith(googleCalendarEventId: eventId);
      }
    }

    state = [...state, reminder];
    await _persist();
    return reminder;
  }

  Future<void> updateReminder(Reminder updated) async {
    // Cancel old notification and reschedule
    await _notificationService.cancelReminder(updated.notificationId);
    await _notificationService.scheduleReminder(updated);

    state = [
      for (final r in state)
        if (r.id == updated.id) updated else r
    ];
    await _persist();
  }

  Future<void> toggleComplete(String id) async {
    final reminder = state.firstWhere((r) => r.id == id);
    final updated = reminder.copyWith(isCompleted: !reminder.isCompleted);

    if (updated.isCompleted) {
      await _notificationService.cancelReminder(reminder.notificationId);
    } else {
      await _notificationService.scheduleReminder(updated);
    }

    state = [
      for (final r in state)
        if (r.id == id) updated else r
    ];
    await _persist();
  }

  Future<void> deleteReminder(String id) async {
    final reminder = state.firstWhere((r) => r.id == id, orElse: () => throw Exception('Not found'));

    await _notificationService.cancelReminder(reminder.notificationId);

    // Remove from Google Calendar
    if (reminder.googleCalendarEventId != null) {
      await _googleCalendarService.deleteEvent(reminder.googleCalendarEventId!);
    }

    state = state.where((r) => r.id != id).toList();
    await _persist();
  }

  /// Called when Google Calendar is newly connected — syncs all local reminders.
  Future<void> syncToGoogleCalendar() async {
    final updated = <Reminder>[];
    for (final reminder in state) {
      if (reminder.googleCalendarEventId != null || reminder.isCompleted) {
        updated.add(reminder);
        continue;
      }
      final eventId = await _googleCalendarService.createEvent(reminder);
      updated.add(eventId != null ? reminder.copyWith(googleCalendarEventId: eventId) : reminder);
    }
    state = updated;
    await _persist();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _generateId() => '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  int _generateNotificationId() => Random().nextInt(2147483647);

  List<Reminder> get upcoming => state.where((r) => r.isUpcoming).toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<Reminder> get completed => state.where((r) => r.isCompleted).toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  List<Reminder> get past => state.where((r) => r.isPast).toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
}

final reminderProvider = NotifierProvider<ReminderNotifier, List<Reminder>>(
  ReminderNotifier.new,
);

final upcomingRemindersProvider = Provider<List<Reminder>>((ref) {
  return ref.watch(reminderProvider.notifier).upcoming;
});
