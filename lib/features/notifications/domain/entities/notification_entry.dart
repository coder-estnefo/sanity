import 'package:equatable/equatable.dart';

enum NotificationKind { soft, hard }

class NotificationEntry extends Equatable {
  const NotificationEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.kind,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationKind kind;
  final bool isRead;

  NotificationEntry copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    NotificationKind? kind,
    bool? isRead,
  }) =>
      NotificationEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        timestamp: timestamp ?? this.timestamp,
        kind: kind ?? this.kind,
        isRead: isRead ?? this.isRead,
      );

  @override
  List<Object?> get props => [id, title, body, timestamp, kind, isRead];
}

