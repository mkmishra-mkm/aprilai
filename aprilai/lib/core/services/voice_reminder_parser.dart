import '../models/reminder.dart';

class ReminderParseResult {
  final String title;
  final DateTime scheduledAt;
  final ReminderRepeat repeat;
  final String? note;

  const ReminderParseResult({
    required this.title,
    required this.scheduledAt,
    this.repeat = ReminderRepeat.none,
    this.note,
  });
}

/// Parses natural language voice input into structured reminder data.
///
/// Supported patterns:
///   "remind me to [X] at [time]"
///   "remind me to [X] tomorrow at [time]"
///   "remind me to [X] in [N] minutes/hours"
///   "set a reminder for [time] to [X]"
///   "every day at [time] remind me to [X]"
///   "every week at [time] remind me to [X]"
class VoiceReminderParser {
  static ReminderParseResult? parse(String text) {
    final input = text.trim().toLowerCase();
    if (input.isEmpty) return null;

    final repeat = _extractRepeat(input);
    final timeResult = _extractTime(input);
    final title = _extractTitle(input);

    if (title == null || title.isEmpty) return null;

    final scheduledAt = timeResult ?? _defaultTime();

    return ReminderParseResult(
      title: _capitalize(title),
      scheduledAt: scheduledAt,
      repeat: repeat,
    );
  }

  // ── Title extraction ────────────────────────────────────────────────────────

  static String? _extractTitle(String input) {
    // Patterns: "remind me to X at/in/tomorrow", "set reminder to X at"
    final patterns = [
      RegExp(r'remind me (?:every (?:day|week|month) )?to (.+?)(?:\s+(?:at|in|tomorrow|today|next|on)\s+|\s*$)'),
      RegExp(r'set (?:a )?reminder (?:to|for) (.+?)(?:\s+(?:at|in|tomorrow|today|next|on)\s+|\s*$)'),
      RegExp(r'add (?:a )?reminder (?:to|for) (.+?)(?:\s+(?:at|in|tomorrow|today|next|on)\s+|\s*$)'),
      RegExp(r'(?:at|in) .+? (?:to|remind me to) (.+)$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        final title = match.group(1)?.trim();
        if (title != null && title.isNotEmpty) {
          return _cleanTitle(title);
        }
      }
    }

    // Fallback: strip time/repeat keywords and use the rest
    var cleaned = input
        .replaceAll(RegExp(r'\b(remind me|set a reminder|add a reminder|reminder)\b'), '')
        .replaceAll(RegExp(r'\b(every day|every week|every month|daily|weekly)\b'), '')
        .replaceAll(RegExp(r'\b(tomorrow|today|next monday|next tuesday|next wednesday|next thursday|next friday|next saturday|next sunday)\b'), '')
        .replaceAll(RegExp(r'\bat \d{1,2}(?::\d{2})?\s*(?:am|pm)?\b'), '')
        .replaceAll(RegExp(r'\bin \d+ (?:minutes?|hours?)\b'), '')
        .replaceAll(RegExp(r'\b(to|for|at|in|on)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned.isEmpty ? null : cleaned;
  }

  static String _cleanTitle(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^(to|for)\s+'), '');
  }

  // ── Time extraction ─────────────────────────────────────────────────────────

  static DateTime? _extractTime(String input) {
    final now = DateTime.now();

    // "in N minutes/hours"
    final inMatch = RegExp(r'in (\d+)\s*(minutes?|mins?|hours?|hrs?)').firstMatch(input);
    if (inMatch != null) {
      final value = int.parse(inMatch.group(1)!);
      final unit = inMatch.group(2)!;
      if (unit.startsWith('h')) return now.add(Duration(hours: value));
      return now.add(Duration(minutes: value));
    }

    // Parse "tomorrow" base
    bool isTomorrow = input.contains('tomorrow');
    bool isToday = input.contains('today');

    // Next weekday
    final weekdayMatch = RegExp(r'next (monday|tuesday|wednesday|thursday|friday|saturday|sunday)').firstMatch(input);
    int? targetWeekday;
    if (weekdayMatch != null) {
      const days = {
        'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
        'friday': 5, 'saturday': 6, 'sunday': 7,
      };
      targetWeekday = days[weekdayMatch.group(1)];
    }

    // Parse explicit time: "at 8 PM", "at 8:30 AM", "at 14:00"
    final timeMatch = RegExp(r'at (\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(input);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      final minute = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
      final period = timeMatch.group(3);

      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      // If no AM/PM and hour < 8, assume PM (e.g. "at 6" → 6 PM)
      if (period == null && hour < 8) hour += 12;

      DateTime base;
      if (targetWeekday != null) {
        base = _nextWeekday(now, targetWeekday);
      } else if (isTomorrow) {
        base = now.add(const Duration(days: 1));
      } else {
        base = now;
        // If the time has already passed today, schedule for tomorrow
        final candidate = DateTime(now.year, now.month, now.day, hour, minute);
        if (!isToday && candidate.isBefore(now)) {
          base = now.add(const Duration(days: 1));
        }
      }

      return DateTime(base.year, base.month, base.day, hour, minute);
    }

    // No explicit time found but has day reference → default 9 AM
    if (isTomorrow || targetWeekday != null) {
      final base = targetWeekday != null
          ? _nextWeekday(now, targetWeekday)
          : now.add(const Duration(days: 1));
      return DateTime(base.year, base.month, base.day, 9, 0);
    }

    return null;
  }

  static DateTime _nextWeekday(DateTime from, int weekday) {
    var date = from.add(const Duration(days: 1));
    while (date.weekday != weekday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  static DateTime _defaultTime() {
    final now = DateTime.now();
    // Default: one hour from now, rounded to next half-hour
    final candidate = now.add(const Duration(hours: 1));
    final minute = candidate.minute < 30 ? 30 : 0;
    final hour = candidate.minute < 30 ? candidate.hour : candidate.hour + 1;
    return DateTime(candidate.year, candidate.month, candidate.day, hour, minute);
  }

  // ── Repeat extraction ───────────────────────────────────────────────────────

  static ReminderRepeat _extractRepeat(String input) {
    if (input.contains('every day') || input.contains('daily') || input.contains('every morning') || input.contains('every night')) {
      return ReminderRepeat.daily;
    }
    if (input.contains('every week') || input.contains('weekly')) {
      return ReminderRepeat.weekly;
    }
    if (input.contains('every month') || input.contains('monthly')) {
      return ReminderRepeat.monthly;
    }
    return ReminderRepeat.none;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Returns true if the text looks like a reminder intent.
  static bool isReminderIntent(String text) {
    final lower = text.toLowerCase();
    return lower.contains('remind') ||
        lower.contains('reminder') ||
        lower.contains('set alarm') ||
        lower.contains('alert me') ||
        lower.contains('don\'t let me forget') ||
        lower.contains('schedule') ||
        (lower.contains('notify') && lower.contains('at'));
  }
}
