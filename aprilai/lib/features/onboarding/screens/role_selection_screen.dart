import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_configuration.dart';
import '../../../core/providers/user_configuration_provider.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;

  Future<void> _confirmRole() async {
    if (_selectedRole == null) return;
    final notifier = ref.read(userConfigurationProvider.notifier);
    await notifier.setRole(_selectedRole!);
    await notifier.completeOnboarding();
    if (mounted) context.go(AppConstants.routeDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final userName = ref.watch(userConfigurationProvider).userName ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi $userName 👋',
                    style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    'How do you work best? Choose a role and April AI will adapt its entire interface for you.',
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                  ).animate().fadeIn(delay: 150.ms),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _RoleCard(
                    role: UserRole.executive,
                    selected: _selectedRole == UserRole.executive,
                    onTap: () => setState(() => _selectedRole = UserRole.executive),
                    accentColor: const Color(0xFF1A3C5E),
                    features: const [
                      'Calendar & daily briefings',
                      'Priority task management',
                      'Outlook, Salesforce, LinkedIn',
                      'Formal AI tone, executive summaries',
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0, delay: 200.ms),
                  const SizedBox(height: 16),
                  _RoleCard(
                    role: UserRole.technical,
                    selected: _selectedRole == UserRole.technical,
                    onTap: () => setState(() => _selectedRole = UserRole.technical),
                    accentColor: const Color(0xFF00E5FF),
                    features: const [
                      'Dark terminal-style interface',
                      'Markdown & code snippet support',
                      'GitHub, Jira, StackOverflow',
                      'Concise, data-heavy AI output',
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0, delay: 300.ms),
                  const SizedBox(height: 16),
                  _RoleCard(
                    role: UserRole.general,
                    selected: _selectedRole == UserRole.general,
                    onTap: () => setState(() => _selectedRole = UserRole.general),
                    accentColor: const Color(0xFF00897B),
                    features: const [
                      'Large touch-friendly buttons',
                      'Voice assistant interface',
                      'Google Photos, WhatsApp, Reminders',
                      'Empathetic, step-by-step AI guidance',
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15, end: 0, delay: 400.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: FilledButton(
                onPressed: _selectedRole != null ? _confirmRole : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedRole != null
                      ? 'Continue as ${_selectedRole!.displayName}'
                      : 'Select a role to continue',
                ),
              ).animate().fadeIn(delay: 500.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  final List<String> features;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
    required this.accentColor,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? accentColor : cs.outlineVariant,
          width: selected ? 2.5 : 1,
        ),
        color: selected
            ? accentColor.withValues(alpha: 0.06)
            : cs.surfaceContainerLowest,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        role.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.displayName,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected ? accentColor : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? accentColor : cs.outline,
                        width: 2,
                      ),
                      color: selected ? accentColor : Colors.transparent,
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: selected ? accentColor : cs.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
