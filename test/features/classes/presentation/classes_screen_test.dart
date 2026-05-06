import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/models/subscription.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/class_session_provider.dart';
import 'package:tfg_frontend/features/classes/presentation/screens/classes_screen.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/providers/subscription_provider.dart';

class MockClassSessionRepository extends Mock
    implements ClassSessionRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

const _activeSubscription = Subscription(
  id: 7,
  plan: SubscriptionPlan(id: 2, name: 'Premium Monthly', priceMonthly: 49.99),
  gym: SubscriptionGym(
    id: 5,
    name: 'GymBook Central',
    address: 'Calle Mayor 1',
    city: 'Madrid',
  ),
  status: SubscriptionStatus.active,
  startDate: '2024-05-01',
  renewalDate: '2024-06-01',
  classesUsedThisMonth: 0,
  pendingCancellation: false,
);

ClassSession _makeSession(int id) => ClassSession(
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
  instructor: const SessionInstructor(
    id: 2,
    name: 'Jane Doe',
    specialty: 'Cycling',
  ),
  startTime: '2024-06-01T09:00:00Z',
  durationMinutes: 45,
  maxCapacity: 20,
  room: 'Studio A',
  status: ClassSessionStatus.scheduled,
  confirmedCount: 15,
  availableSpots: 5,
);

final _bookingSession = BookingClassSession(
  id: 1,
  classType: BookingClassType(
    id: 1,
    name: 'Spinning 45min',
    durationMinutes: 45,
  ),
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
  ClassSessionProvider sessionProvider, {
  BookingProvider? bookingProvider,
  SubscriptionProvider? subscriptionProvider,
}) {
  if (subscriptionProvider == null) {
    final subRepo = MockSubscriptionRepository();
    when(
      () => subRepo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubscription]);
    subscriptionProvider = SubscriptionProvider(repository: subRepo);
  }
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: sessionProvider),
      ChangeNotifierProvider.value(
        value:
            bookingProvider ??
            BookingProvider(repository: MockBookingRepository()),
      ),
      ChangeNotifierProvider.value(value: subscriptionProvider),
    ],
    child: const MaterialApp(home: Scaffold(body: ClassesScreen())),
  );
}

void main() {
  late MockClassSessionRepository repository;
  late MockBookingRepository bookingRepository;

  setUpAll(() {
    registerFallbackValue(DateTime(2024));
  });

  setUp(() {
    repository = MockClassSessionRepository();
    bookingRepository = MockBookingRepository();
  });

  void stubScheduleAny(List<ClassSession> sessions) {
    when(
      () => repository.fetchSchedule(
        from: any(named: 'from'),
        to: any(named: 'to'),
        gymId: any(named: 'gymId'),
      ),
    ).thenAnswer((_) async => sessions);
  }

  testWidgets('shows no_subscription widget when no active subscription', (
    tester,
  ) async {
    final subRepo = MockSubscriptionRepository();
    when(
      () => subRepo.fetchMySubscriptions(),
    ).thenAnswer((_) async => []);
    final subProvider = SubscriptionProvider(repository: subRepo);
    final sessionProvider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(
      _wrap(sessionProvider, subscriptionProvider: subProvider),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('no_subscription')), findsOneWidget);
    verifyNever(
      () => repository.fetchSchedule(
        from: any(named: 'from'),
        to: any(named: 'to'),
        gymId: any(named: 'gymId'),
      ),
    );
  });

  testWidgets('loads sessions filtered by active subscription gymId', (
    tester,
  ) async {
    final subRepo = MockSubscriptionRepository();
    when(
      () => subRepo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubscription]);
    final subProvider = SubscriptionProvider(repository: subRepo);

    when(
      () => repository.fetchSchedule(
        from: any(named: 'from'),
        to: any(named: 'to'),
        gymId: 5,
      ),
    ).thenAnswer((_) async => [_makeSession(1)]);
    final sessionProvider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(
      _wrap(sessionProvider, subscriptionProvider: subProvider),
    );
    await tester.pumpAndSettle();

    verify(
      () => repository.fetchSchedule(
        from: any(named: 'from'),
        to: any(named: 'to'),
        gymId: 5,
      ),
    ).called(1);
    expect(find.byKey(const Key('session_card')), findsOneWidget);
  });

  testWidgets('shows week strip with 7 day chips', (tester) async {
    stubScheduleAny([]);
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('week_strip')), findsOneWidget);

    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final key = Key(
        'day_chip_${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
      );
      expect(find.byKey(key), findsOneWidget);
    }
  });

  testWidgets('tapping a day chip fetches sessions for that day', (
    tester,
  ) async {
    stubScheduleAny([]);
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    // pick a day in current week that is not today
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    final tapDay =
        today.weekday == 1 ? monday.add(const Duration(days: 1)) : monday;
    final tapDayStr =
        '${tapDay.year}-${tapDay.month.toString().padLeft(2, '0')}-${tapDay.day.toString().padLeft(2, '0')}';
    final expectedFrom = DateTime.utc(tapDay.year, tapDay.month, tapDay.day);
    final expectedTo = DateTime.utc(
      tapDay.year,
      tapDay.month,
      tapDay.day,
      23,
      59,
      59,
    );

    when(
      () => repository.fetchSchedule(
        from: expectedFrom,
        to: expectedTo,
        gymId: any(named: 'gymId'),
      ),
    ).thenAnswer((_) async => [_makeSession(1)]);

    await tester.tap(find.byKey(Key('day_chip_$tapDayStr')));
    await tester.pumpAndSettle();

    verify(
      () => repository.fetchSchedule(
        from: expectedFrom,
        to: expectedTo,
        gymId: any(named: 'gymId'),
      ),
    ).called(1);
  });

  testWidgets('session card shows time only, not ISO date', (tester) async {
    stubScheduleAny([_makeSession(1)]);
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    final expectedTime = DateFormat('HH:mm').format(
      DateTime.parse('2024-06-01T09:00:00Z').toLocal(),
    );
    expect(find.textContaining('2024-06-01'), findsNothing);
    expect(find.textContaining(expectedTime), findsOneWidget);
  });

  testWidgets('shows loading indicator initially', (tester) async {
    when(
      () => repository.fetchSchedule(
        from: any(named: 'from'),
        to: any(named: 'to'),
        gymId: any(named: 'gymId'),
      ),
    ).thenAnswer((_) => Completer<List<ClassSession>>().future);
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byKey(const Key('classes_loading')), findsOneWidget);
  });

  testWidgets('shows empty state when no sessions', (tester) async {
    stubScheduleAny([]);
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('classes_empty_icon')), findsOneWidget);
    expect(find.byKey(const Key('classes_empty_text')), findsOneWidget);
    expect(find.text('No hay clases disponibles'), findsOneWidget);
  });

  testWidgets('shows session cards when sessions loaded', (tester) async {
    stubScheduleAny([_makeSession(1), _makeSession(2)]);
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session_card')), findsNWidgets(2));
  });

  testWidgets('session card shows class type name', (tester) async {
    stubScheduleAny([_makeSession(1)]);
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Spinning 45min'), findsOneWidget);
  });

  testWidgets('session card shows status chip PROGRAMADA', (tester) async {
    stubScheduleAny([_makeSession(1)]);
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('PROGRAMADA'), findsOneWidget);
  });

  testWidgets('shows error state with retry button on failure', (tester) async {
    when(
      () => repository.fetchSchedule(
        from: any(named: 'from'),
        to: any(named: 'to'),
        gymId: any(named: 'gymId'),
      ),
    ).thenThrow(
      ApiException(
        status: 401,
        error: 'Unauthorized',
        message: 'Token expired',
        path: '/class-sessions/schedule',
      ),
    );
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('classes_error')), findsOneWidget);
    expect(find.byKey(const Key('classes_retry_button')), findsOneWidget);
    expect(find.text('Token expired'), findsOneWidget);
  });

  testWidgets('retry button reloads sessions for selected day', (tester) async {
    when(
      () => repository.fetchSchedule(
        from: any(named: 'from'),
        to: any(named: 'to'),
        gymId: any(named: 'gymId'),
      ),
    ).thenThrow(
      ApiException(
        status: 500,
        error: 'Server Error',
        message: 'Internal error',
        path: '/class-sessions/schedule',
      ),
    );
    final provider = ClassSessionProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    stubScheduleAny([_makeSession(1)]);

    await tester.tap(find.byKey(const Key('classes_retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session_card')), findsOneWidget);
  });

  testWidgets(
    'shows Reservar button for scheduled session with available spots',
    (tester) async {
      stubScheduleAny([_makeSession(1)]);
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
    stubScheduleAny([_makeSession(1)]);
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
    stubScheduleAny([_makeSession(1)]);
    final waitlistedBooking = Booking(
      id: 43,
      classSession: _bookingSession,
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
    stubScheduleAny([_makeSession(1)]);
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
