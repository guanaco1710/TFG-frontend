enum NotificationType {
  confirmation,
  reminder,
  cancellation;

  static NotificationType fromString(String value) {
    return switch (value) {
      'CONFIRMATION' => NotificationType.confirmation,
      'REMINDER' => NotificationType.reminder,
      'CANCELLATION' => NotificationType.cancellation,
      _ => throw ArgumentError('Unknown NotificationType: $value'),
    };
  }

  String toJson() => switch (this) {
    NotificationType.confirmation => 'CONFIRMATION',
    NotificationType.reminder => 'REMINDER',
    NotificationType.cancellation => 'CANCELLATION',
  };
}

class NotificationSession {
  const NotificationSession({
    required this.id,
    required this.startTime,
    required this.classTypeName,
  });

  final int id;
  final DateTime startTime;
  final String classTypeName;

  factory NotificationSession.fromJson(Map<String, dynamic> json) =>
      NotificationSession(
        id: json['id'] as int,
        startTime: DateTime.parse(json['startTime'] as String),
        classTypeName:
            (json['classType'] as Map<String, dynamic>)['name'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'classType': {'name': classTypeName},
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSession &&
          other.id == id &&
          other.startTime == startTime &&
          other.classTypeName == classTypeName;

  @override
  int get hashCode => Object.hash(id, startTime, classTypeName);
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    this.scheduledAt,
    required this.sent,
    this.sentAt,
    required this.read,
    required this.userId,
    required this.session,
  });

  final int id;
  final NotificationType type;
  final DateTime? scheduledAt;
  final bool sent;
  final DateTime? sentAt;
  final bool read;
  final int userId;
  final NotificationSession session;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        type: NotificationType.fromString(json['type'] as String),
        scheduledAt: json['scheduledAt'] != null
            ? DateTime.parse(json['scheduledAt'] as String)
            : null,
        sent: json['sent'] as bool,
        sentAt: json['sentAt'] != null
            ? DateTime.parse(json['sentAt'] as String)
            : null,
        read: json['read'] as bool,
        userId: json['userId'] as int,
        session: NotificationSession.fromJson(
          json['session'] as Map<String, dynamic>,
        ),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toJson(),
    'scheduledAt': scheduledAt?.toIso8601String(),
    'sent': sent,
    'sentAt': sentAt?.toIso8601String(),
    'read': read,
    'userId': userId,
    'session': session.toJson(),
  };

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    scheduledAt: scheduledAt,
    sent: sent,
    sentAt: sentAt,
    read: read ?? this.read,
    userId: userId,
    session: session,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          other.id == id &&
          other.type == type &&
          other.scheduledAt == scheduledAt &&
          other.sent == sent &&
          other.sentAt == sentAt &&
          other.read == read &&
          other.userId == userId &&
          other.session == session;

  @override
  int get hashCode =>
      Object.hash(id, type, scheduledAt, sent, sentAt, read, userId, session);
}

class NotificationPage {
  const NotificationPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasMore,
  });

  final List<AppNotification> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasMore;

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      NotificationPage(
        content: (json['content'] as List<dynamic>)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        size: json['size'] as int,
        totalElements: json['totalElements'] as int,
        totalPages: json['totalPages'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
