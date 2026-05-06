import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';
import 'package:tfg_frontend/features/dashboard/presentation/providers/dashboard_provider.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

final _session = BookingClassSession(
  id: 1,
  classType: const BookingClassType(
    id: 1,
    name: 'Spinning 45min',
    durationMinutes: 45,
  ),
  gym: const BookingGym(id: 1, name: 'Downtown Gym', city: 'Madrid'),
  startTime: DateTime.now().add(const Duration(days: 1)),
);

final _booking = Booking(
  id: 42,
  classSession: _session,
  status: BookingStatus.confirmed,
  bookedAt: DateTime.now(),
);

final _emptyPage = BookingPage(
  content: [],
  page: 0,
  size: 3,
  totalElements: 0,
  totalPages: 0,
  hasMore: false,
);

BookingPage _pageWith(List<Booking> bookings) => BookingPage(
  content: bookings,
  page: 0,
  size: 3,
  totalElements: bookings.length,
  totalPages: 1,
  hasMore: false,
);

void main() {
  late MockBookingRepository repository;
  late DashboardProvider provider;

  setUp(() {
    repository = MockBookingRepository();
    provider = DashboardProvider(repository: repository);
  });

  test('initial state is initial', () {
    expect(provider.state, DashboardState.initial);
    expect(provider.upcoming, isEmpty);
    expect(provider.error, isNull);
  });

  group('loadUpcoming', () {
    test('transitions loading → loaded with bookings', () async {
      when(
        () => repository.fetchMyBookings(
          page: any(named: 'page'),
          size: any(named: 'size'),
          status: any(named: 'status'),
          from: any(named: 'from'),
        ),
      ).thenAnswer((_) async => _pageWith([_booking]));

      final states = <DashboardState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadUpcoming();

      expect(states, [DashboardState.loading, DashboardState.loaded]);
      expect(provider.upcoming, [_booking]);
      expect(provider.error, isNull);
    });

    test('loaded with empty list when no upcoming bookings', () async {
      when(
        () => repository.fetchMyBookings(
          page: any(named: 'page'),
          size: any(named: 'size'),
          status: any(named: 'status'),
          from: any(named: 'from'),
        ),
      ).thenAnswer((_) async => _emptyPage);

      await provider.loadUpcoming();

      expect(provider.state, DashboardState.loaded);
      expect(provider.upcoming, isEmpty);
    });

    test('transitions loading → error on ApiException', () async {
      when(
        () => repository.fetchMyBookings(
          page: any(named: 'page'),
          size: any(named: 'size'),
          status: any(named: 'status'),
          from: any(named: 'from'),
        ),
      ).thenThrow(
        ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Token expired',
          path: '/bookings/me',
        ),
      );

      await provider.loadUpcoming();

      expect(provider.state, DashboardState.error);
      expect(provider.error, 'Token expired');
    });

    test('transitions loading → error on generic exception', () async {
      when(
        () => repository.fetchMyBookings(
          page: any(named: 'page'),
          size: any(named: 'size'),
          status: any(named: 'status'),
          from: any(named: 'from'),
        ),
      ).thenThrow(Exception('network'));

      await provider.loadUpcoming();

      expect(provider.state, DashboardState.error);
      expect(provider.error, isNotNull);
    });

    test('fetches with status=CONFIRMED and size=3', () async {
      when(
        () => repository.fetchMyBookings(
          page: any(named: 'page'),
          size: any(named: 'size'),
          status: any(named: 'status'),
          from: any(named: 'from'),
        ),
      ).thenAnswer((_) async => _emptyPage);

      await provider.loadUpcoming();

      verify(
        () => repository.fetchMyBookings(
          page: 0,
          size: 3,
          status: BookingStatus.confirmed,
          from: any(named: 'from'),
        ),
      ).called(1);
    });
  });
}
