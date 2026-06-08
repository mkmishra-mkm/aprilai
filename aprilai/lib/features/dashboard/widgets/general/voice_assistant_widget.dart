import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/models/reminder.dart';
import '../../../../core/providers/reminder_provider.dart';
import '../../../../core/services/voice_reminder_parser.dart';
import '../../../reminders/screens/reminder_form_screen.dart';

class VoiceAssistantWidget extends ConsumerStatefulWidget {
  const VoiceAssistantWidget({super.key});

  @override
  ConsumerState<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends ConsumerState<VoiceAssistantWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final SpeechToText _speech = SpeechToText();

  bool _speechAvailable = false;
  bool _isListening = false;
  String _spokenText = '';
  String _statusMessage = 'Tap the mic to start';

  static const _suggestions = [
    'Remind me to take my medication at 8 PM',
    'Set a reminder to call Mom tomorrow at 10 AM',
    'Remind me every day at 9 AM to exercise',
    'Remind me to drink water in 30 minutes',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    if (kIsWeb) {
      setState(() => _statusMessage = 'Voice not supported on web — type a reminder below');
      return;
    }
    try {
      final available = await _speech.initialize(
        onError: (e) {
          setState(() {
            _isListening = false;
            _statusMessage = 'Speech error: ${e.errorMsg}';
          });
          _pulseController.stop();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _onListeningDone();
          }
        },
      );
      setState(() {
        _speechAvailable = available;
        _statusMessage = available ? 'Tap the mic to start' : 'Microphone not available';
      });
    } catch (_) {
      setState(() {
        _speechAvailable = false;
        _statusMessage = 'Speech recognition unavailable';
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      _onListeningDone();
      return;
    }

    setState(() {
      _isListening = true;
      _spokenText = '';
      _statusMessage = 'Listening...';
    });
    _pulseController.repeat(reverse: true);

    await _speech.listen(
      onResult: (result) {
        setState(() => _spokenText = result.recognizedWords);
        if (result.finalResult) {
          _onListeningDone();
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'en_US',
        listenMode: ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  void _onListeningDone() {
    _pulseController.stop();
    _pulseController.reset();
    final text = _spokenText;
    setState(() {
      _isListening = false;
      _statusMessage = text.isNotEmpty ? '"$text"' : 'Tap the mic to start';
    });
    if (text.trim().isNotEmpty) {
      _handleSpokenText(text);
    }
  }

  void _handleSpokenText(String text) {
    final parsed = VoiceReminderParser.parse(text);
    _openReminderForm(
      initialTitle: parsed?.title ?? text,
      initialDateTime: parsed?.scheduledAt,
      initialRepeat: parsed?.repeat,
    );
  }

  void _openReminderForm({
    String? initialTitle,
    DateTime? initialDateTime,
    ReminderRepeat? initialRepeat,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReminderFormScreen(
          initialTitle: initialTitle,
          initialDateTime: initialDateTime,
          initialRepeat: initialRepeat,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final upcoming = ref.watch(upcomingRemindersProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice Assistant', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),

            // Mic button with pulse rings
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening) ...[
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Container(
                        width: 100 + 40 * _pulseController.value,
                        height: 100 + 40 * _pulseController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.error.withValues(alpha: 0.08 * (1 - _pulseController.value)),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Container(
                        width: 90 + 25 * _pulseController.value,
                        height: 90 + 25 * _pulseController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.error.withValues(alpha: 0.12 * (1 - _pulseController.value)),
                        ),
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: _speechAvailable ? _toggleListening : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? cs.error : cs.primary,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? cs.error : cs.primary).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _statusMessage,
                  key: ValueKey(_statusMessage),
                  style: tt.bodyMedium?.copyWith(
                    color: _isListening ? cs.error : cs.onSurfaceVariant,
                    fontStyle: _spokenText.isNotEmpty && !_isListening ? FontStyle.italic : FontStyle.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Upcoming reminders preview
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text('Upcoming reminders', style: tt.labelMedium?.copyWith(color: cs.primary)),
              const SizedBox(height: 8),
              ...upcoming.take(3).map((r) => _UpcomingReminderChip(reminder: r)),
            ],

            // Suggestion chips
            const SizedBox(height: 24),
            Text('Try saying:', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions
                  .map(
                    (s) => ActionChip(
                      label: Text(s, style: tt.bodySmall),
                      onPressed: () {
                        setState(() {
                          _spokenText = s;
                          _statusMessage = '"$s"';
                        });
                        _handleSpokenText(s);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingReminderChip extends StatelessWidget {
  final Reminder reminder;
  const _UpcomingReminderChip({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.alarm_outlined, size: 14, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(reminder.title, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
