import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_configuration.dart';
import '../../../core/providers/reminder_provider.dart';
import '../../../core/providers/user_configuration_provider.dart';
import '../../../core/services/google_calendar_service.dart';
import '../../assistant/services/llm_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _apiKeyVisible = false;
  bool _googleCalendarLoading = false;
  final _googleCalendarService = GoogleCalendarService();

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
                color: config.llmApiKey?.isNotEmpty == true ? Colors.green : cs.error,
              ),
            ),
            trailing: TextButton(
              onPressed: () => _showApiKeyDialog(context, config),
              child: const Text('Edit'),
            ),
          ).animate().fadeIn(delay: 175.ms),

          // Google Calendar
          _SectionHeader(label: 'Google Calendar'),
          _GoogleCalendarTile(
            config: config,
            isLoading: _googleCalendarLoading,
            onConnect: _connectGoogleCalendar,
            onDisconnect: _disconnectGoogleCalendar,
          ).animate().fadeIn(delay: 200.ms),

          // Other integrations
          _SectionHeader(label: 'Other Integrations'),
          ...(AppConstants.roleIntegrations[config.role.name] ?? [])
              .where((i) => i != 'Google Calendar')
              .toList()
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
                ).animate().fadeIn(delay: Duration(milliseconds: 220 + e.key * 40)),
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
            title: Text('Reset & Re-onboard', style: TextStyle(color: cs.error)),
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

  Future<void> _connectGoogleCalendar() async {
    setState(() => _googleCalendarLoading = true);
    try {
      final email = await _googleCalendarService.signIn();
      if (email != null && mounted) {
        await ref.read(userConfigurationProvider.notifier).setGoogleCalendarConnected(
              connected: true,
              email: email,
            );
        await ref.read(reminderProvider.notifier).syncToGoogleCalendar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected as $email. Reminders synced to Google Calendar.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sign-in cancelled or failed. Make sure Google OAuth credentials are configured in your app.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _googleCalendarLoading = false);
    }
  }

  Future<void> _disconnectGoogleCalendar() async {
    await _googleCalendarService.signOut();
    await ref.read(userConfigurationProvider.notifier).setGoogleCalendarConnected(connected: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disconnected from Google Calendar'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showApiKeyDialog(BuildContext context, UserConfiguration config) async {
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _apiKeyVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your key is stored locally and never shared.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final key = _apiKeyController.text.trim();
              await ref.read(userConfigurationProvider.notifier).setLlmApiKey(key);
              // Reset chat so it picks up the new key
              ref.invalidate(chatProvider);
              if (ctx.mounted) Navigator.pop(ctx);
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
        title: const Text('Reset everything?'),
        content: const Text(
          'This will clear your name, role, API key, and all settings. '
          'You will go through onboarding again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(userConfigurationProvider.notifier).resetConfiguration();
      ref.invalidate(chatProvider);
      // ignore: use_build_context_synchronously
      if (mounted) context.go(AppConstants.routeSplash);
    }
  }
}

// ── Google Calendar tile ──────────────────────────────────────────────────────

class _GoogleCalendarTile extends StatelessWidget {
  final UserConfiguration config;
  final bool isLoading;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _GoogleCalendarTile({
    required this.config,
    required this.isLoading,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final connected = config.googleCalendarConnected;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: connected
              ? const Color(0xFF1A73E8).withValues(alpha: 0.12)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.calendar_month_outlined,
          color: connected ? const Color(0xFF1A73E8) : cs.onSurfaceVariant,
        ),
      ),
      title: const Text('Google Calendar'),
      subtitle: Text(
        connected
            ? 'Connected as ${config.googleAccountEmail ?? "your account"}\nReminders sync automatically'
            : 'Connect to sync reminders to Google Calendar',
        style: tt.bodySmall?.copyWith(
          color: connected ? Colors.green : cs.onSurfaceVariant,
        ),
      ),
      isThreeLine: connected,
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: connected ? onDisconnect : onConnect,
              style: connected ? TextButton.styleFrom(foregroundColor: cs.error) : null,
              child: Text(connected ? 'Disconnect' : 'Connect'),
            ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

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
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Profile tile ──────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  final UserConfiguration config;
  const _ProfileTile({required this.config});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = config.userName ?? 'Unknown User';
    final initials = name.trim().split(' ').take(2).map((s) => s[0]).join().toUpperCase();

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: cs.primaryContainer,
        child: Text(
          initials,
          style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
        ),
      ),
      title: Text(name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
        config.role.displayName,
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

// ── Role picker ───────────────────────────────────────────────────────────────

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
        children: UserRole.values.map((role) {
          final selected = role == currentRole;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer : cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: selected ? Border.all(color: cs.primary, width: 1.5) : null,
            ),
            child: ListTile(
              leading: Text(role.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(
                role.displayName,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(role.description, style: tt.bodySmall),
              trailing: selected ? Icon(Icons.check_circle, color: cs.primary) : null,
              onTap: () => onRoleSelected(role),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── LLM provider picker ───────────────────────────────────────────────────────

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
          Text('AI Provider', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentProvider,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
