import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_configuration.dart';
import '../../../core/providers/user_configuration_provider.dart';
import '../../assistant/services/llm_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _apiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(userConfigurationProvider);
    _apiKeyController.text = config.llmApiKey ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(userConfigurationProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile section
          _SectionHeader(label: 'Profile'),
          _ProfileTile(config: config).animate().fadeIn(delay: 50.ms),

          // Role section
          _SectionHeader(label: 'Role & Appearance'),
          _RolePicker(
            currentRole: config.role,
            onRoleSelected: (role) async {
              await ref.read(userConfigurationProvider.notifier).setRole(role);
            },
          ).animate().fadeIn(delay: 100.ms),

          // LLM section
          _SectionHeader(label: 'AI Assistant'),
          _LlmProviderPicker(
            currentProvider: config.preferredLlmProvider,
            onProviderSelected: (p) async {
              await ref.read(userConfigurationProvider.notifier).setLlmProvider(p);
            },
          ).animate().fadeIn(delay: 150.ms),
          ListTile(
            title: const Text('API Key'),
            subtitle: Text(
              config.llmApiKey?.isNotEmpty == true
                  ? '●●●●●●●●●●●● (set)'
                  : 'Not configured — using demo mode',
              style: tt.bodySmall?.copyWith(
                color: config.llmApiKey?.isNotEmpty == true
                    ? Colors.green
                    : cs.error,
              ),
            ),
            trailing: TextButton(
              onPressed: () => _showApiKeyDialog(context, config),
              child: const Text('Edit'),
            ),
          ).animate().fadeIn(delay: 175.ms),

          // Integrations section
          _SectionHeader(label: 'Integrations'),
          ...(AppConstants.roleIntegrations[config.role.name] ?? [])
              .asMap()
              .entries
              .map(
                (e) => ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: Text(e.value),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Connect'),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 200 + e.key * 40)),
              ),

          // Notifications section
          _SectionHeader(label: 'Notifications'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Daily briefings and task reminders'),
            value: config.notificationsEnabled,
            onChanged: (_) async {
              await ref.read(userConfigurationProvider.notifier).toggleNotifications();
            },
          ).animate().fadeIn(delay: 300.ms),

          // Danger zone
          _SectionHeader(label: 'Account'),
          ListTile(
            leading: Icon(Icons.logout, color: cs.error),
            title: Text('Reset & Re-onboard',
                style: TextStyle(color: cs.error)),
            subtitle: const Text('Clear all settings and start over'),
            onTap: () => _showResetDialog(context),
          ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 32),
          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: tt.labelSmall?.copyWith(color: cs.outline),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _showApiKeyDialog(
      BuildContext context, UserConfiguration config) async {
    final cs = Theme.of(context).colorScheme;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Key'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your ${AppConstants.llmProviderNames[config.preferredLlmProvider]} API key.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: !_apiKeyVisible,
                decoration: InputDecoration(
                  hintText: 'sk-… or AIza…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _apiKeyVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _apiKeyVisible = !_apiKeyVisible),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your key is stored locally and never shared.',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(userConfigurationProvider.notifier)
                  .setLlmApiKey(_apiKeyController.text.trim());
              if (ctx.mounted) ctx.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset April AI'),
        content: const Text(
          'This will clear all your settings, role selection, and chat history. You will need to go through onboarding again.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => ctx.pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(userConfigurationProvider.notifier).resetConfiguration();
      ref.read(chatProvider.notifier).clearHistory();
      // ignore: use_build_context_synchronously
      context.go(AppConstants.routeOnboarding);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final UserConfiguration config;
  const _ProfileTile({required this.config});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = config.userName ?? 'User';
    final initials = name.trim().split(' ').take(2).map((s) => s[0]).join().toUpperCase();

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: cs.primaryContainer,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
      ),
      title: Text(name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
        config.role.displayName,
        style: tt.bodySmall?.copyWith(color: cs.outline),
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  final UserRole currentRole;
  final ValueChanged<UserRole> onRoleSelected;

  const _RolePicker({required this.currentRole, required this.onRoleSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Role',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: UserRole.values.map((role) {
              final selected = role == currentRole;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onRoleSelected(role),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? cs.primary : cs.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(role.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            role.displayName,
                            style: tt.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selected ? cs.primary : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LlmProviderPicker extends StatelessWidget {
  final String currentProvider;
  final ValueChanged<String> onProviderSelected;

  const _LlmProviderPicker({
    required this.currentProvider,
    required this.onProviderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Provider',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentProvider,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: AppConstants.llmProviders
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(AppConstants.llmProviderNames[p] ?? p),
                    ))
                .toList(),
            onChanged: (v) => v != null ? onProviderSelected(v) : null,
          ),
        ],
      ),
    );
  }
}

