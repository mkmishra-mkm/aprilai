import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class _Task {
  final String title;
  final String tag;
  final Color tagColor;
  final String dueLabel;
  bool done;

  _Task({
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.dueLabel,
    this.done = false,
  });
}

class PriorityTasksWidget extends StatefulWidget {
  const PriorityTasksWidget({super.key});

  @override
  State<PriorityTasksWidget> createState() => _PriorityTasksWidgetState();
}

class _PriorityTasksWidgetState extends State<PriorityTasksWidget> {
  final _tasks = [
    _Task(
      title: 'Approve Q4 budget allocation',
      tag: 'Finance',
      tagColor: const Color(0xFF34A853),
      dueLabel: 'Today',
    ),
    _Task(
      title: 'Review product roadmap v2',
      tag: 'Product',
      tagColor: const Color(0xFF1A73E8),
      dueLabel: 'Today',
    ),
    _Task(
      title: 'Sign partnership agreement',
      tag: 'Legal',
      tagColor: const Color(0xFFEA4335),
      dueLabel: 'Today',
    ),
    _Task(
      title: 'Prepare board deck slides 12–18',
      tag: 'Strategy',
      tagColor: const Color(0xFF9C27B0),
      dueLabel: 'By 1 PM',
    ),
    _Task(
      title: 'Reply to Series B investor email',
      tag: 'Investors',
      tagColor: const Color(0xFFFF6D00),
      dueLabel: 'Tomorrow',
      done: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final pending = _tasks.where((t) => !t.done).length;

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
                  'Priority Tasks',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pending pending',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._tasks.asMap().entries.map(
                  (e) => _TaskRow(
                    task: e.value,
                    onToggle: () => setState(() => e.value.done = !e.value.done),
                    index: e.key,
                  ),
                ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _TaskRow extends StatelessWidget {
  final _Task task;
  final VoidCallback onToggle;
  final int index;

  const _TaskRow({required this.task, required this.onToggle, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.done ? cs.primary : cs.outline,
                  width: 2,
                ),
                color: task.done ? cs.primary : Colors.transparent,
              ),
              child: task.done
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: tt.bodySmall?.copyWith(
                    decoration: task.done ? TextDecoration.lineThrough : null,
                    color: task.done ? cs.outline : cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: task.tagColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.tag,
                        style: tt.labelSmall?.copyWith(
                          color: task.tagColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.dueLabel,
                      style: tt.labelSmall?.copyWith(color: cs.outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.drag_indicator,
            size: 18,
            color: cs.outlineVariant,
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 250 + index * 50));
  }
}
