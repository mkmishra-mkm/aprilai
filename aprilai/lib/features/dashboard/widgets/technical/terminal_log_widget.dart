import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class _LogLine {
  final String prefix;
  final String text;
  final Color prefixColor;

  const _LogLine({
    required this.prefix,
    required this.text,
    required this.prefixColor,
  });
}

class TerminalLogWidget extends StatefulWidget {
  const TerminalLogWidget({super.key});

  @override
  State<TerminalLogWidget> createState() => _TerminalLogWidgetState();
}

class _TerminalLogWidgetState extends State<TerminalLogWidget> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<_LogLine> _log = const [
    _LogLine(prefix: '❯', text: 'april-ai init', prefixColor: Color(0xFF00E5FF)),
    _LogLine(prefix: '✔', text: 'Workspace loaded in 0.31s', prefixColor: Color(0xFF3FB950)),
    _LogLine(prefix: 'ℹ', text: 'GitHub connected — 3 open PRs require review', prefixColor: Color(0xFF58A6FF)),
    _LogLine(prefix: 'ℹ', text: 'Jira sprint has 7 tickets — 2 blocked', prefixColor: Color(0xFF58A6FF)),
    _LogLine(prefix: '⚠', text: 'CI pipeline failed on feat/auth-refactor', prefixColor: Color(0xFFD29922)),
    _LogLine(prefix: '✔', text: 'main branch is up to date', prefixColor: Color(0xFF3FB950)),
    _LogLine(prefix: 'ℹ', text: 'Daily standup in 14 minutes', prefixColor: Color(0xFF58A6FF)),
    _LogLine(prefix: '❯', text: 'april-ai status', prefixColor: Color(0xFF00E5FF)),
    _LogLine(prefix: ' ', text: 'Role: Technical  •  LLM: Gemini 1.5 Pro  •  Mode: Dark', prefixColor: Color(0xFF8B949E)),
  ];

  final List<String> _history = ['april-ai init', 'april-ai status'];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _runCommand() {
    final cmd = _controller.text.trim();
    if (cmd.isEmpty) return;
    setState(() {
      _history.add(cmd);
      _log as dynamic; // local mutation not possible; full demo uses mutable list
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Window chrome
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F57)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF28C840)),
                const SizedBox(width: 16),
                Expanded(
                  child: Center(
                    child: Text(
                      'april-ai — terminal',
                      style: tt.labelSmall?.copyWith(
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 14),
                  color: const Color(0xFF8B949E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    final text = _log.map((l) => '${l.prefix} ${l.text}').join('\n');
                    Clipboard.setData(ClipboardData(text: text));
                  },
                ),
              ],
            ),
          ),
          // Log content
          Container(
            height: 200,
            padding: const EdgeInsets.all(14),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _log.length,
              itemBuilder: (context, i) {
                final line = _log[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.prefix,
                        style: tt.bodySmall?.copyWith(
                          color: line.prefixColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          line.text,
                          style: tt.bodySmall?.copyWith(
                            color: const Color(0xFFE6EDF3),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 80));
              },
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              border: Border(top: BorderSide(color: const Color(0xFF30363D))),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
            ),
            child: Row(
              children: [
                Text(
                  '❯',
                  style: tt.bodyMedium?.copyWith(
                    color: const Color(0xFF00E5FF),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: tt.bodySmall?.copyWith(
                      color: const Color(0xFFE6EDF3),
                      fontFamily: 'monospace',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type a command…',
                      hintStyle: TextStyle(color: Color(0xFF484F58)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _runCommand(),
                  ),
                ),
                GestureDetector(
                  onTap: _runCommand,
                  child: Icon(
                    Icons.keyboard_return,
                    size: 16,
                    color: const Color(0xFF8B949E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _dot(Color color) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
