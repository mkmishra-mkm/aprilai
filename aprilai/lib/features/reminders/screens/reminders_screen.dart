import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/models/reminder.dart';
import '../../../core/providers/reminder_provider.dart';
import '../../../core/services/voice_reminder_parser.dart';
import 'reminder_form_screen.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _voiceText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    if (kIsWeb) return;
    try {
      final available = await _speech.initialize(
        onError: (_) => setState(() => _isListening = false),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
            _processVoice(_voiceText);
          }
        },
      );
      setState(() => _speechAvailable = available);
    } catch (_) {
      setState(() => _speechAvailable = false);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _voiceText = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() => _voiceText = result.recognizedWords);
        if (result.finalResult) {
          _processVoice(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'en_US',
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _processVoice(String text) {
    if (text.trim().isEmpty) return;
    final parsed = VoiceReminderParser.parse(text);
    if (parsed == null) {
      // Show the full form with the spoken text as title
      _openForm(initialTitle: text);
      return;
    }
    _openForm(
      initialTitle: parsed.title,
      initialDateTime: parsed.scheduledAt,
      initialRepeat: parsed.repeat,
    );
  }

  void _openForm({
    Reminder? existing,
    String? initialTitle,
    DateTime? initialDateTime,
    ReminderRepeat? initialRepeat,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReminderFormScreen(
          existing: existing,
          initialTitle: initialTitle,
          initialDateTime: initialDateTime,
          initialRepeat: initialRepeat,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(reminderProvider);
    final upcoming = ref.watch(reminderProvider.notifier).upcoming;
    final past = ref.watch(reminderProvider.notifier).past;
    final completed = ref.watch(reminderProvider.notifier).completed;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New reminder',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: reminders.isEmpty
          ? _EmptyState(onAdd: () => _openForm(), onVoice: _speechAvailable ? _toggleListening : null)
          : CustomScrollView(
              slivers: [
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader('Upcoming (${upcoming.length})'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ReminderTile(
                        reminder: upcoming[i],
                        onToggle: () => ref.read(reminderProvider.notifier).toggleComplete(upcoming[i].id),
                        onDelete: () => _confirmDelete(upcoming[i]),
                        onEdit: () => _openForm(existing: upcoming[i]),
                      ).animate().fadeIn(delay: (i * 40).ms),
                      childCount: upcoming.length,
                    ),
                  ),
                ],
                if (past.isNotEmpty) ...[
                  _SectionHeader('Overdue (${past.length})', color: cs.error),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ReminderTile(
                        reminder: past[i],
                        isOverdue: true,
                        onToggle: () => ref.read(reminderProvider.notifier).toggleComplete(past[i].id),
                        onDelete: () => _confirmDelete(past[i]),
                        onEdit: () => _openForm(existing: past[i]),
                      ),
                      childCount: past.length,
                    ),
                  ),
                ],
                if (completed.isNotEmpty) ...[
                  _SectionHeader('Completed (${completed.length})'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ReminderTile(
                        reminder: completed[i],
                        onToggle: () => ref.read(reminderProvider.notifier).toggleComplete(completed[i].id),
                        onDelete: () => _confirmDelete(completed[i]),
                        onEdit: () => _openForm(existing: completed[i]),
                      ),
                      childCount: completed.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_speechAvailable)
            FloatingActionButton(
              heroTag: 'voice_fab',
              onPressed: _toggleListening,
              backgroundColor: _isListening ? cs.error : cs.primary,
              tooltip: _isListening ? 'Stop listening' : 'Set reminder by voice',
              child: Icon(_isListening ? Icons.stop : Icons.mic),
            ).animate(target: _isListening ? 1 : 0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  curve: Curves.easeInOut,
                  duration: 400.ms,
                ),
          if (_speechAvailable) const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add_fab',
            onPressed: () => _openForm(),
            tooltip: 'New reminder',
            child: const Icon(Icons.add),
          ),
        ],
      ),
      // Voice listening banner
      bottomSheet: _isListening
          ? _VoiceBanner(text: _voiceText, onCancel: () async {
              await _speech.stop();
              setState(() => _isListening = false);
            })
          : null,
    );
  }

  Future<void> _confirmDelete(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('"${reminder.title}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(reminderProvider.notifier).deleteReminder(reminder.id);
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader(this.title, {this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color ?? cs.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }
}

// ── Reminder tile ─────────────────────────────────────────────────────────────

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final bool isOverdue;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ReminderTile({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: cs.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: cs.onError),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Checkbox(
          value: reminder.isCompleted,
          onChanged: (_) => onToggle(),
          shape: const CircleBorder(),
        ),
        title: Text(
          reminder.title,
          style: tt.bodyMedium?.copyWith(
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
            color: reminder.isCompleted ? cs.onSurface.withValues(alpha: 0.4) : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              isOverdue ? Icons.warning_amber_rounded : Icons.access_time_outlined,
              size: 12,
              color: isOverdue ? cs.error : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('EEE, MMM d · h:mm a').format(reminder.scheduledAt),
              style: tt.bodySmall?.copyWith(
                color: isOverdue ? cs.error : cs.onSurfaceVariant,
              ),
            ),
            if (reminder.repeat != ReminderRepeat.none) ...[
              const SizedBox(width: 6),
              Icon(Icons.repeat, size: 12, color: cs.primary),
            ],
            if (reminder.googleCalendarEventId != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.calendar_month_outlined, size: 12, color: cs.primary),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: onEdit,
          tooltip: 'Edit',
        ),
        onTap: onEdit,
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback? onVoice;

  const _EmptyState({required this.onAdd, this.onVoice});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 72, color: cs.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            Text('No reminders yet', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Add a reminder manually or say it out loud.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
            ),
            if (onVoice != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onVoice,
                icon: const Icon(Icons.mic),
                label: const Text('Say a reminder'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Voice listening banner ────────────────────────────────────────────────────

class _VoiceBanner extends StatelessWidget {
  final String text;
  final VoidCallback onCancel;

  const _VoiceBanner({required this.text, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(Icons.mic, color: cs.onErrorContainer)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 600.ms),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text.isEmpty ? 'Listening... say your reminder' : text,
                style: TextStyle(color: cs.onErrorContainer),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: cs.onErrorContainer),
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 200.ms);
  }
}
