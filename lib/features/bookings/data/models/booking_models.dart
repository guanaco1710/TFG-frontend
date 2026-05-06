enum BookingStatus {
  confirmed,
  waitlisted,
  cancelled,
  attended,
  noShow;

  static BookingStatus fromString(String value) {
    return switch (value) {
      'CONFIRMED' => BookingStatus.confirmed,
      'WAITLISTED' => BookingStatus.waitlisted,
      'CANCELLED' => BookingStatus.cancelled,
      'ATTENDED' => BookingStatus.attended,
      'NO_SHOW' => BookingStatus.noShow,
      _ => throw ArgumentError('Unknown BookingStatus: $value'),
    };
  }

  String toJson() => switch (this) {
    BookingStatus.confirmed => 'CONFIRMED',
    BookingStatus.waitlisted => 'WAITLISTED',
    BookingStatus.cancelled => 'CANCELLED',
    BookingStatus.attended => 'ATTENDED',
    BookingStatus.noShow => 'NO_SHOW',
  };
}

class BookingClassType {
  const BookingClassType({
    required this.id,
    required this.name,
    required this.durationMinutes,
  });

  final int id;
  final String name;
  final int durationMinutes;

  factory BookingClassType.fromJson(Map<String, dynamic> json) =>
      BookingClassType(
        id: json['id'] as int,
        name: json['name'] as String,
        durationMinutes: json['durationMinutes'] as int,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'durationMinutes': durationMinutes,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingClassType &&
          other.id == id &&
          other.name == name &&
          other.durationMinutes == durationMinutes;

  @override
  int get hashCode => Object.hash(id, name, durationMinutes);
}

class BookingGym {
  const BookingGym({required this.id, required this.name, required this.city});

  final int id;
  final String name;
  final String city;

  factory BookingGym.fromJson(Map<String, dynamic> json) => BookingGym(
    id: json['id'] as int,
    name: json['name'] as String,
    city: json['city'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'city': city};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingGym &&
          other.id == id &&
          other.name == name &&
          other.city == city;

  @override
  int get hashCode => Object.hash(id, name, city);
}

class BookingClassSession {
  const BookingClassSession({
    required this.id,
    required this.classType,
    required this.gym,
    required this.startTime,
  });

  final int id;
  final BookingClassType classType;
  final BookingGym gym;
  final DateTime startTime;

  factory BookingClassSession.fromJson(Map<String, dynamic> json) =>
      BookingClassSession(
        id: json['id'] as int,
        classType: BookingClassType.fromJson(
          json['classType'] as Map<String, dynamic>,
        ),
        gym: BookingGym.fromJson(json['gym'] as Map<String, dynamic>),
        startTime: DateTime.parse(json['startTime'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'classType': classType.toJson(),
    'gym': gym.toJson(),
    'startTime': startTime.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingClassSession &&
          other.id == id &&
          other.classType == classType &&
          other.gym == gym &&
          other.startTime == startTime;

  @override
  int get hashCode => Object.hash(id, classType, gym, startTime);
}

class Booking {
  const Booking({
    required this.id,
    required this.classSession,
    required this.status,
    this.waitlistPosition,
    required this.bookedAt,
  });

  final int id;
  final BookingClassSession classSession;
  final BookingStatus status;
  final int? waitlistPosition;
  final DateTime bookedAt;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as int,
    classSession: BookingClassSession.fromJson(
      json['classSession'] as Map<String, dynamic>,
    ),
    status: BookingStatus.fromString(json['status'] as String),
    waitlistPosition: json['waitlistPosition'] as int?,
    bookedAt: DateTime.parse(json['bookedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'classSession': classSession.toJson(),
    'status': status.toJson(),
    'waitlistPosition': waitlistPosition,
    'bookedAt': bookedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Booking &&
          other.id == id &&
          other.classSession == classSession &&
          other.status == status &&
          other.waitlistPosition == waitlistPosition &&
          other.bookedAt == bookedAt;

  @override
  int get hashCode =>
      Object.hash(id, classSession, status, waitlistPosition, bookedAt);
}

class BookingPage {
  const BookingPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasMore,
  });

  final List<Booking> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasMore;

  factory BookingPage.fromJson(Map<String, dynamic> json) => BookingPage(
    content: (json['content'] as List<dynamic>)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: json['page'] as int,
    size: json['size'] as int,
    totalElements: json['totalElements'] as int,
    totalPages: json['totalPages'] as int,
    hasMore: json['hasMore'] as bool,
  );
}
