import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/gyms/data/models/gym_models.dart';
import 'package:tfg_frontend/features/gyms/data/repositories/gym_repository.dart';
import 'package:tfg_frontend/features/gyms/presentation/providers/gym_list_provider.dart';
import 'package:tfg_frontend/features/gyms/presentation/screens/gym_list_screen.dart';
import 'package:tfg_frontend/features/membership_plans/presentation/screens/gym_plans_screen.dart';

class MockGymRepository extends Mock implements GymRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

const _gymPageWithResults = GymPage(
  content: [
    Gym(
      id: 1,
      name: 'GymBook Central',
      address: 'Calle Mayor 1',
      city: 'Madrid',
      phone: '+34 91 000 0000',
      openingHours: 'Mon–Fri 07:00–22:00',
      active: true,
    ),
    Gym(
      id: 2,
      name: 'FitLife North',
      address: 'Av. Norte 22',
      city: 'Barcelona',
      openingHours: null,
      active: true,
    ),
  ],
  page: 0,
  size: 20,
  totalElements: 2,
  totalPages: 1,
  hasMore: false,
);

const _emptyGymPage = GymPage(
  content: [],
  page: 0,
  size: 20,
  totalElements: 0,
  totalPages: 0,
  hasMore: false,
);

Widget _buildSubject(MockGymRepository repo) {
  return MultiProvider(
    providers: [
      Provider<TokenStorage>.value(value: MockTokenStorage()),
      Provider<String>.value(value: 'http://localhost:8080/api/v1'),
      ChangeNotifierProvider(create: (_) => GymListProvider(repository: repo)),
    ],
    child: const MaterialApp(home: GymListScreen()),
  );
}

void main() {
  late MockGymRepository repo;

  setUp(() {
    repo = MockGymRepository();
  });

  testWidgets('shows loading indicator while fetching gyms', (tester) async {
    when(() => repo.fetchGyms()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return _gymPageWithResults;
    });

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump();

    expect(find.byKey(const Key('gym_list_loading')), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('shows list of gyms when loaded', (tester) async {
    when(() => repo.fetchGyms()).thenAnswer((_) async => _gymPageWithResults);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gym_list')), findsOneWidget);
    expect(find.text('GymBook Central'), findsOneWidget);
    expect(find.text('FitLife North'), findsOneWidget);
    expect(find.text('Calle Mayor 1, Madrid'), findsOneWidget);
    expect(find.text('Av. Norte 22, Barcelona'), findsOneWidget);
    expect(find.text('Mon–Fri 07:00–22:00'), findsOneWidget);
  });

  testWidgets('shows empty message when gym list is empty', (tester) async {
    when(() => repo.fetchGyms()).thenAnswer((_) async => _emptyGymPage);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gym_list_empty')), findsOneWidget);
    expect(find.text('No hay gimnasios disponibles'), findsOneWidget);
  });

  testWidgets('shows error message on ApiException', (tester) async {
    when(() => repo.fetchGyms()).thenThrow(
      const ApiException(
        status: 500,
        error: 'InternalServerError',
        message: 'Service unavailable',
        path: '/api/v1/gyms',
      ),
    );

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gym_list_error')), findsOneWidget);
    expect(find.text('Service unavailable'), findsOneWidget);
  });

  testWidgets('shows error message on generic exception', (tester) async {
    when(() => repo.fetchGyms()).thenThrow(Exception('Network failure'));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gym_list_error')), findsOneWidget);
  });

  testWidgets('tapping gym card navigates to GymPlansScreen', (tester) async {
    when(() => repo.fetchGyms()).thenAnswer((_) async => _gymPageWithResults);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('GymBook Central'));
    await tester.pumpAndSettle();

    expect(find.byType(GymPlansScreen), findsOneWidget);
  });

  testWidgets('typing in search field triggers debounced search', (
    tester,
  ) async {
    when(() => repo.fetchGyms()).thenAnswer((_) async => _gymPageWithResults);
    when(
      () => repo.fetchGyms(name: 'Central'),
    ).thenAnswer((_) async => _emptyGymPage);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('gym_search_field')),
      'Central',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.byKey(const Key('gym_list_empty')), findsOneWidget);
  });

  testWidgets(
    'shows "Sin resultados" when search returns empty with non-empty query',
    (tester) async {
      when(() => repo.fetchGyms()).thenAnswer((_) async => _gymPageWithResults);
      when(
        () => repo.fetchGyms(name: 'XYZ'),
      ).thenAnswer((_) async => _emptyGymPage);

      await tester.pumpWidget(_buildSubject(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('gym_search_field')), 'XYZ');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('Sin resultados para "XYZ"'), findsOneWidget);
    },
  );

  testWidgets('X button appears when query is non-empty', (tester) async {
    when(() => repo.fetchGyms()).thenAnswer((_) async => _gymPageWithResults);
    when(
      () => repo.fetchGyms(name: 'Gym'),
    ).thenAnswer((_) async => _gymPageWithResults);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.enterText(find.byKey(const Key('gym_search_field')), 'Gym');
    await tester.pump();

    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('tapping X button clears search query', (tester) async {
    when(() => repo.fetchGyms()).thenAnswer((_) async => _gymPageWithResults);
    when(
      () => repo.fetchGyms(name: 'Gym'),
    ).thenAnswer((_) async => _emptyGymPage);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('gym_search_field')), 'Gym');
    await tester.pump();

    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.byIcon(Icons.clear), findsNothing);
    expect(find.byKey(const Key('gym_list')), findsOneWidget);
  });

  testWidgets('scrolling gym list triggers scroll listener', (tester) async {
    when(() => repo.fetchGyms()).thenAnswer((_) async => _gymPageWithResults);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.drag(find.byKey(const Key('gym_list')), const Offset(0, -200));
    await tester.pump();

    expect(find.byKey(const Key('gym_list')), findsOneWidget);
  });

  testWidgets('RefreshIndicator is present when gym list is loaded',
      (tester) async {
    when(() => repo.fetchGyms()).thenAnswer((_) async => _gymPageWithResults);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('pull-to-refresh calls loadGyms again', (tester) async {
    when(() => repo.fetchGyms()).thenAnswer((_) async => _gymPageWithResults);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    final refreshState = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    unawaited(refreshState.show());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    verify(() => repo.fetchGyms()).called(greaterThanOrEqualTo(2));
  });
}
