import 'package:flutter/foundation.dart';

enum MessageRole { user, assistant, system }

@immutable
class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime createdAt;
  final bool isLoading;

  const Message({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.isLoading = false,
  });

  factory Message.user(String content) => Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: MessageRole.user,
        createdAt: DateTime.now(),
      );

  factory Message.assistant(String content, {bool isLoading = false}) =>
      Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
        isLoading: isLoading,
      );

  factory Message.loading() => Message(
        id: 'loading',
        content: '',
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
        isLoading: true,
      );

  Message copyWith({String? content, bool? isLoading}) => Message(
        id: id,
        content: content ?? this.content,
        role: role,
        createdAt: createdAt,
        isLoading: isLoading ?? this.isLoading,
      );
}
