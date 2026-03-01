import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CodeSnippetsWidget extends StatefulWidget {
  const CodeSnippetsWidget({super.key});

  @override
  State<CodeSnippetsWidget> createState() => _CodeSnippetsWidgetState();
}

class _CodeSnippetsWidgetState extends State<CodeSnippetsWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _snippets = [
    _Snippet(
      label: 'Python',
      icon: Icons.code,
      content: '''```python
# April AI — data analysis helper
import pandas as pd
from april_ai import assistant

df = pd.read_csv("metrics.csv")
summary = assistant.summarize(df)
print(summary.insight)
```''',
    ),
    _Snippet(
      label: 'Shell',
      icon: Icons.terminal,
      content: '''```bash
#!/bin/bash
# Deploy April AI backend
docker build -t aprilai:latest .
docker push gcr.io/project/aprilai:latest
kubectl rollout restart deployment/aprilai
echo "Deployment complete ✔"
```''',
    ),
    _Snippet(
      label: 'Notes',
      icon: Icons.sticky_note_2_outlined,
      content: '''## Sprint 14 Notes

**Goal:** Ship AI assistant v1.2

- [x] Role-based UI complete
- [x] Theme factory implemented
- [ ] LLM streaming responses
- [ ] Integration tests

> Run `flutter test` before pushing to `main`.
''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _snippets.length, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Snippets & Notes',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: cs.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tab,
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: _snippets
                .map((s) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.icon, size: 14),
                          const SizedBox(width: 6),
                          Text(s.label, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tab,
              children: _snippets.map((s) => _SnippetView(snippet: s)).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }
}

class _Snippet {
  final String label;
  final IconData icon;
  final String content;
  const _Snippet({required this.label, required this.icon, required this.content});
}

class _SnippetView extends StatelessWidget {
  final _Snippet snippet;
  const _SnippetView({required this.snippet});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Markdown(
          data: snippet.content,
          padding: const EdgeInsets.all(12),
          styleSheet: MarkdownStyleSheet(
            code: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFFE6EDF3),
              backgroundColor: Color(0xFF161B22),
            ),
            codeblockDecoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            p: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 12, height: 1.6),
            h2: const TextStyle(
                color: Color(0xFFE6EDF3),
                fontSize: 14,
                fontWeight: FontWeight.w700),
            listBullet: const TextStyle(color: Color(0xFF8B949E)),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                  left: BorderSide(color: const Color(0xFF30363D), width: 3)),
              color: Colors.transparent,
            ),
            blockquote: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
            checkbox: const TextStyle(color: Color(0xFF3FB950)),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.copy_outlined, size: 14),
            color: const Color(0xFF8B949E),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: snippet.content)),
          ),
        ),
      ],
    );
  }
}
