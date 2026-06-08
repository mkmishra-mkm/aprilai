import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/reminder_provider.dart';
import '../../../../core/models/reminder.dart';
import '../../../reminders/screens/reminder_form_screen.dart';

class _CalendarEvent {
  final String title;
  final String time;
  final String? location;
  final Color color;
  final bool isNow;

  const _CalendarEvent({
    required this.title,
    required this.time,
    this.location,
    required this.color,
    this.isNow = false,
  });
}

class CalendarWidget extends ConsumerWidget {
  const CalendarWidget({super.key});

  static final _mockEvents = [
    _CalendarEvent(
      title: 'Standup — Engineering',
      time: '9:00 AM',
      location: 'Zoom',
      color: const Color(0xFF1A73E8),
    ),
    _CalendarEvent(
      title: 'Q4 Review — Sales',
      time: '11:00 AM',
      location: 'Conf Room A',
      color: const Color(0xFF34A853),
      isNow: true,
    ),
    _CalendarEvent(
      title: 'Lunch with Investor',
      time: '12:30 PM',
      location: 'The Capital Grille',
      color: const Color(0xFFFF6D00),
    ),
    _CalendarEvent(
      title: 'Board Presentation',
      time: '2:00 PM',
      location: 'Boardroom',
      color: const Color(0xFFEA4335),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final upcomingReminders = ref.watch(upcomingRemindersProvider);
    final todayReminders = upcomingReminders
        .where((r) => _isToday(r.scheduledAt))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Schedule',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('MMM d').format(DateTime.now()),
                  style: tt.labelMedium?.copyWith(color: cs.outline),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mock calendar events
            ..._mockEvents.asMap().entries.map((e) => _EventTile(event: e.value, index: e.key)),

            // Reminders for today
            if (todayReminders.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Reminders today',
                  style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                ),
              ),
              ...todayReminders.asMap().entries.map(
                    (e) => _ReminderTile(reminder: e.value, index: e.key),
                  ),
            ],

            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReminderFormScreen()),
              ),
              icon: Icon(Icons.add, size: 16, color: cs.primary),
              label: Text('Add reminder', style: TextStyle(color: cs.primary)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final int index;
  const _ReminderTile({required this.reminder, required this.index});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    const color = Color(0xFF00897B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              DateFormat('h:mm a').format(reminder.scheduledAt),
              style: tt.labelSmall?.copyWith(color: cs.outline),
            ),
          ),
          Container(
            width: 3,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm_outlined, size: 13, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reminder.title,
                      style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (reminder.googleCalendarEventId != null)
                    Icon(Icons.calendar_month_outlined, size: 12, color: cs.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 60));
  }
}

class _EventTile extends StatelessWidget {
  final _CalendarEvent event;
  final int index;

  const _EventTile({required this.event, required this.index});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              event.time,
              style: tt.labelSmall?.copyWith(
                color: event.isNow ? event.color : cs.outline,
                fontWeight: event.isNow ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          Container(
            width: 3,
            height: 44,
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: event.isNow
                    ? event.color.withValues(alpha: 0.08)
                    : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: event.isNow
                    ? Border.all(color: event.color.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: event.isNow ? event.color : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.isNow)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: event.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NOW',
                            style: tt.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 2),
                    Text(event.location!, style: tt.labelSmall?.copyWith(color: cs.outline)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 150 + index * 60));
  }
}
