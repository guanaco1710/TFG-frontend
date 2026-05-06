import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';

const _classTypeJson = {
  'id': 1,
  'name': 'Spinning 45min',
  'durationMinutes': 45,
};

const _gymJson = {'id': 1, 'name': 'GymBook Central', 'city': 'Madrid'};

const _sessionJson = {
  'id': 1,
  'classType': _classTypeJson,
  'gym': _gymJson,
  'startTime': '2024-06-01T09:00:00.000Z',
};

const _bookingJson = {
  'id': 42,
  'classSession': _sessionJson,
  'status': 'CONFIRMED',
  'waitlistPosition': null,
  'bookedAt': '2024-05-20T10:00:00.000Z',
};

const _waitlistedBookingJson = {
  'id': 43,
  'classSession': _sessionJson,
  'status': 'WAITLISTED',
  'waitlistPosition': 3,
  'bookedAt': '2024-05-20T10:01:00.000Z',
};

void main() {
  group('BookingClassType', () {
    test('fromJson parses all fields', () {
      final ct = BookingClassType.fromJson(_classTypeJson);
      expect(ct.id, 1);
      expect(ct.name, 'Spinning 45min');
      expect(ct.durationMinutes, 45);
    });

    test('toJson round-trips', () {
      final ct = BookingClassType.fromJson(_classTypeJson);
      expect(ct.toJson(), _classTypeJson);
    });

    test('equality and hashCode', () {
      final a = BookingClassType.fromJson(_classTypeJson);
      final b = BookingClassType.fromJson(_classTypeJson);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('BookingGym', () {
    test('fromJson parses all fields', () {
      final gym = BookingGym.fromJson(_gymJson);
      expect(gym.id, 1);
      expect(gym.name, 'GymBook Central');
      expect(gym.city, 'Madrid');
    });

    test('toJson round-trips', () {
      final gym = BookingGym.fromJson(_gymJson);
      expect(gym.toJson(), _gymJson);
    });

    test('equality and hashCode', () {
      final a = BookingGym.fromJson(_gymJson);
      final b = BookingGym.fromJson(_gymJson);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('BookingClassSession', () {
    test('fromJson parses all fields', () {
      final session = BookingClassSession.fromJson(_sessionJson);
      expect(session.id, 1);
      expect(session.classType.name, 'Spinning 45min');
      expect(session.gym.name, 'GymBook Central');
      expect(session.startTime, DateTime.parse('2024-06-01T09:00:00Z'));
    });

    test('toJson round-trips', () {
      final session = BookingClassSession.fromJson(_sessionJson);
      expect(session.toJson(), _sessionJson);
    });

    test('equality and hashCode', () {
      final a = BookingClassSession.fromJson(_sessionJson);
      final b = BookingClassSession.fromJson(_sessionJson);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('BookingStatus', () {
    test('fromString parses all values', () {
      expect(BookingStatus.fromString('CONFIRMED'), BookingStatus.confirmed);
      expect(BookingStatus.fromString('WAITLISTED'), BookingStatus.waitlisted);
      expect(BookingStatus.fromString('CANCELLED'), BookingStatus.cancelled);
      expect(BookingStatus.fromString('ATTENDED'), BookingStatus.attended);
      expect(BookingStatus.fromString('NO_SHOW'), BookingStatus.noShow);
    });

    test('fromString throws on unknown value', () {
      expect(() => BookingStatus.fromString('UNKNOWN'), throwsArgumentError);
    });

    test('toJson serialises back to wire format', () {
      expect(BookingStatus.confirmed.toJson(), 'CONFIRMED');
      expect(BookingStatus.waitlisted.toJson(), 'WAITLISTED');
      expect(BookingStatus.cancelled.toJson(), 'CANCELLED');
      expect(BookingStatus.attended.toJson(), 'ATTENDED');
      expect(BookingStatus.noShow.toJson(), 'NO_SHOW');
    });
  });

  group('Booking', () {
    test('fromJson parses confirmed booking', () {
      final booking = Booking.fromJson(_bookingJson);
      expect(booking.id, 42);
      expect(booking.status, BookingStatus.confirmed);
      expect(booking.waitlistPosition, isNull);
      expect(booking.bookedAt, DateTime.parse('2024-05-20T10:00:00Z'));
      expect(booking.classSession.id, 1);
    });

    test('fromJson parses waitlisted booking with position', () {
      final booking = Booking.fromJson(_waitlistedBookingJson);
      expect(booking.id, 43);
      expect(booking.status, BookingStatus.waitlisted);
      expect(booking.waitlistPosition, 3);
    });

    test('toJson round-trips confirmed booking', () {
      final booking = Booking.fromJson(_bookingJson);
      expect(booking.toJson(), _bookingJson);
    });

    test('toJson round-trips waitlisted booking', () {
      final booking = Booking.fromJson(_waitlistedBookingJson);
      expect(booking.toJson(), _waitlistedBookingJson);
    });

    test('equality and hashCode', () {
      final a = Booking.fromJson(_bookingJson);
      final b = Booking.fromJson(_bookingJson);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when id differs', () {
      final a = Booking.fromJson(_bookingJson);
      final b = Booking.fromJson(_waitlistedBookingJson);
      expect(a, isNot(b));
    });
  });

  group('BookingPage', () {
    test('fromJson parses paginated response', () {
      final json = {
        'content': [_bookingJson],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
        'hasMore': false,
      };

      final page = BookingPage.fromJson(json);
      expect(page.content, hasLength(1));
      expect(page.content[0].id, 42);
      expect(page.page, 0);
      expect(page.size, 20);
      expect(page.totalElements, 1);
      expect(page.totalPages, 1);
      expect(page.hasMore, false);
    });
  });
}
