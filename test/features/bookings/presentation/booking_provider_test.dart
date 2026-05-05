import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

final _session = BookingClassSession(
  id: 1,
  classType: BookingClassType(
    id: 1,
    name: 'Spinning 45min',
    durationMinutes: 45,
  ),
  gym: BookingGym(id: 1, name: 'GymBook Central', city: 'Madrid'),
  startTime: DateTime.parse('2024-06-01T09:00:00Z'),
);

final _confirmedBooking = Booking(
  id: 42,
  classSession: _session,
  status: BookingStatus.confirmed,
  bookedAt: DateTime.parse('2024-05-20T10:00:00Z'),
);

final _waitlistedBooking = Booking(
  id: 43,
  classSession: _session,
  status: BookingStatus.waitlisted,
  waitlistPosition: 3,
  bookedAt: DateTime.parse('2024-05-20T10:01:00Z'),
);

final _cancelledBooking = Booking(
  id: 42,
  classSession: _session,
  status: BookingStatus.cancelled,
  bookedAt: DateTime.parse('2024-05-20T10:00:00Z'),
);

BookingPage _makePage(List<Booking> bookings, {bool hasMore = false}) =>
    BookingPage(
      content: bookings,
      page: 0,
      size: 20,
      totalElements: bookings.length,
      totalPages: 1,
      hasMore: hasMore,
    );

void main() {
  late MockBookingRepository repo;
  late BookingProvider provider;

  setUp(() {
    repo = MockBookingRepository();
    provider = BookingProvider(repository: repo);
  });

  group('loadMyBookings', () {
    test('transitions initial → loading → loaded and sets bookings', () async {
      when(
        () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
      ).thenAnswer((_) async => _makePage([_confirmedBooking]));

      final states = <BookingLoadState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadMyBookings();

      expect(states, [BookingLoadState.loading, BookingLoadState.loaded]);
      expect(provider.bookings, hasLength(1));
      expect(provider.bookings[0].id, 42);
      expect(provider.errorMessage, isNull);
    });

    test('sets bookings empty list when none returned', () async {
      when(
        () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
      ).thenAnswer((_) async => _makePage([]));

      await provider.loadMyBookings();

      expect(provider.state, BookingLoadState.loaded);
      expect(provider.bookings, isEmpty);
    });

    test('transitions to error on ApiException', () async {
      when(
        () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
      ).thenThrow(
        const ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Token expired',
          path: '/bookings/me',
        ),
      );

      await provider.loadMyBookings();

      expect(provider.state, BookingLoadState.error);
      expect(provider.errorMessage, 'Token expired');
    });

    test('transitions to error on generic exception', () async {
      when(
        () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
      ).thenThrow(Exception('Network failure'));

      await provider.loadMyBookings();

      expect(provider.state, BookingLoadState.error);
      expect(provider.errorMessage, isNotNull);
    });
  });

  group('loadMore', () {
    test('appends next page to bookings', () async {
      when(
        () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
      ).thenAnswer((_) async => _makePage([_confirmedBooking], hasMore: true));

      final page2 = BookingPage(
        content: [_waitlistedBooking],
        page: 1,
        size: 20,
        totalElements: 2,
        totalPages: 1,
        hasMore: false,
      );
      when(
        () => repo.fetchMyBookings(page: 1, size: any(named: 'size')),
      ).thenAnswer((_) async => page2);

      await provider.loadMyBookings();
      await provider.loadMore();

      expect(provider.bookings, hasLength(2));
      expect(provider.hasMore, false);
    });

    test('does nothing when hasMore is false', () async {
      when(
        () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
      ).thenAnswer((_) async => _makePage([_confirmedBooking], hasMore: false));

      await provider.loadMyBookings();
      await provider.loadMore();

      verifyNever(
        () => repo.fetchMyBookings(page: 1, size: any(named: 'size')),
      );
    });

    test('does nothing while already loading more', () async {
      when(
        () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
      ).thenAnswer((_) async => _makePage([_confirmedBooking], hasMore: true));

      await provider.loadMyBookings();

      when(
        () => repo.fetchMyBookings(page: 1, size: any(named: 'size')),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 10));
        return _makePage([]);
      });

      final first = provider.loadMore();
      final second = provider.loadMore();
      await first;
      await second;

      verify(
        () => repo.fetchMyBookings(page: 1, size: any(named: 'size')),
      ).called(1);
    });
  });

  group('book', () {
    test('returns confirmed Booking and does not set error', () async {
      when(
        () => repo.book(classSessionId: any(named: 'classSessionId')),
      ).thenAnswer((_) async => _confirmedBooking);

      final result = await provider.book(classSessionId: 1);

      expect(result, _confirmedBooking);
      expect(provider.isBooking, false);
      expect(provider.bookingError, isNull);
    });

    test('returns waitlisted Booking', () async {
      when(
        () => repo.book(classSessionId: any(named: 'classSessionId')),
      ).thenAnswer((_) async => _waitlistedBooking);

      final result = await provider.book(classSessionId: 1);

      expect(result?.status, BookingStatus.waitlisted);
    });

    test('isBooking is true while pending and false after', () async {
      when(
        () => repo.book(classSessionId: any(named: 'classSessionId')),
      ).thenAnswer((_) async => _confirmedBooking);

      final bookingValues = <bool>[];
      provider.addListener(() => bookingValues.add(provider.isBooking));

      await provider.book(classSessionId: 1);

      expect(bookingValues, containsAllInOrder([true, false]));
    });

    test('returns null and sets bookingError on ApiException', () async {
      when(
        () => repo.book(classSessionId: any(named: 'classSessionId')),
      ).thenThrow(
        const ApiException(
          status: 409,
          error: 'AlreadyBooked',
          message: 'Already have a booking',
          path: '/bookings',
        ),
      );

      final result = await provider.book(classSessionId: 1);

      expect(result, isNull);
      expect(provider.bookingError, 'Already have a booking');
      expect(provider.isBooking, false);
    });

    test('returns null and sets bookingError on generic exception', () async {
      when(
        () => repo.book(classSessionId: any(named: 'classSessionId')),
      ).thenThrow(Exception('Network failure'));

      final result = await provider.book(classSessionId: 1);

      expect(result, isNull);
      expect(provider.bookingError, isNotNull);
    });
  });

  group('cancelBooking', () {
    setUp(() {
      when(
        () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
      ).thenAnswer((_) async => _makePage([_confirmedBooking]));
    });

    test('returns true, updates booking in list, and clears error', () async {
      when(
        () => repo.cancelBooking(bookingId: any(named: 'bookingId')),
      ).thenAnswer((_) async => _cancelledBooking);

      await provider.loadMyBookings();
      final result = await provider.cancelBooking(bookingId: 42);

      expect(result, true);
      expect(provider.isCancelling, false);
      expect(provider.errorMessage, isNull);
      final updated = provider.bookings.firstWhere((b) => b.id == 42);
      expect(updated.status, BookingStatus.cancelled);
    });

    test('returns false and sets errorMessage on ApiException', () async {
      when(
        () => repo.cancelBooking(bookingId: any(named: 'bookingId')),
      ).thenThrow(
        const ApiException(
          status: 404,
          error: 'BookingNotFound',
          message: 'Booking not found',
          path: '/bookings/42/cancel',
        ),
      );

      await provider.loadMyBookings();
      final result = await provider.cancelBooking(bookingId: 42);

      expect(result, false);
      expect(provider.errorMessage, 'Booking not found');
      expect(provider.isCancelling, false);
    });

    test('isCancelling is true while pending and false after', () async {
      when(
        () => repo.cancelBooking(bookingId: any(named: 'bookingId')),
      ).thenAnswer((_) async => _cancelledBooking);

      await provider.loadMyBookings();

      final cancellingValues = <bool>[];
      provider.addListener(() => cancellingValues.add(provider.isCancelling));

      await provider.cancelBooking(bookingId: 42);

      expect(cancellingValues, containsAllInOrder([true, false]));
    });
  });
}
