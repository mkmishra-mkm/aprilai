import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class DailyBriefingWidget extends StatelessWidget {
  const DailyBriefingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final greeting = _greeting(now.hour);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: tt.labelLarge?.copyWith(color: cs.primary, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEEE, MMMM d').format(now),
                        style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wb_sunny_outlined, size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Executive View',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              'AI Daily Summary',
              style: tt.labelLarge?.copyWith(color: cs.outline, letterSpacing: 0.3),
            ),
            const SizedBox(height: 8),
            _BriefingPoint(
              icon: Icons.trending_up,
              color: Colors.green,
              text: 'Q4 pipeline is 12% ahead of target. 3 deals closing this week.',
            ),
            const SizedBox(height: 8),
            _BriefingPoint(
              icon: Icons.warning_amber_outlined,
              color: Colors.orange,
              text: 'Board presentation at 2 PM requires slide deck finalization.',
            ),
            const SizedBox(height: 8),
            _BriefingPoint(
              icon: Icons.people_outline,
              color: cs.primary,
              text: '5 team check-ins scheduled. 2 direct reports flagged blockers.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricChip(
                    label: 'Focus Time',
                    value: '3.5h',
                    icon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricChip(
                    label: 'Emails',
                    value: '24 new',
                    icon: Icons.mail_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricChip(
                    label: 'Meetings',
                    value: '6 today',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  String _greeting(int hour) {
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

class _BriefingPoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _BriefingPoint({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: tt.bodySmall?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
