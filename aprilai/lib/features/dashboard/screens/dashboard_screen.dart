import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_configuration.dart';
import '../../../core/providers/user_configuration_provider.dart';
import '../widgets/executive/calendar_widget.dart';
import '../widgets/executive/daily_briefing_widget.dart';
import '../widgets/executive/priority_tasks_widget.dart';
import '../widgets/general/simple_task_button.dart';
import '../widgets/general/voice_assistant_widget.dart';
import '../widgets/technical/code_snippets_widget.dart';
import '../widgets/technical/integrations_widget.dart';
import '../widgets/technical/terminal_log_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(userConfigurationProvider);
    final role = config.role;

    return switch (role) {
      UserRole.executive => _ExecutiveDashboard(
          config: config,
          selectedIndex: _selectedIndex,
          onIndexChanged: (i) => setState(() => _selectedIndex = i),
        ),
      UserRole.technical => _TechnicalDashboard(
          config: config,
          selectedIndex: _selectedIndex,
          onIndexChanged: (i) => setState(() => _selectedIndex = i),
        ),
      UserRole.general => _GeneralDashboard(
          config: config,
          selectedIndex: _selectedIndex,
          onIndexChanged: (i) => setState(() => _selectedIndex = i),
        ),
    };
  }
}

// ── Executive Dashboard ─────────────────────────────────────────────────────

class _ExecutiveDashboard extends ConsumerWidget {
  final UserConfiguration config;
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const _ExecutiveDashboard({
    required this.config,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('April AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
          _AvatarButton(
            name: config.userName ?? 'Executive',
            onTap: () => context.push(AppConstants.routeSettings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Side nav rail for wider screens
          if (MediaQuery.of(context).size.width > 600)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onIndexChanged,
              labelType: NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Overview'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: Text('Calendar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.task_alt_outlined),
                  selectedIcon: Icon(Icons.task_alt),
                  label: Text('Tasks'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  selectedIcon: Icon(Icons.smart_toy),
                  label: Text('Assistant'),
                ),
              ],
            ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _ExecutiveBody(selectedIndex: selectedIndex),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onIndexChanged,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Calendar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.task_alt_outlined),
                  selectedIcon: Icon(Icons.task_alt),
                  label: 'Tasks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  selectedIcon: Icon(Icons.smart_toy),
                  label: 'Assistant',
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.routeAssistant),
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Ask April AI'),
      ),
    );
  }
}

class _ExecutiveBody extends StatelessWidget {
  final int selectedIndex;
  const _ExecutiveBody({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: selectedIndex,
      children: [
        // Overview
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const DailyBriefingWidget(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: CalendarWidget()),
                  const SizedBox(width: 12),
                  const Expanded(child: PriorityTasksWidget()),
                ],
              ),
            ],
          ),
        ),
        // Calendar tab
        const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: CalendarWidget(),
        ),
        // Tasks tab
        const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: PriorityTasksWidget(),
        ),
        // Assistant tab
        const _AssistantPlaceholder(),
      ],
    );
  }
}

// ── Technical Dashboard ──────────────────────────────────────────────────────

class _TechnicalDashboard extends ConsumerWidget {
  final UserConfiguration config;
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const _TechnicalDashboard({
    required this.config,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'april-ai',
              style: tt.titleLarge?.copyWith(
                color: const Color(0xFFE6EDF3),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                'v1.0.0',
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push(AppConstants.routeSettings),
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, size: 20),
            onPressed: () => context.push(AppConstants.routeAssistant),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 600)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onIndexChanged,
              labelType: NavigationRailLabelType.selected,
              minWidth: 64,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.terminal_outlined),
                  selectedIcon: Icon(Icons.terminal),
                  label: Text('Terminal'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.code_outlined),
                  selectedIcon: Icon(Icons.code),
                  label: Text('Snippets'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.hub_outlined),
                  selectedIcon: Icon(Icons.hub),
                  label: Text('Integrations'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  selectedIcon: Icon(Icons.smart_toy),
                  label: Text('AI'),
                ),
              ],
            ),
          const VerticalDivider(width: 1, color: Color(0xFF30363D)),
          Expanded(
            child: _TechnicalBody(selectedIndex: selectedIndex),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onIndexChanged,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.terminal_outlined),
                  selectedIcon: Icon(Icons.terminal),
                  label: 'Terminal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.code_outlined),
                  selectedIcon: Icon(Icons.code),
                  label: 'Snippets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.hub_outlined),
                  selectedIcon: Icon(Icons.hub),
                  label: 'Integrations',
                ),
                NavigationDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  selectedIcon: Icon(Icons.smart_toy),
                  label: 'AI',
                ),
              ],
            )
          : null,
    );
  }
}

class _TechnicalBody extends StatelessWidget {
  final int selectedIndex;
  const _TechnicalBody({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: selectedIndex,
      children: [
        // Terminal tab
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const TerminalLogWidget(),
              const SizedBox(height: 12),
              const IntegrationsWidget(),
            ],
          ),
        ),
        // Snippets
        const SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: CodeSnippetsWidget(),
        ),
        // Integrations
        const SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: IntegrationsWidget(),
        ),
        // AI Assistant
        const _AssistantPlaceholder(),
      ],
    );
  }
}

// ── General Dashboard ────────────────────────────────────────────────────────

class _GeneralDashboard extends ConsumerWidget {
  final UserConfiguration config;
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const _GeneralDashboard({
    required this.config,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('April AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 28),
            onPressed: () => context.push(AppConstants.routeSettings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          // Home — voice first
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const VoiceAssistantWidget(),
                const SizedBox(height: 20),
                SimpleTaskButton(
                  label: 'Add a Reminder',
                  icon: Icons.alarm_add_rounded,
                  color: cs.primary,
                ),
                const SizedBox(height: 12),
                SimpleTaskButton(
                  label: 'Ask a Question',
                  icon: Icons.help_outline_rounded,
                  color: const Color(0xFF6A1B9A),
                  onTap: () => context.push(AppConstants.routeAssistant),
                ),
              ],
            ),
          ),
          // Actions grid
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: const BigActionGrid(),
          ),
          // Assistant
          const _AssistantPlaceholder(),
          // Settings shortcut
          const _GeneralSettingsShortcut(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onIndexChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Actions',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'April AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _GeneralSettingsShortcut extends StatelessWidget {
  const _GeneralSettingsShortcut();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => context.push(AppConstants.routeSettings),
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

class _AvatarButton extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _AvatarButton({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = name.trim().split(' ').take(2).map((s) => s[0]).join();
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: cs.primaryContainer,
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _AssistantPlaceholder extends StatelessWidget {
  const _AssistantPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, size: 64, color: cs.primary),
          const SizedBox(height: 16),
          Text('April AI Assistant', style: tt.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to start a conversation',
            style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push(AppConstants.routeAssistant),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Open Chat'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(200, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
