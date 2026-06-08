import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/reminder.dart';
import '../../../core/providers/reminder_provider.dart';
import '../../../core/services/notification_service.dart';

class ReminderFormScreen extends ConsumerStatefulWidget {
  /// Pass an existing reminder to edit it; null to create a new one.
  final Reminder? existing;

  /// Pre-fill title (e.g. parsed from voice).
  final String? initialTitle;
  final DateTime? initialDateTime;
  final ReminderRepeat? initialRepeat;

  const ReminderFormScreen({
    super.key,
    this.existing,
    this.initialTitle,
    this.initialDateTime,
    this.initialRepeat,
  });

  @override
  ConsumerState<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late ReminderRepeat _repeat;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl = TextEditingController(text: existing?.title ?? widget.initialTitle ?? '');
    _noteCtrl = TextEditingController(text: existing?.note ?? '');
    final dt = existing?.scheduledAt ?? widget.initialDateTime ?? _defaultTime();
    _selectedDate = DateTime(dt.year, dt.month, dt.day);
    _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    _repeat = existing?.repeat ?? widget.initialRepeat ?? ReminderRepeat.none;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  DateTime _defaultTime() {
    final now = DateTime.now().add(const Duration(hours: 1));
    return DateTime(now.year, now.month, now.day, now.hour, 0);
  }

  DateTime get _scheduledAt => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime.now()) ? DateTime.now() : _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder title')),
      );
      return;
    }

    setState(() => _saving = true);

    await NotificationService().requestPermissions();

    final notifier = ref.read(reminderProvider.notifier);

    if (widget.existing != null) {
      await notifier.updateReminder(
        widget.existing!.copyWith(
          title: _titleCtrl.text.trim(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          scheduledAt: _scheduledAt,
          repeat: _repeat,
        ),
      );
    } else {
      await notifier.addReminder(
        title: _titleCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        scheduledAt: _scheduledAt,
        repeat: _repeat,
      );
    }

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing != null ? 'Reminder updated' : 'Reminder set for ${DateFormat('MMM d, h:mm a').format(_scheduledAt)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Reminder' : 'New Reminder'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Title
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: tt.titleMedium,
            decoration: InputDecoration(
              labelText: 'Reminder',
              hintText: 'e.g. Take medication',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Additional details...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Date & Time row
          Text('When', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PickerCard(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerCard(
                  icon: Icons.access_time_outlined,
                  label: _selectedTime.format(context),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Repeat
          Text('Repeat', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ReminderRepeat.values.map((r) {
              final selected = r == _repeat;
              return ChoiceChip(
                label: Text(r.displayName),
                selected: selected,
                onSelected: (_) => setState(() => _repeat = r),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.alarm, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleCtrl.text.trim().isEmpty ? 'Your reminder' : _titleCtrl.text.trim(),
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${DateFormat("EEE, MMM d, yyyy 'at' h:mm a").format(_scheduledAt)}'
                        '${_repeat != ReminderRepeat.none ? " · ${_repeat.displayName}" : ""}',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(isEdit ? 'Update Reminder' : 'Set Reminder'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
