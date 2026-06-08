import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../reminders/screens/reminder_form_screen.dart';

class SimpleTaskButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const SimpleTaskButton({
    super.key,
    required this.label,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final effectiveColor = color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: effectiveColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: effectiveColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: effectiveColor,
              size: 28,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class BigActionGrid extends StatelessWidget {
  const BigActionGrid({super.key});

  static const _actions = [
    (label: 'Add Reminder', icon: Icons.alarm_add_rounded, color: Color(0xFF00897B)),
    (label: 'Call Someone', icon: Icons.phone_rounded, color: Color(0xFF1565C0)),
    (label: 'Write a Note', icon: Icons.edit_note_rounded, color: Color(0xFF6A1B9A)),
    (label: 'Ask April AI', icon: Icons.smart_toy_outlined, color: Color(0xFFC62828)),
    (label: 'Open Photos', icon: Icons.photo_library_rounded, color: Color(0xFFE65100)),
    (label: 'Weather', icon: Icons.wb_sunny_rounded, color: Color(0xFFF57F17)),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'What would you like to do?',
            style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: _actions.asMap().entries.map((e) {
            final action = e.value;
            return _BigActionCell(
              label: action.label,
              icon: action.icon,
              color: action.color,
              index: e.key,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BigActionCell extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int index;

  const _BigActionCell({
    required this.label,
    required this.icon,
    required this.color,
    required this.index,
  });

  void _handleTap(BuildContext context) {
    switch (label) {
      case 'Add Reminder':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReminderFormScreen()),
        );
      case 'Ask April AI':
        context.push(AppConstants.routeAssistant);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: tt.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + index * 60))
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          delay: Duration(milliseconds: 100 + index * 60),
          curve: Curves.easeOut,
        );
  }
}
