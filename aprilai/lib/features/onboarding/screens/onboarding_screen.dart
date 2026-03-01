import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/user_configuration_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(userConfigurationProvider.notifier)
          .setUserName(_nameController.text.trim());
      context.go(AppConstants.routeRoleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo mark
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 32),
                Text('Welcome to', style: tt.bodyLarge?.copyWith(color: cs.outline))
                    .animate()
                    .fadeIn(delay: 100.ms),
                Text(
                  'April AI',
                  style: tt.displayLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, delay: 200.ms),
                const SizedBox(height: 12),
                Text(
                  'Your productivity assistant that adapts to how you work. Let\'s get started.',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant, height: 1.6),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 48),
                Text(
                  'What should we call you?',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                  onFieldSubmitted: (_) => _continue(),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 40),
                _OnboardingFeatureRow(
                  icon: Icons.auto_awesome,
                  title: 'Role-Adaptive UI',
                  subtitle: 'The interface reshapes around your work style.',
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0, delay: 600.ms),
                const SizedBox(height: 16),
                _OnboardingFeatureRow(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI-Powered Assistant',
                  subtitle: 'Powered by leading LLMs – Gemini, GPT, or Claude.',
                ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2, end: 0, delay: 700.ms),
                const SizedBox(height: 16),
                _OnboardingFeatureRow(
                  icon: Icons.lock_outline,
                  title: 'Privacy First',
                  subtitle: 'Your data stays on device. API keys are never shared.',
                ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2, end: 0, delay: 800.ms),
                const SizedBox(height: 56),
                FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ).animate().fadeIn(delay: 900.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingFeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: cs.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
