import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/screens/chat_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/role_selection_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/reminders/screens/reminders_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../constants/app_constants.dart';
import '../providers/user_configuration_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingComplete = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    redirect: (context, state) {
      final isSplash = state.matchedLocation == AppConstants.routeSplash;
      if (isSplash) return null;

      final isOnboarding = state.matchedLocation.startsWith('/onboarding');
      if (!onboardingComplete && !isOnboarding) {
        return AppConstants.routeOnboarding;
      }
      if (onboardingComplete && isOnboarding) {
        return AppConstants.routeDashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeOnboarding,
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: 'role',
            builder: (context, state) => const RoleSelectionScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppConstants.routeDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSettings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAssistant,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: AppConstants.routeReminders,
        builder: (context, state) => const RemindersScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
