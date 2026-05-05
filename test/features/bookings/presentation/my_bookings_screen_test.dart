import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';
import 'package:tfg_frontend/features/bookings/presentation/screens/my_bookings_screen.dart';

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
  id: 44,
  classSession: _session,
  status: BookingStatus.cancelled,
  bookedAt: DateTime.parse('2024-05-20T10:02:00Z'),
);

final _attendedBooking = Booking(
  id: 45,
  classSession: _session,
  status: BookingStatus.attended,
  bookedAt: DateTime.parse('2024-05-20T10:03:00Z'),
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

Widget _buildSubject(MockBookingRepository repo) {
  return ChangeNotifierProvider(
    create: (_) => BookingProvider(repository: repo),
    child: const MaterialApp(home: MyBookingsScreen()),
  );
}

void main() {
  late MockBookingRepository repo;

  setUpAll(() {
    registerFallbackValue(BookingStatus.confirmed);
  });

  setUp(() {
    repo = MockBookingRepository();
  });

  testWidgets('shows loading indicator while fetching', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return _makePage([]);
    });

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump();

    expect(find.byKey(const Key('bookings_loading')), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('shows empty state when no bookings', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bookings_empty')), findsOneWidget);
    expect(find.text('No tienes reservas todavía'), findsOneWidget);
  });

  testWidgets('shows booking cards for confirmed and waitlisted', (
    tester,
  ) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer(
      (_) async => _makePage([_confirmedBooking, _waitlistedBooking]),
    );

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('booking_card_42')), findsOneWidget);
    expect(find.byKey(const Key('booking_card_43')), findsOneWidget);
  });

  testWidgets('booking card shows class type name and gym', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_confirmedBooking]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('Spinning 45min'), findsOneWidget);
    expect(find.text('GymBook Central'), findsOneWidget);
  });

  testWidgets('booking card shows CONFIRMED status badge', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_confirmedBooking]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('CONFIRMADA'), findsOneWidget);
  });

  testWidgets('booking card shows WAITLISTED status badge and position', (
    tester,
  ) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_waitlistedBooking]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('LISTA DE ESPERA'), findsOneWidget);
    expect(find.textContaining('Posición: 3'), findsOneWidget);
  });

  testWidgets('cancel button shown for CONFIRMED booking', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_confirmedBooking]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cancel_booking_42')), findsOneWidget);
  });

  testWidgets('cancel button shown for WAITLISTED booking', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_waitlistedBooking]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cancel_booking_43')), findsOneWidget);
  });

  testWidgets('cancel button not shown for CANCELLED booking', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_cancelledBooking]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cancel_booking_44')), findsNothing);
  });

  testWidgets('cancel button not shown for ATTENDED booking', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_attendedBooking]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cancel_booking_45')), findsNothing);
  });

  testWidgets('tapping cancel shows confirmation dialog', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_confirmedBooking]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_booking_42')));
    await tester.pumpAndSettle();

    expect(find.text('Cancelar reserva'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);
    expect(find.text('Cancelar'), findsWidgets);
  });

  testWidgets('tapping Volver in dialog does not call cancelBooking', (
    tester,
  ) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_confirmedBooking]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_booking_42')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.cancelBooking(bookingId: any(named: 'bookingId')));
  });

  testWidgets('confirming cancel shows success snackbar', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_confirmedBooking]));

    final cancelledJson = {
      'id': 42,
      'classSession': {
        'id': 1,
        'classType': {'id': 1, 'name': 'Spinning 45min', 'durationMinutes': 45},
        'gym': {'id': 1, 'name': 'GymBook Central', 'city': 'Madrid'},
        'startTime': '2024-06-01T09:00:00Z',
      },
      'status': 'CANCELLED',
      'waitlistPosition': null,
      'bookedAt': '2024-05-20T10:00:00Z',
    };
    when(
      () => repo.cancelBooking(bookingId: any(named: 'bookingId')),
    ).thenAnswer((_) async => Booking.fromJson(cancelledJson));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_booking_42')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('cancelada'), findsOneWidget);
  });

  testWidgets('confirming cancel on error shows error snackbar', (
    tester,
  ) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_confirmedBooking]));
    when(
      () => repo.cancelBooking(bookingId: any(named: 'bookingId')),
    ).thenThrow(
      const ApiException(
        status: 404,
        error: 'BookingNotFound',
        message: 'Reserva no encontrada',
        path: '/bookings/42/cancel',
      ),
    );

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_booking_42')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar').last);
    await tester.pumpAndSettle();

    expect(find.text('Reserva no encontrada'), findsOneWidget);
  });

  testWidgets('shows error state on fetch failure', (tester) async {
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

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bookings_error')), findsOneWidget);
    expect(find.text('Token expired'), findsOneWidget);
  });

  testWidgets('pull to refresh triggers loadMyBookings again', (tester) async {
    when(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).thenAnswer((_) async => _makePage([_confirmedBooking]));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    final state = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    unawaited(state.show());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    verify(
      () => repo.fetchMyBookings(page: 0, size: any(named: 'size')),
    ).called(greaterThanOrEqualTo(2));
  });
}
