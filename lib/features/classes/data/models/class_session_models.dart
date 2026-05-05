class SessionClassType {
  const SessionClassType({
    required this.id,
    required this.name,
    required this.level,
  });

  final int id;
  final String name;
  final String level;

  factory SessionClassType.fromJson(Map<String, dynamic> json) =>
      SessionClassType(
        id: json['id'] as int,
        name: json['name'] as String,
        level: json['level'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'level': level};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionClassType &&
          other.id == id &&
          other.name == name &&
          other.level == level;

  @override
  int get hashCode => Object.hash(id, name, level);
}

class SessionGym {
  const SessionGym({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
  });

  final int id;
  final String name;
  final String address;
  final String city;

  factory SessionGym.fromJson(Map<String, dynamic> json) => SessionGym(
    id: json['id'] as int,
    name: json['name'] as String,
    address: json['address'] as String,
    city: json['city'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionGym &&
          other.id == id &&
          other.name == name &&
          other.address == address &&
          other.city == city;

  @override
  int get hashCode => Object.hash(id, name, address, city);
}

class SessionInstructor {
  const SessionInstructor({
    required this.id,
    required this.name,
    this.specialty,
  });

  final int id;
  final String name;
  final String? specialty;

  factory SessionInstructor.fromJson(Map<String, dynamic> json) =>
      SessionInstructor(
        id: json['id'] as int,
        name: json['name'] as String,
        specialty: json['specialty'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'specialty': specialty,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionInstructor &&
          other.id == id &&
          other.name == name &&
          other.specialty == specialty;

  @override
  int get hashCode => Object.hash(id, name, specialty);
}

enum ClassSessionStatus {
  scheduled,
  active,
  cancelled,
  finished;

  static ClassSessionStatus fromString(String value) {
    return switch (value) {
      'SCHEDULED' => ClassSessionStatus.scheduled,
      'ACTIVE' => ClassSessionStatus.active,
      'CANCELLED' => ClassSessionStatus.cancelled,
      'FINISHED' => ClassSessionStatus.finished,
      _ => throw ArgumentError('Unknown ClassSessionStatus: $value'),
    };
  }

  String toJson() => switch (this) {
    ClassSessionStatus.scheduled => 'SCHEDULED',
    ClassSessionStatus.active => 'ACTIVE',
    ClassSessionStatus.cancelled => 'CANCELLED',
    ClassSessionStatus.finished => 'FINISHED',
  };
}

class ClassSession {
  const ClassSession({
    required this.id,
    required this.classType,
    required this.gym,
    required this.instructor,
    required this.startTime,
    required this.durationMinutes,
    required this.maxCapacity,
    required this.room,
    required this.status,
    required this.confirmedCount,
    required this.availableSpots,
  });

  final int id;
  final SessionClassType classType;
  final SessionGym gym;
  final SessionInstructor instructor;
  final String startTime;
  final int durationMinutes;
  final int maxCapacity;
  final String room;
  final ClassSessionStatus status;
  final int confirmedCount;
  final int availableSpots;

  factory ClassSession.fromJson(Map<String, dynamic> json) => ClassSession(
    id: json['id'] as int,
    classType: SessionClassType.fromJson(
      json['classType'] as Map<String, dynamic>,
    ),
    gym: SessionGym.fromJson(json['gym'] as Map<String, dynamic>),
    instructor: SessionInstructor.fromJson(
      json['instructor'] as Map<String, dynamic>,
    ),
    startTime: json['startTime'] as String,
    durationMinutes: json['durationMinutes'] as int,
    maxCapacity: json['maxCapacity'] as int,
    room: json['room'] as String,
    status: ClassSessionStatus.fromString(json['status'] as String),
    confirmedCount: json['confirmedCount'] as int,
    availableSpots: json['availableSpots'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'classType': classType.toJson(),
    'gym': gym.toJson(),
    'instructor': instructor.toJson(),
    'startTime': startTime,
    'durationMinutes': durationMinutes,
    'maxCapacity': maxCapacity,
    'room': room,
    'status': status.toJson(),
    'confirmedCount': confirmedCount,
    'availableSpots': availableSpots,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassSession &&
          other.id == id &&
          other.classType == classType &&
          other.gym == gym &&
          other.instructor == instructor &&
          other.startTime == startTime &&
          other.durationMinutes == durationMinutes &&
          other.maxCapacity == maxCapacity &&
          other.room == room &&
          other.status == status &&
          other.confirmedCount == confirmedCount &&
          other.availableSpots == availableSpots;

  @override
  int get hashCode => Object.hash(
    id,
    classType,
    gym,
    instructor,
    startTime,
    durationMinutes,
    maxCapacity,
    room,
    status,
    confirmedCount,
    availableSpots,
  );
}

class ClassSessionPage {
  const ClassSessionPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasMore,
  });

  final List<ClassSession> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasMore;

  factory ClassSessionPage.fromJson(Map<String, dynamic> json) =>
      ClassSessionPage(
        content: (json['content'] as List<dynamic>)
            .map((e) => ClassSession.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        size: json['size'] as int,
        totalElements: json['totalElements'] as int,
        totalPages: json['totalPages'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
