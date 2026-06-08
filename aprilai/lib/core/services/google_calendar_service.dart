import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/reminder.dart';

/// Wraps Google Sign-In and Calendar API v3.
///
/// Setup required (one-time per project):
///   1. Create a project at console.cloud.google.com
///   2. Enable "Google Calendar API"
///   3. Create an OAuth 2.0 client ID for each platform
///   4. Place android/app/google-services.json and ios/Runner/GoogleService-Info.plist
///
/// On Web, pass the [webClientId] to [GoogleSignIn].
class GoogleCalendarService {
  static const _tokenKey = 'google_calendar_access_token';
  static const _emailKey = 'google_calendar_email';
  static const _calendarBaseUrl = 'https://www.googleapis.com/calendar/v3';

  final _storage = const FlutterSecureStorage();

  late final GoogleSignIn _signIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
    // Web apps: set your OAuth client ID here
    clientId: kIsWeb ? null : null,
  );

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<String?> signIn() async {
    try {
      final account = await _signIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      final token = auth.accessToken;
      if (token == null) return null;

      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _emailKey, value: account.email);

      return account.email;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
  }

  Future<bool> isSignedIn() async {
    return await _signIn.isSignedIn();
  }

  Future<String?> getEmail() async {
    return _storage.read(key: _emailKey);
  }

  Future<String?> _getValidToken() async {
    try {
      // Silently refresh if already signed in
      final account = await _signIn.signInSilently();
      if (account == null) return null;
      final auth = await account.authentication;
      final token = auth.accessToken;
      if (token != null) {
        await _storage.write(key: _tokenKey, value: token);
      }
      return token;
    } catch (_) {
      return _storage.read(key: _tokenKey);
    }
  }

  // ── Calendar API ────────────────────────────────────────────────────────────

  /// Creates a Google Calendar event for [reminder]. Returns the event ID or null on failure.
  Future<String?> createEvent(Reminder reminder) async {
    final token = await _getValidToken();
    if (token == null) return null;

    final end = reminder.scheduledAt.add(const Duration(minutes: 30));

    final body = jsonEncode({
      'summary': reminder.title,
      'description': reminder.note ?? 'Set via April AI',
      'start': {
        'dateTime': reminder.scheduledAt.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      },
      'end': {
        'dateTime': end.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      },
      if (reminder.repeat != ReminderRepeat.none)
        'recurrence': [_rrule(reminder.repeat)],
      'reminders': {
        'useDefault': false,
        'overrides': [
          {'method': 'popup', 'minutes': 10},
        ],
      },
    });

    final response = await http.post(
      Uri.parse('$_calendarBaseUrl/calendars/primary/events'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['id'] as String?;
    }
    debugPrint('Calendar create event failed: ${response.statusCode} ${response.body}');
    return null;
  }

  /// Deletes an event from Google Calendar.
  Future<bool> deleteEvent(String eventId) async {
    final token = await _getValidToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$_calendarBaseUrl/calendars/primary/events/$eventId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 204;
  }

  /// Fetches upcoming Google Calendar events (next 30 days).
  Future<List<CalendarEvent>> fetchUpcomingEvents() async {
    final token = await _getValidToken();
    if (token == null) return [];

    final now = DateTime.now().toUtc();
    final end = now.add(const Duration(days: 30));

    final uri = Uri.parse('$_calendarBaseUrl/calendars/primary/events').replace(
      queryParameters: {
        'timeMin': now.toIso8601String(),
        'timeMax': end.toIso8601String(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'maxResults': '50',
      },
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      debugPrint('Calendar fetch failed: ${response.statusCode}');
      return [];
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>? ?? [];

    return items.map((item) {
      final map = item as Map<String, dynamic>;
      final start = map['start'] as Map<String, dynamic>?;
      final startStr = start?['dateTime'] as String? ?? start?['date'] as String? ?? '';
      return CalendarEvent(
        id: map['id'] as String? ?? '',
        title: map['summary'] as String? ?? '(No title)',
        startTime: startStr.isNotEmpty ? DateTime.tryParse(startStr) : null,
      );
    }).toList();
  }

  String _rrule(ReminderRepeat repeat) {
    switch (repeat) {
      case ReminderRepeat.daily:
        return 'RRULE:FREQ=DAILY';
      case ReminderRepeat.weekly:
        return 'RRULE:FREQ=WEEKLY';
      case ReminderRepeat.monthly:
        return 'RRULE:FREQ=MONTHLY';
      default:
        return '';
    }
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final DateTime? startTime;

  const CalendarEvent({required this.id, required this.title, this.startTime});
}
