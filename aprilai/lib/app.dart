import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/user_configuration_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class AprilAIApp extends ConsumerWidget {
  const AprilAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final role = ref.watch(userRoleProvider);
    final theme = AppTheme.forRole(role);

    SystemChrome.setSystemUIOverlayStyle(
      AppTheme.brightnessForRole(role) == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );

    return MaterialApp.router(
      title: 'April AI',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
