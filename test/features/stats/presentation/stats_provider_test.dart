import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/stats/data/models/stats_models.dart';
import 'package:tfg_frontend/features/stats/data/repositories/stats_repository.dart';
import 'package:tfg_frontend/features/stats/presentation/providers/stats_provider.dart';

class MockStatsRepository extends Mock implements StatsRepository {}

const _stats = UserStats(
  totalBookings: 42,
  totalAttended: 38,
  totalNoShows: 2,
  totalCancellations: 4,
  attendanceRate: 0.95,
  currentStreak: 5,
  favoriteClassType: 'Spinning 45min',
  classesBookedThisMonth: 8,
  classesRemainingThisMonth: 12,
);

void main() {
  late MockStatsRepository repository;
  late StatsProvider provider;

  setUp(() {
    repository = MockStatsRepository();
    provider = StatsProvider(repository: repository);
  });

  test('initial state is initial', () {
    expect(provider.state, StatsLoadState.initial);
    expect(provider.stats, isNull);
    expect(provider.errorMessage, isNull);
  });

  group('loadStats', () {
    test('transitions loading → loaded, sets stats', () async {
      when(() => repository.getMyStats()).thenAnswer((_) async => _stats);

      final states = <StatsLoadState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadStats();

      expect(states, [StatsLoadState.loading, StatsLoadState.loaded]);
      expect(provider.stats, _stats);
      expect(provider.errorMessage, isNull);
    });

    test('transitions loading → error on ApiException', () async {
      when(() => repository.getMyStats()).thenThrow(
        ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Token expired',
          path: '/stats/me',
        ),
      );

      await provider.loadStats();

      expect(provider.state, StatsLoadState.error);
      expect(provider.errorMessage, 'Token expired');
      expect(provider.stats, isNull);
    });

    test('transitions loading → error on generic exception', () async {
      when(() => repository.getMyStats()).thenThrow(Exception('Network error'));

      await provider.loadStats();

      expect(provider.state, StatsLoadState.error);
      expect(provider.errorMessage, isNotNull);
    });

    test('clears previous error on retry', () async {
      when(() => repository.getMyStats()).thenThrow(
        ApiException(
          status: 500,
          error: 'Server Error',
          message: 'Internal error',
          path: '/stats/me',
        ),
      );
      await provider.loadStats();
      expect(provider.state, StatsLoadState.error);

      when(() => repository.getMyStats()).thenAnswer((_) async => _stats);
      await provider.loadStats();

      expect(provider.state, StatsLoadState.loaded);
      expect(provider.errorMessage, isNull);
    });

    test('notifyListeners called twice (loading + completion)', () async {
      when(() => repository.getMyStats()).thenAnswer((_) async => _stats);

      var count = 0;
      provider.addListener(() => count++);

      await provider.loadStats();

      expect(count, 2);
    });
  });
}
