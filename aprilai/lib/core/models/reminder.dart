import 'package:flutter/foundation.dart';

enum ReminderRepeat { none, daily, weekly, monthly }

extension ReminderRepeatExtension on ReminderRepeat {
  String get displayName {
    switch (this) {
      case ReminderRepeat.none:
        return 'No repeat';
      case ReminderRepeat.daily:
        return 'Every day';
      case ReminderRepeat.weekly:
        return 'Every week';
      case ReminderRepeat.monthly:
        return 'Every month';
    }
  }

  String get toKey => name;

  static ReminderRepeat fromKey(String key) {
    return ReminderRepeat.values.firstWhere(
      (r) => r.name == key,
      orElse: () => ReminderRepeat.none,
    );
  }
}

@immutable
class Reminder {
  final String id;
  final String title;
  final String? note;
  final DateTime scheduledAt;
  final bool isCompleted;
  final ReminderRepeat repeat;
  final String? googleCalendarEventId;
  final int notificationId;

  const Reminder({
    required this.id,
    required this.title,
    this.note,
    required this.scheduledAt,
    this.isCompleted = false,
    this.repeat = ReminderRepeat.none,
    this.googleCalendarEventId,
    required this.notificationId,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? scheduledAt,
    bool? isCompleted,
    ReminderRepeat? repeat,
    String? googleCalendarEventId,
    int? notificationId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isCompleted: isCompleted ?? this.isCompleted,
      repeat: repeat ?? this.repeat,
      googleCalendarEventId: googleCalendarEventId ?? this.googleCalendarEventId,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'scheduledAt': scheduledAt.toIso8601String(),
        'isCompleted': isCompleted,
        'repeat': repeat.toKey,
        'googleCalendarEventId': googleCalendarEventId,
        'notificationId': notificationId,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String?,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      repeat: ReminderRepeatExtension.fromKey(json['repeat'] as String? ?? 'none'),
      googleCalendarEventId: json['googleCalendarEventId'] as String?,
      notificationId: json['notificationId'] as int? ?? 0,
    );
  }

  bool get isPast => scheduledAt.isBefore(DateTime.now()) && !isCompleted;
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now()) && !isCompleted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Reminder && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
