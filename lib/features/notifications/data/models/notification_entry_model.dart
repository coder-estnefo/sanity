import '../../domain/entities/notification_entry.dart';

class NotificationEntryModel {
  static Map<String, dynamic> toJson(NotificationEntry e) => {
        'id': e.id,
        'title': e.title,
        'body': e.body,
        'timestamp': e.timestamp.toIso8601String(),
        'kind': e.kind.name,
        'isRead': e.isRead,
      };

  static NotificationEntry fromJson(Map<String, dynamic> j) => NotificationEntry(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        kind: NotificationKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => NotificationKind.soft,
        ),
        isRead: (j['isRead'] as bool?) ?? false,
      );
}

