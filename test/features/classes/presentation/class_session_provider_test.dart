import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/class_session_provider.dart';

class MockClassSessionRepository extends Mock
    implements ClassSessionRepository {}

ClassSession _makeSession(int id) => ClassSession(
  id: id,
  classType: const SessionClassType(id: 1, name: 'Spinning', level: 'BEGINNER'),
  gym: const SessionGym(
    id: 1,
    name: 'GymBook Central',
    address: 'Calle Mayor 1',
    city: 'Madrid',
  ),
  instructor: const SessionInstructor(id: 2, name: 'Jane Doe'),
  startTime: '2024-06-01T09:00:00Z',
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
  int page = 0,
}) => ClassSessionPage(
  content: content,
  page: page,
  size: 20,
  totalElements: content.length,
  totalPages: 1,
  hasMore: hasMore,
);

void main() {
  late MockClassSessionRepository repository;
  late ClassSessionProvider provider;

  setUpAll(() {
    registerFallbackValue(DateTime(2024));
  });

  setUp(() {
    repository = MockClassSessionRepository();
    provider = ClassSessionProvider(repository: repository);
  });

  test('initial state is initial, empty sessions', () {
    expect(provider.state, ClassSessionLoadState.initial);
    expect(provider.sessions, isEmpty);
    expect(provider.hasMore, isFalse);
    expect(provider.isLoadingMore, isFalse);
  });

  group('loadSessions', () {
    test('transitions loading → loaded, sets sessions', () async {
      final sessions = [_makeSession(1), _makeSession(2)];
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
      ).thenAnswer((_) async => _makePage(sessions));

      final states = <ClassSessionLoadState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadSessions();

      expect(states, [
        ClassSessionLoadState.loading,
        ClassSessionLoadState.loaded,
      ]);
      expect(provider.sessions, sessions);
      expect(provider.hasMore, isFalse);
    });

    test('resets previous sessions on new load', () async {
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
      ).thenAnswer((_) async => _makePage([_makeSession(1), _makeSession(2)]));
      await provider.loadSessions();
      expect(provider.sessions.length, 2);

      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
      ).thenAnswer((_) async => _makePage([_makeSession(99)]));
      await provider.loadSessions();

      expect(provider.sessions.length, 1);
      expect(provider.sessions.first.id, 99);
    });

    test('sets gymId filter', () async {
      when(
        () => repository.fetchSessions(gymId: 5, page: 0),
      ).thenAnswer((_) async => _makePage([_makeSession(1)]));

      await provider.loadSessions(gymId: 5);

      expect(provider.gymId, 5);
      verify(() => repository.fetchSessions(gymId: 5, page: 0)).called(1);
    });

    test('transitions loading → error on ApiException', () async {
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

      await provider.loadSessions();

      expect(provider.state, ClassSessionLoadState.error);
      expect(provider.errorMessage, 'Token expired');
    });

    test('transitions loading → error on generic exception', () async {
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
      ).thenThrow(Exception('Network error'));

      await provider.loadSessions();

      expect(provider.state, ClassSessionLoadState.error);
      expect(provider.errorMessage, isNotNull);
    });

    test('hasMore reflects page.hasMore', () async {
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
      ).thenAnswer((_) async => _makePage([_makeSession(1)], hasMore: true));

      await provider.loadSessions();

      expect(provider.hasMore, isTrue);
    });
  });

  group('loadSessionsByDay', () {
    final day = DateTime(2024, 6, 1);
    final expectedFrom = DateTime.utc(2024, 6, 1, 0, 0, 0);
    final expectedTo = DateTime.utc(2024, 6, 1, 23, 59, 59);

    test('transitions loading → loaded with sessions', () async {
      when(
        () => repository.fetchSchedule(
          from: expectedFrom,
          to: expectedTo,
          gymId: any(named: 'gymId'),
        ),
      ).thenAnswer((_) async => [_makeSession(1), _makeSession(2)]);

      final states = <ClassSessionLoadState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadSessionsByDay(day);

      expect(states, [
        ClassSessionLoadState.loading,
        ClassSessionLoadState.loaded,
      ]);
      expect(provider.sessions.length, 2);
      expect(provider.hasMore, isFalse);
    });

    test('calls fetchSchedule with UTC start/end of day', () async {
      when(
        () => repository.fetchSchedule(
          from: expectedFrom,
          to: expectedTo,
          gymId: any(named: 'gymId'),
        ),
      ).thenAnswer((_) async => []);

      await provider.loadSessionsByDay(day);

      verify(
        () => repository.fetchSchedule(
          from: expectedFrom,
          to: expectedTo,
          gymId: any(named: 'gymId'),
        ),
      ).called(1);
    });

    test('passes gymId to fetchSchedule', () async {
      when(
        () => repository.fetchSchedule(
          from: expectedFrom,
          to: expectedTo,
          gymId: 5,
        ),
      ).thenAnswer((_) async => []);

      await provider.loadSessionsByDay(day, gymId: 5);

      verify(
        () => repository.fetchSchedule(
          from: expectedFrom,
          to: expectedTo,
          gymId: 5,
        ),
      ).called(1);
    });

    test('transitions loading → error on ApiException', () async {
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
          message: 'Schedule fetch failed',
          path: '/class-sessions/schedule',
        ),
      );

      await provider.loadSessionsByDay(day);

      expect(provider.state, ClassSessionLoadState.error);
      expect(provider.errorMessage, 'Schedule fetch failed');
    });

    test('clears sessions from previous paginated load', () async {
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
      ).thenAnswer((_) async => _makePage([_makeSession(1), _makeSession(2)]));
      await provider.loadSessions();
      expect(provider.sessions.length, 2);

      when(
        () => repository.fetchSchedule(
          from: expectedFrom,
          to: expectedTo,
          gymId: any(named: 'gymId'),
        ),
      ).thenAnswer((_) async => [_makeSession(99)]);
      await provider.loadSessionsByDay(day);

      expect(provider.sessions.length, 1);
      expect(provider.sessions.first.id, 99);
    });
  });

  group('loadMore', () {
    setUp(() async {
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
      ).thenAnswer((_) async => _makePage([_makeSession(1)], hasMore: true));
      await provider.loadSessions();
    });

    test('appends sessions, increments page', () async {
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 1),
      ).thenAnswer(
        (_) async => _makePage([_makeSession(2)], hasMore: false, page: 1),
      );

      await provider.loadMore();

      expect(provider.sessions.length, 2);
      expect(provider.sessions.last.id, 2);
      expect(provider.hasMore, isFalse);
    });

    test('no-op when hasMore is false', () async {
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 0),
      ).thenAnswer((_) async => _makePage([_makeSession(1)], hasMore: false));
      await provider.loadSessions();

      await provider.loadMore();

      verifyNever(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 1),
      );
    });

    test('isLoadingMore false after completion', () async {
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 1),
      ).thenAnswer(
        (_) async => _makePage([_makeSession(2)], hasMore: false, page: 1),
      );

      await provider.loadMore();

      expect(provider.isLoadingMore, isFalse);
    });

    test('sets errorMessage on ApiException but keeps loaded state', () async {
      when(
        () => repository.fetchSessions(gymId: any(named: 'gymId'), page: 1),
      ).thenThrow(
        ApiException(
          status: 500,
          error: 'Server Error',
          message: 'Failed to load more',
          path: '/class-sessions',
        ),
      );

      await provider.loadMore();

      expect(provider.errorMessage, 'Failed to load more');
      expect(provider.isLoadingMore, isFalse);
    });
  });
}
