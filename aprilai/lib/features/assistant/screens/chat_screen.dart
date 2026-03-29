import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_configuration.dart';
import '../../../core/providers/user_configuration_provider.dart';
import '../models/message.dart';
import '../services/llm_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    await ref.read(chatProvider.notifier).sendMessage(text);
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final config = ref.watch(userConfigurationProvider);
    final role = config.role;
    final llm = ref.watch(llmServiceProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('April AI Assistant'),
            Text(
              llm.providerName,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat',
            onPressed: () =>
                ref.read(chatProvider.notifier).clearHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Role badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cs.primaryContainer,
            child: Row(
              children: [
                Text(role.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${role.displayName} mode — ${_modeDescription(role)}',
                    style: tt.labelSmall?.copyWith(color: cs.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: messages.isEmpty
                ? _EmptyState(role: role, onSend: (text) {
                    _controller.text = text;
                    _send();
                  })
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      return _ChatBubble(
                        message: msg,
                        role: role,
                        index: i,
                      );
                    },
                  ),
          ),
          // Input bar
          _InputBar(
            controller: _controller,
            sending: _sending,
            onSend: _send,
            role: role,
          ),
        ],
      ),
    );
  }

  String _modeDescription(UserRole role) {
    switch (role) {
      case UserRole.executive:
        return 'Formal, concise, action-oriented';
      case UserRole.technical:
        return 'Data-heavy, code-first responses';
      case UserRole.general:
        return 'Friendly, step-by-step guidance';
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final Message message;
  final UserRole role;
  final int index;

  const _ChatBubble({
    required this.message,
    required this.role,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.role == MessageRole.user;

    if (message.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            _Avatar(isUser: false, role: role),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(cs.onSurfaceVariant, 0),
                  const SizedBox(width: 4),
                  _dot(cs.onSurfaceVariant, 150),
                  const SizedBox(width: 4),
                  _dot(cs.onSurfaceVariant, 300),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _Avatar(isUser: false, role: role),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: TextStyle(color: cs.onPrimary),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: _markdownStyle(context, role),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _Avatar(isUser: true, role: role),
          ],
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 30)).slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: index * 30),
          duration: 300.ms,
        );
  }

  Widget _dot(Color color, int delayMs) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 400.ms);
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context, UserRole role) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final baseStyle = tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant) ??
        const TextStyle();

    return MarkdownStyleSheet(
      p: baseStyle,
      code: baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: cs.surfaceContainerLowest,
        fontSize: (baseStyle.fontSize ?? 14) - 1,
      ),
      codeblockDecoration: BoxDecoration(
        color: role == UserRole.technical
            ? const Color(0xFF161B22)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: cs.primary, width: 3)),
      ),
      strong: baseStyle.copyWith(fontWeight: FontWeight.w700),
      listBullet: baseStyle,
      h1: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      h2: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      h3: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isUser;
  final UserRole role;

  const _Avatar({required this.isUser, required this.role});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? cs.primaryContainer : cs.secondaryContainer,
      child: Text(
        isUser ? 'U' : 'A',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isUser ? cs.primary : cs.secondary,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final UserRole role;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                style: role == UserRole.technical
                    ? tt.bodyMedium?.copyWith(fontFamily: 'monospace')
                    : tt.bodyLarge,
                decoration: InputDecoration(
                  hintText: _hint(role),
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: sending
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : FilledButton(
                      onPressed: onSend,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.send_rounded, size: 20),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _hint(UserRole role) {
    switch (role) {
      case UserRole.executive:
        return 'Brief me on…';
      case UserRole.technical:
        return r'$ ask april-ai...';
      case UserRole.general:
        return 'What can I help you with?';
    }
  }
}

class _EmptyState extends StatelessWidget {
  final UserRole role;
  final ValueChanged<String> onSend;

  const _EmptyState({required this.role, required this.onSend});

  List<String> get _suggestions {
    switch (role) {
      case UserRole.executive:
        return [
          'Summarize my pipeline performance this week',
          'What are my highest-priority tasks today?',
          'Draft a response to the investor email',
          'What meetings do I have this afternoon?',
        ];
      case UserRole.technical:
        return [
          'Review open GitHub PRs and flag blockers',
          'How do I fix a race condition in async Dart?',
          'Generate a bash script to build and deploy Docker',
          'Explain the difference between isolates and threads',
        ];
      case UserRole.general:
        return [
          'Remind me to take my medication at 8 PM',
          'How do I send a photo on WhatsApp?',
          'What will the weather be like this weekend?',
          'Help me write a birthday message for my friend',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              size: 40,
              color: cs.primary,
            ),
          ).animate().fadeIn().scale(
                begin: const Offset(0.8, 0.8),
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 16),
          Text(
            'How can I help?',
            style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            'I\'m your ${role.displayName.toLowerCase()} AI assistant. Ask me anything.',
            style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._suggestions.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => onSend(e.value),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(e.value, style: tt.bodyMedium),
                          ),
                          Icon(
                            Icons.north_east_rounded,
                            size: 16,
                            color: cs.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 200 + e.key * 60)),
              ),
        ],
      ),
    );
  }
}
