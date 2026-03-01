# April AI

A cross-platform productivity assistant built with Flutter that **adapts its entire UI, tone, and integrations** based on the user's selected role.

---

## Features

### Three Adaptive Roles

| Feature | Executive | Technical | General / Senior |
|---|---|---|---|
| **Primary View** | Calendar & Priority Tasks | Terminal & Code Snippets | Voice Assistant & Big Buttons |
| **AI Tone** | Formal, brief, action-oriented | Concise, literal, data-heavy | Empathetic, step-by-step |
| **Integrations** | Outlook, Salesforce, LinkedIn | GitHub, Jira, StackOverflow | Google Photos, WhatsApp, Reminders |
| **Visual Density** | Medium (clean) | High (data-rich, dark mode) | Low (focus-heavy, large targets) |
| **Theme** | Light, Inter font, Material 3 | Dark (#0D1117), JetBrains Mono | Light, Nunito, high-contrast |

### Architecture Highlights

- **Clean Architecture** — UI, state, and AI logic are fully separated
- **Riverpod** state management — role switching is instant, no restart needed
- **ThemeFactory** — generates the complete `ThemeData` per role at runtime
- **LLM-agnostic service layer** — swap between Gemini, OpenAI, Anthropic, or Ollama via Settings
- **Material 3** (Android) and **Cupertino**-friendly layout standards
- **go_router** for declarative navigation with onboarding guard

---

## Project Structure

```
lib/
├── main.dart                          # Entry point
├── app.dart                           # MaterialApp.router, theme binding
├── core/
│   ├── constants/app_constants.dart   # Route names, provider list, integrations
│   ├── models/user_configuration.dart # UserRole enum + UserConfiguration model
│   ├── providers/                     # Riverpod NotifierProvider for config
│   ├── router/app_router.dart         # GoRouter with onboarding redirect guard
│   └── theme/app_theme.dart          # ThemeFactory — forRole(UserRole) → ThemeData
└── features/
    ├── onboarding/
    │   └── screens/
    │       ├── splash_screen.dart          # Animated logo, auto-navigates
    │       ├── onboarding_screen.dart      # Name entry + feature highlights
    │       └── role_selection_screen.dart  # Role picker cards (Executive/Technical/General)
    ├── dashboard/
    │   ├── screens/dashboard_screen.dart   # Role-switching container (IndexedStack)
    │   └── widgets/
    │       ├── executive/
    │       │   ├── daily_briefing_widget.dart   # AI summary, metrics strip
    │       │   ├── calendar_widget.dart         # Today's schedule with NOW indicator
    │       │   └── priority_tasks_widget.dart   # Checkable task list with tags
    │       ├── technical/
    │       │   ├── terminal_log_widget.dart     # Terminal chrome, log lines, input
    │       │   ├── code_snippets_widget.dart    # Tabbed markdown/code viewer
    │       │   └── integrations_widget.dart     # GitHub/Jira/SO status list
    │       └── general/
    │           ├── voice_assistant_widget.dart  # Animated mic button + suggestions
    │           └── simple_task_button.dart      # Large-touch action buttons + grid
    ├── settings/
    │   └── screens/settings_screen.dart   # Role picker, LLM provider, API key, integrations
    └── assistant/
        ├── models/message.dart             # Message model (user/assistant/loading)
        ├── services/llm_service.dart       # Gemini/OpenAI/Anthropic/Mock + ChatNotifier
        └── screens/chat_screen.dart        # Full chat UI with markdown rendering
```

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.27.4
- Dart SDK ≥ 3.6.2

### Install & Run

```bash
cd aprilai
flutter pub get
flutter run                    # Runs on connected device / emulator
flutter run -d chrome          # Runs as web app
flutter build web              # Production web build
```

### LLM Configuration

The app ships in **Demo Mode** (no API key needed). To enable a real LLM:

1. Open the app → Settings → AI Provider
2. Select your preferred provider (Gemini, OpenAI, or Anthropic)
3. Tap **Edit** next to API Key and enter your key
4. Your key is stored locally via `shared_preferences` — never transmitted elsewhere

#### Supported Providers

| Provider | Model | API Key format |
|---|---|---|
| Google Gemini | gemini-1.5-flash | `AIza...` |
| OpenAI | gpt-4o-mini | `sk-...` |
| Anthropic Claude | claude-3-haiku | `sk-ant-...` |
| Ollama (local) | demo mode | — |

---

## Role-Based UI Details

### Executive
- Light theme, Inter typeface, medium density
- `NavigationRail` on tablet, `NavigationBar` on mobile
- DailyBriefingWidget with AI-generated summary + metric chips
- CalendarWidget with real-time NOW indicator
- PriorityTasksWidget with department tags and tap-to-complete

### Technical
- Dark theme (#0D1117), JetBrains Mono typeface, high density
- Terminal widget with macOS-style window chrome, live log, command input
- Tabbed code/markdown snippet viewer (Python, Shell, Notes)
- Integration status panel (GitHub, Jira, StackOverflow, Docker)

### General / Senior
- High-contrast light theme, Nunito typeface, large touch targets (≥64 dp)
- Large animated microphone button with pulse rings
- 2-column big-button action grid with icon + label
- Simplified `NavigationBar` with clear labels

---

## State Management

```dart
// Instantly switch role — UI rebuilds without restart
ref.read(userConfigurationProvider.notifier).setRole(UserRole.technical);
```

`UserConfigurationNotifier` persists state to `SharedPreferences` on every mutation. The `appRouterProvider` watches `onboardingCompleteProvider` and redirects automatically.

---

## Extending the AI Layer

The `LlmService` abstract class makes adding new providers trivial:

```dart
class MyCustomLlmService implements LlmService {
  @override
  String get providerName => 'My Provider';

  @override
  Future<String> sendMessage({...}) async {
    // Call your API here
  }
}
```

Register it in `LlmServiceFactory.create()` and add it to `AppConstants.llmProviders`.
