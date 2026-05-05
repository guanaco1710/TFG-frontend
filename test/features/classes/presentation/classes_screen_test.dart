import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/class_session_provider.dart';
import 'package:tfg_frontend/features/classes/presentation/screens/classes_screen.dart';

class MockClassSessionRepository extends Mock
    implements ClassSessionRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

ClassSession _makeSession(int id) => ClassSession(
  id: id,
  classType: const SessionClassType(
    id: 1,
    name: 'Spinning 45min',
    level: 'INTERMEDIATE',
  ),
  gym: const SessionGym(
    id: 1,
    name: 'GymBook Central',
    address: 'Calle Mayor 1',
    city: 'Madrid',
  ),
  instructor: const SessionInstructor(
    id: 2,
    name: 'Jane Doe',
    specialty: 'Cycling',
  ),
  startTime: '2024-06-01T09:00:00',
  durationMinutes: 45,
  maxCapacity: 20,
  room: 'Studio A',
  status: ClassSessionStatus.scheduled,
  confirmedCount: 15,
  availableSpots: 5,
);

ClassSessionPage _makePage(
  List<ClassSession> content, {
  bool hasMore = false,
}) => ClassSessionPage(
  content: content,
  page: 0,
  size: 20,
  totalElements: content.length,
  totalPages: 1,
  hasMore: hasMore,
);

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

Widget _wrap(
  ClassSessionProvider sessionProvider, {
  BookingProvider? bookingProvider,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: sessionProvider),
    ChangeNotifierProvider.value(
      value:
          bookingProvider ??
          BookingProvider(repository: MockBookingRepository()),
    ),
  ],
  child: const MaterialApp(home: Scaffold(body: ClassesScreen())),
);

void main() {
  late MockClassSessionRepository repository;
  late MockBookingRepository bookingRepository;

  setUp(() {
    repository = MockClassSessionRepository();
    bookingRepository = MockBookingRepository();
  });

  testWidgets('shows loading indicator initially', (tester) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenAnswer((_) => Completer<ClassSessionPage>().future);
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byKey(const Key('classes_loading')), findsOneWidget);
  });

  testWidgets('shows empty state when no sessions', (tester) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenAnswer((_) async => _makePage([]));
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('classes_empty_icon')), findsOneWidget);
    expect(find.byKey(const Key('classes_empty_text')), findsOneWidget);
    expect(find.text('No hay clases disponibles'), findsOneWidget);
  });

  testWidgets('shows session cards when sessions loaded', (tester) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenAnswer((_) async => _makePage([_makeSession(1), _makeSession(2)]));
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session_card')), findsNWidgets(2));
  });

  testWidgets('session card shows class type name', (tester) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenAnswer((_) async => _makePage([_makeSession(1)]));
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Spinning 45min'), findsOneWidget);
  });

  testWidgets('session card shows status chip PROGRAMADA', (tester) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenAnswer((_) async => _makePage([_makeSession(1)]));
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('PROGRAMADA'), findsOneWidget);
  });

  testWidgets('shows error state with retry button on failure', (tester) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenThrow(
      ApiException(
        status: 401,
        error: 'Unauthorized',
        message: 'Token expired',
        path: '/class-sessions',
      ),
    );
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('classes_error')), findsOneWidget);
    expect(find.byKey(const Key('classes_retry_button')), findsOneWidget);
    expect(find.text('Token expired'), findsOneWidget);
  });

  testWidgets('retry button calls loadSessions again', (tester) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenThrow(
      ApiException(
        status: 500,
        error: 'Server Error',
        message: 'Internal error',
        path: '/class-sessions',
      ),
    );
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenAnswer((_) async => _makePage([_makeSession(1)]));

    await tester.tap(find.byKey(const Key('classes_retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session_card')), findsOneWidget);
  });

  testWidgets('shows load_more_indicator when hasMore', (tester) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenAnswer((_) async => _makePage([_makeSession(1)], hasMore: true));
    // Stub page 1 with never-completing future to stop infinite scroll trigger
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 1),
    ).thenAnswer((_) => Completer<ClassSessionPage>().future);
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('load_more_indicator')), findsOneWidget);
  });

  testWidgets(
    'shows Reservar button for scheduled session with available spots',
    (tester) async {
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
      ).thenAnswer((_) async => _makePage([_makeSession(1)]));
      final sessionProvider = ClassSessionProvider(repository: repository);
      final bookingProvider = BookingProvider(repository: bookingRepository);

      await tester.pumpWidget(
        _wrap(sessionProvider, bookingProvider: bookingProvider),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('book_session_1')), findsOneWidget);
      expect(find.text('Reservar'), findsOneWidget);
    },
  );

  testWidgets('book button calls book and shows success snackbar', (
    tester,
  ) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenAnswer((_) async => _makePage([_makeSession(1)]));
    when(
      () =>
          bookingRepository.book(classSessionId: any(named: 'classSessionId')),
    ).thenAnswer((_) async => _confirmedBooking);
    final sessionProvider = ClassSessionProvider(repository: repository);
    final bookingProvider = BookingProvider(repository: bookingRepository);

    await tester.pumpWidget(
      _wrap(sessionProvider, bookingProvider: bookingProvider),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('book_session_1')));
    await tester.pumpAndSettle();

    expect(find.text('Reserva confirmada'), findsOneWidget);
  });

  testWidgets('book button shows waitlist snackbar on WAITLISTED result', (
    tester,
  ) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenAnswer((_) async => _makePage([_makeSession(1)]));

    final waitlistedBooking = Booking(
      id: 43,
      classSession: _session,
      status: BookingStatus.waitlisted,
      waitlistPosition: 3,
      bookedAt: DateTime.parse('2024-05-20T10:01:00Z'),
    );

    when(
      () =>
          bookingRepository.book(classSessionId: any(named: 'classSessionId')),
    ).thenAnswer((_) async => waitlistedBooking);
    final sessionProvider = ClassSessionProvider(repository: repository);
    final bookingProvider = BookingProvider(repository: bookingRepository);

    await tester.pumpWidget(
      _wrap(sessionProvider, bookingProvider: bookingProvider),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('book_session_1')));
    await tester.pumpAndSettle();

    expect(find.text('Añadido a lista de espera'), findsOneWidget);
  });

  testWidgets('book button shows error snackbar on failure', (tester) async {
    when(
      () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
    ).thenAnswer((_) async => _makePage([_makeSession(1)]));
    when(
      () =>
          bookingRepository.book(classSessionId: any(named: 'classSessionId')),
    ).thenThrow(
      const ApiException(
        status: 409,
        error: 'AlreadyBooked',
        message: 'Ya tienes una reserva',
        path: '/bookings',
      ),
    );
    final sessionProvider = ClassSessionProvider(repository: repository);
    final bookingProvider = BookingProvider(repository: bookingRepository);

    await tester.pumpWidget(
      _wrap(sessionProvider, bookingProvider: bookingProvider),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('book_session_1')));
    await tester.pumpAndSettle();

    expect(find.text('Ya tienes una reserva'), findsOneWidget);
  });
}
