import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class _Integration {
  final String name;
  final String status;
  final Color statusColor;
  final IconData icon;
  final String metric;

  const _Integration({
    required this.name,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.metric,
  });
}

class IntegrationsWidget extends StatelessWidget {
  const IntegrationsWidget({super.key});

  static const _integrations = [
    _Integration(
      name: 'GitHub',
      status: 'Connected',
      statusColor: Color(0xFF3FB950),
      icon: Icons.code_rounded,
      metric: '3 PRs open',
    ),
    _Integration(
      name: 'Jira',
      status: 'Connected',
      statusColor: Color(0xFF3FB950),
      icon: Icons.track_changes,
      metric: '7 tickets',
    ),
    _Integration(
      name: 'StackOverflow',
      status: 'Syncing',
      statusColor: Color(0xFFD29922),
      icon: Icons.help_outline,
      metric: '12 saved',
    ),
    _Integration(
      name: 'Docker Hub',
      status: 'Connected',
      statusColor: Color(0xFF3FB950),
      icon: Icons.storage_outlined,
      metric: '4 images',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Integrations',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    'Manage',
                    style: tt.labelSmall?.copyWith(color: cs.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._integrations.asMap().entries.map(
                  (e) => _IntegrationRow(
                    integration: e.value,
                    index: e.key,
                  ),
                ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class _IntegrationRow extends StatelessWidget {
  final _Integration integration;
  final int index;

  const _IntegrationRow({required this.integration, required this.index});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Icon(integration.icon, size: 16, color: const Color(0xFF8B949E)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  integration.name,
                  style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  integration.metric,
                  style: tt.labelSmall?.copyWith(color: const Color(0xFF8B949E)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: integration.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: integration.statusColor,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  integration.status,
                  style: tt.labelSmall?.copyWith(
                    color: integration.statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 60));
  }
}
