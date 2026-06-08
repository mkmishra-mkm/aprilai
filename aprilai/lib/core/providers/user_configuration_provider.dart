import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_configuration.dart';

const _kConfigKey = 'user_configuration';

class UserConfigurationNotifier extends Notifier<UserConfiguration> {
  @override
  UserConfiguration build() {
    _loadFromPrefs();
    return const UserConfiguration();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kConfigKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = UserConfiguration.fromJson(json);
      } catch (_) {
        state = const UserConfiguration();
      }
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kConfigKey, jsonEncode(state.toJson()));
  }

  Future<void> setRole(UserRole role) async {
    state = state.copyWith(role: role);
    await _persist();
  }

  Future<void> setUserName(String name) async {
    state = state.copyWith(userName: name);
    await _persist();
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingComplete: true);
    await _persist();
  }

  Future<void> setLlmProvider(String provider) async {
    state = state.copyWith(preferredLlmProvider: provider);
    await _persist();
  }

  Future<void> setLlmApiKey(String key) async {
    state = state.copyWith(llmApiKey: key);
    await _persist();
  }

  Future<void> toggleNotifications() async {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
    await _persist();
  }

  Future<void> setGoogleCalendarConnected({
    required bool connected,
    String? email,
  }) async {
    state = state.copyWith(
      googleCalendarConnected: connected,
      googleAccountEmail: connected ? email : null,
    );
    await _persist();
  }

  Future<void> resetConfiguration() async {
    state = const UserConfiguration();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kConfigKey);
  }
}

final userConfigurationProvider =
    NotifierProvider<UserConfigurationNotifier, UserConfiguration>(
  UserConfigurationNotifier.new,
);

final userRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(userConfigurationProvider).role;
});

final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(userConfigurationProvider).onboardingComplete;
});
