import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/session_roster_provider.dart';

class MockClassSessionRepository extends Mock
    implements ClassSessionRepository {}

RosterEntry _makeEntry(int id, String name) => RosterEntry(
  userId: id,
  userFullName: name,
  userEmail: '$name@example.com',
);

void main() {
  late MockClassSessionRepository repository;
  late SessionRosterProvider provider;

  setUp(() {
    repository = MockClassSessionRepository();
    provider = SessionRosterProvider(repository: repository);
  });

  test('initial state is initial, empty entries', () {
    expect(provider.state, SessionRosterState.initial);
    expect(provider.entries, isEmpty);
    expect(provider.errorMessage, isNull);
  });

  group('load', () {
    test('transitions loading → loaded', () async {
      when(() => repository.fetchRoster(any())).thenAnswer((_) async => []);

      final states = <SessionRosterState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.load(1);

      expect(states, [SessionRosterState.loading, SessionRosterState.loaded]);
    });

    test('sets entries from repository', () async {
      final entries = [_makeEntry(1, 'Jane'), _makeEntry(2, 'Carlos')];
      when(() => repository.fetchRoster(any())).thenAnswer((_) async => entries);

      await provider.load(1);

      expect(provider.entries.length, 2);
      expect(provider.entries.first.userFullName, 'Jane');
    });

    test('transitions loading → error on ApiException', () async {
      when(() => repository.fetchRoster(any())).thenThrow(
        ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Token expired',
          path: '/class-sessions/1/bookings',
        ),
      );

      await provider.load(1);

      expect(provider.state, SessionRosterState.error);
    });

    test('sets errorMessage on ApiException', () async {
      when(() => repository.fetchRoster(any())).thenThrow(
        ApiException(
          status: 500,
          error: 'ServerError',
          message: 'Roster fetch failed',
          path: '/class-sessions/1/bookings',
        ),
      );

      await provider.load(1);

      expect(provider.errorMessage, 'Roster fetch failed');
    });

    test('transitions loading → error on generic exception', () async {
      when(
        () => repository.fetchRoster(any()),
      ).thenThrow(Exception('Network error'));

      await provider.load(1);

      expect(provider.state, SessionRosterState.error);
      expect(provider.errorMessage, isNotNull);
    });
  });
}
