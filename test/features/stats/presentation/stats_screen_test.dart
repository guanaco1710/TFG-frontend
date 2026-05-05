import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/stats/data/models/stats_models.dart';
import 'package:tfg_frontend/features/stats/data/repositories/stats_repository.dart';
import 'package:tfg_frontend/features/stats/presentation/providers/stats_provider.dart';
import 'package:tfg_frontend/features/stats/presentation/screens/stats_screen.dart';

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

Widget _wrap(StatsProvider provider) => ChangeNotifierProvider.value(
  value: provider,
  child: const MaterialApp(home: Scaffold(body: StatsScreen())),
);

void main() {
  late MockStatsRepository repository;

  setUp(() {
    repository = MockStatsRepository();
  });

  testWidgets('shows loading indicator initially', (tester) async {
    when(
      () => repository.getMyStats(),
    ).thenAnswer((_) => Completer<UserStats>().future);
    final provider = StatsProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byKey(const Key('stats_loading')), findsOneWidget);
  });

  testWidgets('shows stat cards when loaded', (tester) async {
    when(() => repository.getMyStats()).thenAnswer((_) async => _stats);
    final provider = StatsProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stat_attended')), findsOneWidget);
    expect(find.byKey(const Key('stat_streak')), findsOneWidget);
    expect(find.byKey(const Key('stat_rate')), findsOneWidget);
    expect(find.byKey(const Key('stat_this_month')), findsOneWidget);
  });

  testWidgets('shows correct values in stat cards', (tester) async {
    when(() => repository.getMyStats()).thenAnswer((_) async => _stats);
    final provider = StatsProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('38'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('shows detail section', (tester) async {
    when(() => repository.getMyStats()).thenAnswer((_) async => _stats);
    final provider = StatsProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_total_bookings')), findsOneWidget);
    expect(find.byKey(const Key('detail_no_shows')), findsOneWidget);
    expect(find.byKey(const Key('detail_cancellations')), findsOneWidget);
    expect(find.byKey(const Key('detail_remaining')), findsOneWidget);
    expect(find.byKey(const Key('detail_favorite')), findsOneWidget);
  });

  testWidgets('hides remaining when classesRemainingThisMonth is null', (
    tester,
  ) async {
    const noRemaining = UserStats(
      totalBookings: 10,
      totalAttended: 9,
      totalNoShows: 0,
      totalCancellations: 1,
      attendanceRate: 0.9,
      currentStreak: 2,
      classesBookedThisMonth: 3,
    );
    when(() => repository.getMyStats()).thenAnswer((_) async => noRemaining);
    final provider = StatsProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_remaining')), findsNothing);
    expect(find.byKey(const Key('detail_favorite')), findsNothing);
  });

  testWidgets('shows error state with retry button on failure', (tester) async {
    when(() => repository.getMyStats()).thenThrow(
      ApiException(
        status: 401,
        error: 'Unauthorized',
        message: 'Token expired',
        path: '/stats/me',
      ),
    );
    final provider = StatsProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stats_error')), findsOneWidget);
    expect(find.byKey(const Key('stats_retry_button')), findsOneWidget);
    expect(find.text('Token expired'), findsOneWidget);
  });

  testWidgets('retry button calls loadStats again', (tester) async {
    when(() => repository.getMyStats()).thenThrow(
      ApiException(
        status: 500,
        error: 'Server Error',
        message: 'Internal error',
        path: '/stats/me',
      ),
    );
    final provider = StatsProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    when(() => repository.getMyStats()).thenAnswer((_) async => _stats);

    await tester.tap(find.byKey(const Key('stats_retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stat_attended')), findsOneWidget);
  });

  testWidgets('shows favorite class type in detail', (tester) async {
    when(() => repository.getMyStats()).thenAnswer((_) async => _stats);
    final provider = StatsProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Spinning 45min'), findsOneWidget);
  });
}
