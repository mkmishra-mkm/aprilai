import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/models/user_configuration.dart';
import '../../../core/providers/user_configuration_provider.dart';
import '../models/message.dart';

abstract class LlmService {
  Future<String> sendMessage({
    required List<Message> history,
    required String userMessage,
    required UserRole role,
  });

  String get providerName;
}

// ── Gemini implementation ────────────────────────────────────────────────────

class GeminiLlmService implements LlmService {
  final String apiKey;
  static const _model = 'gemini-1.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  const GeminiLlmService({required this.apiKey});

  @override
  String get providerName => 'Google Gemini';

  @override
  Future<String> sendMessage({
    required List<Message> history,
    required String userMessage,
    required UserRole role,
  }) async {
    final systemInstruction = _systemPrompt(role);

    final contents = [
      ...history
          .where((m) => !m.isLoading && m.role != MessageRole.system)
          .map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'model',
                'parts': [
                  {'text': m.content}
                ],
              }),
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      },
    ];

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    });

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw LlmException(
        'Gemini API error ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (json['candidates'] as List?)
        ?.firstOrNull?['content']?['parts']
        ?.firstOrNull?['text'] as String?;

    return text ?? 'No response generated.';
  }
}

// ── OpenAI implementation ────────────────────────────────────────────────────

class OpenAiLlmService implements LlmService {
  final String apiKey;
  static const _model = 'gpt-4o-mini';
  static const _baseUrl = 'https://api.openai.com/v1/chat/completions';

  const OpenAiLlmService({required this.apiKey});

  @override
  String get providerName => 'OpenAI GPT';

  @override
  Future<String> sendMessage({
    required List<Message> history,
    required String userMessage,
    required UserRole role,
  }) async {
    final messages = [
      {'role': 'system', 'content': _systemPrompt(role)},
      ...history
          .where((m) => !m.isLoading && m.role != MessageRole.system)
          .map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              }),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 1024,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw LlmException(
        'OpenAI API error ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['choices'] as List?)
            ?.firstOrNull?['message']?['content'] as String? ??
        'No response generated.';
  }
}

// ── Anthropic implementation ─────────────────────────────────────────────────

class AnthropicLlmService implements LlmService {
  final String apiKey;
  static const _model = 'claude-3-haiku-20240307';
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';

  const AnthropicLlmService({required this.apiKey});

  @override
  String get providerName => 'Anthropic Claude';

  @override
  Future<String> sendMessage({
    required List<Message> history,
    required String userMessage,
    required UserRole role,
  }) async {
    final messages = [
      ...history
          .where((m) => !m.isLoading && m.role != MessageRole.system)
          .map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              }),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'system': _systemPrompt(role),
        'messages': messages,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode != 200) {
      throw LlmException(
        'Anthropic API error ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['content'] as List?)?.firstOrNull?['text'] as String? ??
        'No response generated.';
  }
}

// ── Mock implementation (no API key needed for demos) ────────────────────────

class MockLlmService implements LlmService {
  @override
  String get providerName => 'Demo Mode';

  @override
  Future<String> sendMessage({
    required List<Message> history,
    required String userMessage,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockResponse(userMessage, role);
  }

  String _mockResponse(String query, UserRole role) {
    switch (role) {
      case UserRole.executive:
        return '**Summary:** Based on your query, here are the key action items:\n\n'
            '1. Schedule a follow-up with the stakeholders by EOD\n'
            '2. Review the attached metrics before the 2 PM board meeting\n'
            '3. Delegate the operational details to your team lead\n\n'
            '*Estimated time to resolve: 45 minutes*';
      case UserRole.technical:
        return '```bash\n# Recommended approach:\ngit checkout -b feat/solution\n'
            'npm run build && npm test\n```\n\n'
            'The issue stems from a race condition in the async handler. '
            'Consider using `async/await` with proper error boundaries. '
            'Relevant: [StackOverflow #48291](https://stackoverflow.com)';
      case UserRole.general:
        return 'Of course! I\'d be happy to help you with that. 😊\n\n'
            'Here\'s what you need to do, step by step:\n\n'
            '**Step 1:** Open the app on your phone\n'
            '**Step 2:** Tap the big blue button at the bottom\n'
            '**Step 3:** Follow the simple instructions on screen\n\n'
            'If you need any more help, just ask me!';
    }
  }
}

// ── System prompt per role ───────────────────────────────────────────────────

String _systemPrompt(UserRole role) {
  switch (role) {
    case UserRole.executive:
      return '''You are April AI, a premium executive productivity assistant. 
Your communication style is: formal, concise, action-oriented, and data-driven. 
Always respond with structured insights, bullet points, and clear next steps. 
Prioritize time sensitivity. Keep responses under 150 words unless detail is explicitly requested.
Integrations available: Outlook, Salesforce, LinkedIn, Google Calendar.''';
    case UserRole.technical:
      return '''You are April AI, a technical productivity assistant for developers.
Your communication style is: concise, literal, data-heavy, code-first. 
Always prefer code examples over prose. Use markdown formatting with proper code blocks.
Integrations available: GitHub, Jira, StackOverflow, Docker.
When relevant, include CLI commands, API references, or code snippets.''';
    case UserRole.general:
      return '''You are April AI, a friendly and empathetic assistant.
Your communication style is: warm, patient, step-by-step, avoiding jargon.
Always break down complex tasks into simple numbered steps.
Use encouraging language. Keep sentences short and clear.
If the user seems frustrated, acknowledge their feelings first before helping.
Integrations available: Google Photos, WhatsApp, Reminders, Maps.''';
  }
}

// ── Factory ──────────────────────────────────────────────────────────────────

class LlmServiceFactory {
  static LlmService create({
    required String provider,
    String? apiKey,
  }) {
    if (apiKey == null || apiKey.isEmpty) {
      return MockLlmService();
    }
    switch (provider) {
      case 'gemini':
        return GeminiLlmService(apiKey: apiKey);
      case 'openai':
        return OpenAiLlmService(apiKey: apiKey);
      case 'anthropic':
        return AnthropicLlmService(apiKey: apiKey);
      default:
        return MockLlmService();
    }
  }
}

// ── Exception ────────────────────────────────────────────────────────────────

class LlmException implements Exception {
  final String message;
  const LlmException(this.message);

  @override
  String toString() => 'LlmException: $message';
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

final llmServiceProvider = Provider<LlmService>((ref) {
  final config = ref.watch(userConfigurationProvider);
  return LlmServiceFactory.create(
    provider: config.preferredLlmProvider,
    apiKey: config.llmApiKey,
  );
});

// ── Chat state ────────────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<List<Message>> {
  @override
  List<Message> build() => [];

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = Message.user(text.trim());
    state = [...state, userMsg, Message.loading()];

    final llm = ref.read(llmServiceProvider);
    final role = ref.read(userRoleProvider);

    try {
      final response = await llm.sendMessage(
        history: state.where((m) => !m.isLoading).toList(),
        userMessage: text.trim(),
        role: role,
      );
      state = [
        ...state.where((m) => !m.isLoading),
        Message.assistant(response),
      ];
    } catch (e) {
      state = [
        ...state.where((m) => !m.isLoading),
        Message.assistant('⚠️ Error: ${e.toString()}'),
      ];
    }
  }

  void clearHistory() => state = [];
}

final chatProvider = NotifierProvider<ChatNotifier, List<Message>>(
  ChatNotifier.new,
);
