import 'package:flutter/foundation.dart';

enum UserRole {
  executive,
  technical,
  general,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.executive:
        return 'Executive';
      case UserRole.technical:
        return 'Technical';
      case UserRole.general:
        return 'General';
    }
  }

  String get description {
    switch (this) {
      case UserRole.executive:
        return 'High-density data, calendar integration, and executive summaries.';
      case UserRole.technical:
        return 'Dark mode, markdown support, terminal actions, and dev integrations.';
      case UserRole.general:
        return 'Large touch targets, high-contrast text, and voice-first interface.';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.executive:
        return '💼';
      case UserRole.technical:
        return '⌨️';
      case UserRole.general:
        return '🌟';
    }
  }

  String get toKey => name;

  static UserRole fromKey(String key) {
    return UserRole.values.firstWhere(
      (r) => r.name == key,
      orElse: () => UserRole.general,
    );
  }
}

@immutable
class UserConfiguration {
  final String? userName;
  final UserRole role;
  final bool onboardingComplete;
  final String preferredLlmProvider;
  final bool notificationsEnabled;
  final String? llmApiKey;
  final bool googleCalendarConnected;
  final String? googleAccountEmail;

  const UserConfiguration({
    this.userName,
    this.role = UserRole.general,
    this.onboardingComplete = false,
    this.preferredLlmProvider = 'gemini',
    this.notificationsEnabled = true,
    this.llmApiKey,
    this.googleCalendarConnected = false,
    this.googleAccountEmail,
  });

  UserConfiguration copyWith({
    String? userName,
    UserRole? role,
    bool? onboardingComplete,
    String? preferredLlmProvider,
    bool? notificationsEnabled,
    String? llmApiKey,
    bool? googleCalendarConnected,
    String? googleAccountEmail,
  }) {
    return UserConfiguration(
      userName: userName ?? this.userName,
      role: role ?? this.role,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      preferredLlmProvider: preferredLlmProvider ?? this.preferredLlmProvider,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      llmApiKey: llmApiKey ?? this.llmApiKey,
      googleCalendarConnected: googleCalendarConnected ?? this.googleCalendarConnected,
      googleAccountEmail: googleAccountEmail ?? this.googleAccountEmail,
    );
  }

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'role': role.toKey,
        'onboardingComplete': onboardingComplete,
        'preferredLlmProvider': preferredLlmProvider,
        'notificationsEnabled': notificationsEnabled,
        'llmApiKey': llmApiKey,
        'googleCalendarConnected': googleCalendarConnected,
        'googleAccountEmail': googleAccountEmail,
      };

  factory UserConfiguration.fromJson(Map<String, dynamic> json) {
    return UserConfiguration(
      userName: json['userName'] as String?,
      role: UserRoleExtension.fromKey(json['role'] as String? ?? 'general'),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      preferredLlmProvider: json['preferredLlmProvider'] as String? ?? 'gemini',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      llmApiKey: json['llmApiKey'] as String?,
      googleCalendarConnected: json['googleCalendarConnected'] as bool? ?? false,
      googleAccountEmail: json['googleAccountEmail'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserConfiguration &&
          runtimeType == other.runtimeType &&
          userName == other.userName &&
          role == other.role &&
          onboardingComplete == other.onboardingComplete &&
          preferredLlmProvider == other.preferredLlmProvider &&
          notificationsEnabled == other.notificationsEnabled &&
          googleCalendarConnected == other.googleCalendarConnected &&
          googleAccountEmail == other.googleAccountEmail;

  @override
  int get hashCode => Object.hash(
        userName,
        role,
        onboardingComplete,
        preferredLlmProvider,
        notificationsEnabled,
        googleCalendarConnected,
        googleAccountEmail,
      );
}
