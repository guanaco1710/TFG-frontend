import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/session_roster_provider.dart';
import 'package:tfg_frontend/features/classes/presentation/screens/class_session_detail_screen.dart';

class MockClassSessionRepository extends Mock
    implements ClassSessionRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

ClassSession _makeSession({
  int id = 1,
  ClassSessionStatus status = ClassSessionStatus.scheduled,
  int confirmedCount = 15,
  int maxCapacity = 20,
}) => ClassSession(
  id: id,
  classType: const SessionClassType(
    id: 1,
    name: 'Spinning 45min',
    level: 'INTERMEDIATE',
  ),
  gym: const SessionGym(
    id: 5,
    name: 'GymBook Central',
    address: 'Calle Mayor 1',
    city: 'Madrid',
  ),
  instructor: const SessionInstructor(id: 2, name: 'Jane Doe'),
  startTime: '2024-06-01T09:00:00Z',
  durationMinutes: 60,
  maxCapacity: maxCapacity,
  room: 'Studio A',
  status: status,
  confirmedCount: confirmedCount,
  availableSpots: maxCapacity - confirmedCount,
);

RosterEntry _makeEntry(int id, String name) => RosterEntry(
  userId: id,
  userFullName: name,
  userEmail: '$name@example.com',
);

final _bookingSession = BookingClassSession(
  id: 1,
  classType: BookingClassType(id: 1, name: 'Spinning 45min', durationMinutes: 60),
  gym: BookingGym(id: 5, name: 'GymBook Central', city: 'Madrid'),
  startTime: DateTime.parse('2024-06-01T09:00:00Z'),
);

final _confirmedBooking = Booking(
  id: 42,
  classSession: _bookingSession,
  status: BookingStatus.confirmed,
  bookedAt: DateTime.parse('2024-05-20T10:00:00Z'),
);

Widget _wrap(
  ClassSession session, {
  int? initialBookingId,
  List<RosterEntry>? roster,
  BookingProvider? bookingProvider,
  Future<List<RosterEntry>> Function(int)? fetchRosterOverride,
}) {
  final mockRepo = MockClassSessionRepository();
  if (fetchRosterOverride != null) {
    when(() => mockRepo.fetchRoster(any())).thenAnswer(
      (inv) => fetchRosterOverride(inv.positionalArguments[0] as int),
    );
  } else {
    when(
      () => mockRepo.fetchRoster(any()),
    ).thenAnswer((_) async => roster ?? []);
  }
  final rosterProvider = SessionRosterProvider(repository: mockRepo);

  if (bookingProvider == null) {
    final mockBookRepo = MockBookingRepository();
    bookingProvider = BookingProvider(repository: mockBookRepo);
  }

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: rosterProvider),
      ChangeNotifierProvider.value(value: bookingProvider),
    ],
    child: MaterialApp(
      home: ClassSessionDetailScreen(
        session: session,
        initialBookingId: initialBookingId,
      ),
    ),
  );
}

void main() {
  testWidgets('shows class type name in header', (tester) async {
    await tester.pumpWidget(_wrap(_makeSession()));
    await tester.pumpAndSettle();

    expect(find.text('Spinning 45min'), findsOneWidget);
  });

  testWidgets('shows formatted time range', (tester) async {
    await tester.pumpWidget(_wrap(_makeSession()));
    await tester.pumpAndSettle();

    final start = DateTime.parse('2024-06-01T09:00:00Z').toLocal();
    final end = start.add(const Duration(minutes: 60));
    final fmt = DateFormat('HH:mm');
    final expected = '${fmt.format(start)} – ${fmt.format(end)}';

    expect(find.textContaining(expected), findsOneWidget);
  });

  testWidgets('shows instructor name', (tester) async {
    await tester.pumpWidget(_wrap(_makeSession()));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('shows Asistentes header', (tester) async {
    await tester.pumpWidget(_wrap(_makeSession()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_attendees_header')), findsOneWidget);
    expect(find.text('Asistentes'), findsOneWidget);
  });

  testWidgets('shows completion percentage', (tester) async {
    // 15/20 = 75%
    await tester.pumpWidget(_wrap(_makeSession()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_completion_pct')), findsOneWidget);
    expect(find.text('75% completo'), findsOneWidget);
  });

  testWidgets('shows loading indicator while roster loading', (tester) async {
    final completer = Completer<List<RosterEntry>>();
    await tester.pumpWidget(
      _wrap(_makeSession(), fetchRosterOverride: (_) => completer.future),
    );
    await tester.pump();

    expect(find.byKey(const Key('detail_roster_loading')), findsOneWidget);
    completer.complete([]);
  });

  testWidgets('shows roster entries when loaded', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _makeSession(),
        roster: [_makeEntry(1, 'Alice Smith'), _makeEntry(2, 'Carlos M.')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Carlos M.'), findsOneWidget);
  });

  testWidgets('shows check icon for each attendee', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _makeSession(),
        roster: [_makeEntry(1, 'Alice Smith'), _makeEntry(2, 'Carlos M.')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('attendee_check_1')), findsOneWidget);
    expect(find.byKey(const Key('attendee_check_2')), findsOneWidget);
  });

  testWidgets('shows error state when roster fails', (tester) async {
    final mockRepo = MockClassSessionRepository();
    when(() => mockRepo.fetchRoster(any())).thenThrow(
      ApiException(
        status: 500,
        error: 'ServerError',
        message: 'Failed',
        path: '/class-sessions/1/bookings',
      ),
    );
    final rosterProvider = SessionRosterProvider(repository: mockRepo);
    final mockBookRepo = MockBookingRepository();
    final bookingProvider = BookingProvider(repository: mockBookRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: rosterProvider),
          ChangeNotifierProvider.value(value: bookingProvider),
        ],
        child: MaterialApp(
          home: ClassSessionDetailScreen(session: _makeSession()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_roster_retry')), findsOneWidget);
  });

  testWidgets('retry button reloads roster', (tester) async {
    final mockRepo = MockClassSessionRepository();
    var callCount = 0;
    when(() => mockRepo.fetchRoster(any())).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) {
        throw ApiException(
          status: 500,
          error: 'ServerError',
          message: 'Failed',
          path: '/class-sessions/1/bookings',
        );
      }
      return [_makeEntry(1, 'Alice Smith')];
    });
    final rosterProvider = SessionRosterProvider(repository: mockRepo);
    final mockBookRepo = MockBookingRepository();
    final bookingProvider = BookingProvider(repository: mockBookRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: rosterProvider),
          ChangeNotifierProvider.value(value: bookingProvider),
        ],
        child: MaterialApp(
          home: ClassSessionDetailScreen(session: _makeSession()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('detail_roster_retry')));
    await tester.pumpAndSettle();

    expect(find.text('Alice Smith'), findsOneWidget);
  });

  testWidgets('shows Unirse button when not booked', (tester) async {
    await tester.pumpWidget(_wrap(_makeSession()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_book_button')), findsOneWidget);
    expect(find.text('Unirse a la clase'), findsOneWidget);
    expect(find.byKey(const Key('detail_cancel_button')), findsNothing);
  });

  testWidgets('shows Salir button when initialBookingId set', (tester) async {
    await tester.pumpWidget(_wrap(_makeSession(), initialBookingId: 42));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_cancel_button')), findsOneWidget);
    expect(find.text('Salir de la clase'), findsOneWidget);
    expect(find.byKey(const Key('detail_book_button')), findsNothing);
  });

  testWidgets('tapping Unirse books session and shows Salir', (tester) async {
    final mockBookRepo = MockBookingRepository();
    when(
      () => mockBookRepo.book(classSessionId: any(named: 'classSessionId')),
    ).thenAnswer((_) async => _confirmedBooking);
    final bookingProvider = BookingProvider(repository: mockBookRepo);

    await tester.pumpWidget(_wrap(_makeSession(), bookingProvider: bookingProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('detail_book_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_cancel_button')), findsOneWidget);
    expect(find.byKey(const Key('detail_book_button')), findsNothing);
  });

  testWidgets('tapping Salir cancels and shows Unirse', (tester) async {
    final mockBookRepo = MockBookingRepository();
    when(
      () => mockBookRepo.book(classSessionId: any(named: 'classSessionId')),
    ).thenAnswer((_) async => _confirmedBooking);
    when(
      () => mockBookRepo.cancelBooking(bookingId: any(named: 'bookingId')),
    ).thenAnswer((_) async => _confirmedBooking);
    final bookingProvider = BookingProvider(repository: mockBookRepo);

    await tester.pumpWidget(_wrap(_makeSession(), bookingProvider: bookingProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('detail_book_button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5)); // fire snackbar dismiss timer
    await tester.pumpAndSettle(); // let exit animation complete

    await tester.tap(find.byKey(const Key('detail_cancel_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_book_button')), findsOneWidget);
    expect(find.byKey(const Key('detail_cancel_button')), findsNothing);
  });

  testWidgets('hides book button when session is cancelled', (tester) async {
    await tester.pumpWidget(
      _wrap(_makeSession(status: ClassSessionStatus.cancelled)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_book_button')), findsNothing);
    expect(find.byKey(const Key('detail_cancel_button')), findsNothing);
  });
}
