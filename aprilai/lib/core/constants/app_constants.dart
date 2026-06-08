class AppConstants {
  AppConstants._();

  static const String appName = 'April AI';
  static const String appVersion = '1.0.0';

  // Route names
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeRoleSelection = '/onboarding/role';
  static const String routeDashboard = '/dashboard';
  static const String routeSettings = '/settings';
  static const String routeAssistant = '/assistant';
  static const String routeReminders = '/reminders';
  static const String routeReminderNew = '/reminders/new';

  // LLM providers
  static const List<String> llmProviders = ['gemini', 'openai', 'anthropic', 'ollama'];

  static const Map<String, String> llmProviderNames = {
    'gemini': 'Google Gemini',
    'openai': 'OpenAI GPT',
    'anthropic': 'Anthropic Claude',
    'ollama': 'Ollama (Local)',
  };

  // Integrations per role
  static const Map<String, List<String>> roleIntegrations = {
    'executive': ['Outlook', 'Salesforce', 'LinkedIn', 'Slack', 'Google Calendar'],
    'technical': ['GitHub', 'Jira', 'StackOverflow', 'VS Code', 'Docker'],
    'general': ['Google Photos', 'WhatsApp', 'Reminders', 'Maps', 'Weather'],
  };
}
