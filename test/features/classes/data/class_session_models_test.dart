import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';

final _sessionJson = {
  'id': 1,
  'classType': {'id': 1, 'name': 'Spinning 45min', 'level': 'INTERMEDIATE'},
  'gym': {
    'id': 1,
    'name': 'GymBook Central',
    'address': 'Calle Mayor 1',
    'city': 'Madrid',
  },
  'instructor': {'id': 2, 'name': 'Jane Doe', 'specialty': 'Cycling'},
  'startTime': '2024-06-01T09:00:00',
  'durationMinutes': 45,
  'maxCapacity': 20,
  'room': 'Studio A',
  'status': 'SCHEDULED',
  'confirmedCount': 15,
  'availableSpots': 5,
};

void main() {
  group('SessionClassType', () {
    test('fromJson parses correctly', () {
      final ct = SessionClassType.fromJson({
        'id': 1,
        'name': 'Spinning',
        'level': 'BEGINNER',
      });
      expect(ct.id, 1);
      expect(ct.name, 'Spinning');
      expect(ct.level, 'BEGINNER');
    });

    test('toJson round-trips', () {
      const ct = SessionClassType(id: 1, name: 'Spinning', level: 'BEGINNER');
      expect(ct.toJson(), {'id': 1, 'name': 'Spinning', 'level': 'BEGINNER'});
    });

    test('equality and hashCode', () {
      const a = SessionClassType(id: 1, name: 'X', level: 'L');
      const b = SessionClassType(id: 1, name: 'X', level: 'L');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == a, isTrue);
    });

    test('not equal for different values', () {
      const a = SessionClassType(id: 1, name: 'X', level: 'L');
      const b = SessionClassType(id: 2, name: 'X', level: 'L');
      expect(a, isNot(equals(b)));
    });
  });

  group('SessionGym', () {
    test('fromJson parses correctly', () {
      final gym = SessionGym.fromJson({
        'id': 1,
        'name': 'Gym',
        'address': 'St 1',
        'city': 'Madrid',
      });
      expect(gym.id, 1);
      expect(gym.city, 'Madrid');
    });

    test('toJson round-trips', () {
      const gym = SessionGym(
        id: 1,
        name: 'Gym',
        address: 'St 1',
        city: 'Madrid',
      );
      expect(gym.toJson()['city'], 'Madrid');
    });

    test('equality and hashCode', () {
      const a = SessionGym(id: 1, name: 'G', address: 'A', city: 'C');
      const b = SessionGym(id: 1, name: 'G', address: 'A', city: 'C');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == a, isTrue);
    });

    test('not equal for different values', () {
      const a = SessionGym(id: 1, name: 'G', address: 'A', city: 'C');
      const b = SessionGym(id: 2, name: 'G', address: 'A', city: 'C');
      expect(a, isNot(equals(b)));
    });
  });

  group('SessionInstructor', () {
    test('fromJson parses with specialty', () {
      final i = SessionInstructor.fromJson({
        'id': 2,
        'name': 'Jane',
        'specialty': 'Cycling',
      });
      expect(i.specialty, 'Cycling');
    });

    test('fromJson parses null specialty', () {
      final i = SessionInstructor.fromJson({
        'id': 2,
        'name': 'Jane',
        'specialty': null,
      });
      expect(i.specialty, isNull);
    });

    test('toJson round-trips', () {
      const i = SessionInstructor(id: 2, name: 'Jane', specialty: 'Cycling');
      expect(i.toJson()['specialty'], 'Cycling');
    });

    test('equality and hashCode', () {
      const a = SessionInstructor(id: 1, name: 'J', specialty: 'X');
      const b = SessionInstructor(id: 1, name: 'J', specialty: 'X');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == a, isTrue);
    });

    test('not equal for different values', () {
      const a = SessionInstructor(id: 1, name: 'J');
      const b = SessionInstructor(id: 2, name: 'J');
      expect(a, isNot(equals(b)));
    });
  });

  group('ClassSessionStatus', () {
    test('fromString parses all values', () {
      expect(
        ClassSessionStatus.fromString('SCHEDULED'),
        ClassSessionStatus.scheduled,
      );
      expect(
        ClassSessionStatus.fromString('ACTIVE'),
        ClassSessionStatus.active,
      );
      expect(
        ClassSessionStatus.fromString('CANCELLED'),
        ClassSessionStatus.cancelled,
      );
      expect(
        ClassSessionStatus.fromString('FINISHED'),
        ClassSessionStatus.finished,
      );
    });

    test('fromString throws on unknown', () {
      expect(
        () => ClassSessionStatus.fromString('UNKNOWN'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns correct strings', () {
      expect(ClassSessionStatus.scheduled.toJson(), 'SCHEDULED');
      expect(ClassSessionStatus.active.toJson(), 'ACTIVE');
      expect(ClassSessionStatus.cancelled.toJson(), 'CANCELLED');
      expect(ClassSessionStatus.finished.toJson(), 'FINISHED');
    });
  });

  group('ClassSession', () {
    test('fromJson parses correctly', () {
      final session = ClassSession.fromJson(_sessionJson);
      expect(session.id, 1);
      expect(session.classType.name, 'Spinning 45min');
      expect(session.gym.city, 'Madrid');
      expect(session.instructor.specialty, 'Cycling');
      expect(session.startTime, '2024-06-01T09:00:00');
      expect(session.durationMinutes, 45);
      expect(session.maxCapacity, 20);
      expect(session.room, 'Studio A');
      expect(session.status, ClassSessionStatus.scheduled);
      expect(session.confirmedCount, 15);
      expect(session.availableSpots, 5);
    });

    test('toJson round-trips', () {
      final session = ClassSession.fromJson(_sessionJson);
      final json = session.toJson();
      expect(json['id'], 1);
      expect(json['status'], 'SCHEDULED');
      expect((json['classType'] as Map)['name'], 'Spinning 45min');
    });

    test('equality and hashCode', () {
      final a = ClassSession.fromJson(_sessionJson);
      final b = ClassSession.fromJson(_sessionJson);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == a, isTrue);
    });

    test('not equal for different id', () {
      final a = ClassSession.fromJson(_sessionJson);
      final b = ClassSession.fromJson({..._sessionJson, 'id': 99});
      expect(a, isNot(equals(b)));
    });
  });

  group('ClassSessionPage', () {
    test('fromJson parses page and sessions', () {
      final page = ClassSessionPage.fromJson({
        'content': [_sessionJson],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
        'hasMore': false,
      });
      expect(page.content.length, 1);
      expect(page.hasMore, isFalse);
      expect(page.totalElements, 1);
    });

    test('fromJson parses empty content', () {
      final page = ClassSessionPage.fromJson({
        'content': [],
        'page': 0,
        'size': 20,
        'totalElements': 0,
        'totalPages': 0,
        'hasMore': false,
      });
      expect(page.content, isEmpty);
    });
  });
}
