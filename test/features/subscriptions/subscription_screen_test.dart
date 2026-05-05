import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/exceptions/api_exception.dart';
import 'package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/screens/my_subscription_screen.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

const _activeSubscription = Subscription(
  id: 7,
  plan: SubscriptionPlan(id: 2, name: 'Premium Monthly', priceMonthly: 49.99),
  gym: SubscriptionGym(
    id: 1,
    name: 'GymBook Central',
    address: 'Calle Mayor 1',
    city: 'Madrid',
  ),
  status: SubscriptionStatus.active,
  startDate: '2024-05-01',
  renewalDate: '2024-06-01',
  classesUsedThisMonth: 5,
  classesRemainingThisMonth: 7,
  pendingCancellation: false,
);

const _expiredSubscription = Subscription(
  id: 9,
  plan: SubscriptionPlan(id: 1, name: 'Basic', priceMonthly: 19.99),
  gym: SubscriptionGym(
    id: 1,
    name: 'GymBook Central',
    address: 'Calle Mayor 1',
    city: 'Madrid',
  ),
  status: SubscriptionStatus.expired,
  startDate: '2024-01-01',
  renewalDate: '2024-02-01',
  endDate: '2024-02-01',
  classesUsedThisMonth: 0,
  classesRemainingThisMonth: null,
  pendingCancellation: false,
);

const _cancelledSubscription = Subscription(
  id: 8,
  plan: SubscriptionPlan(id: 1, name: 'Basic', priceMonthly: 19.99),
  gym: SubscriptionGym(
    id: 1,
    name: 'GymBook Central',
    address: 'Calle Mayor 1',
    city: 'Madrid',
  ),
  status: SubscriptionStatus.cancelled,
  startDate: '2024-03-01',
  renewalDate: '2024-04-01',
  endDate: '2024-04-15',
  classesUsedThisMonth: 0,
  classesRemainingThisMonth: null,
  pendingCancellation: false,
);

Widget _buildSubject(MockSubscriptionRepository repo) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => SubscriptionProvider(repository: repo),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: MySubscriptionScreen(
          gymListScreenBuilder: () => const Scaffold(
            appBar: null,
            body: Center(child: Text('Gimnasios')),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockSubscriptionRepository repo;

  setUp(() {
    repo = MockSubscriptionRepository();
  });

  testWidgets('shows loading indicator while fetching subscriptions', (
    tester,
  ) async {
    when(() => repo.fetchMySubscriptions()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return [_activeSubscription];
    });

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pump();

    expect(find.byKey(const Key('subscription_loading')), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('shows subscription card when subscription is loaded', (
    tester,
  ) async {
    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubscription]);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('subscription_card')), findsOneWidget);
    expect(find.text('GymBook Central'), findsOneWidget);
    expect(find.text('Calle Mayor 1, Madrid'), findsOneWidget);
    expect(find.text('Premium Monthly'), findsOneWidget);
    expect(find.text('49.99 € / mes'), findsOneWidget);
    expect(find.text('ACTIVA'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('shows multiple subscription cards', (tester) async {
    const secondSub = Subscription(
      id: 10,
      plan: SubscriptionPlan(id: 1, name: 'Basic', priceMonthly: 19.99),
      gym: SubscriptionGym(
        id: 2,
        name: 'Gym Norte',
        address: 'Calle Norte 5',
        city: 'Barcelona',
      ),
      status: SubscriptionStatus.active,
      startDate: '2024-05-01',
      renewalDate: '2024-06-01',
      classesUsedThisMonth: 2,
      classesRemainingThisMonth: 6,
      pendingCancellation: false,
    );

    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubscription, secondSub]);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('subscription_card')), findsNWidgets(2));
    expect(find.text('GymBook Central'), findsOneWidget);
    expect(find.text('Gym Norte'), findsOneWidget);
  });

  testWidgets('shows "Ilimitadas" when classesRemainingThisMonth is null', (
    tester,
  ) async {
    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_cancelledSubscription]);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('Ilimitadas'), findsOneWidget);
    expect(find.text('CANCELADA'), findsOneWidget);
  });

  testWidgets('shows empty state when subscription list is empty', (
    tester,
  ) async {
    when(() => repo.fetchMySubscriptions()).thenAnswer((_) async => []);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('Sin suscripción activa'), findsOneWidget);
    expect(find.byKey(const Key('browse_gyms_button')), findsOneWidget);
  });

  testWidgets('shows error message on ApiException', (tester) async {
    when(() => repo.fetchMySubscriptions()).thenThrow(
      const ApiException(
        status: 401,
        error: 'Unauthorized',
        message: 'Token expired',
        path: '/api/v1/subscriptions/me',
      ),
    );

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('subscription_error')), findsOneWidget);
    expect(find.text('Token expired'), findsOneWidget);
  });

  testWidgets('shows EXPIRED status badge for expired subscription', (
    tester,
  ) async {
    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_expiredSubscription]);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('EXPIRADA'), findsOneWidget);
  });

  testWidgets('shows error message on generic exception', (tester) async {
    when(
      () => repo.fetchMySubscriptions(),
    ).thenThrow(Exception('Network failure'));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('subscription_error')), findsOneWidget);
  });

  testWidgets('browse gyms button navigates to GymListScreen when tapped', (
    tester,
  ) async {
    when(() => repo.fetchMySubscriptions()).thenAnswer((_) async => []);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('browse_gyms_button')));
    await tester.pumpAndSettle();

    expect(find.text('Gimnasios'), findsOneWidget);
  });

  testWidgets('shows pending plan info when pendingPlan is set', (
    tester,
  ) async {
    const subWithPending = Subscription(
      id: 7,
      plan: SubscriptionPlan(id: 2, name: 'Basic', priceMonthly: 19.99),
      gym: SubscriptionGym(
        id: 1,
        name: 'GymBook Central',
        address: 'Calle Mayor 1',
        city: 'Madrid',
      ),
      status: SubscriptionStatus.active,
      startDate: '2024-05-01',
      renewalDate: '2024-06-01',
      classesUsedThisMonth: 3,
      classesRemainingThisMonth: 5,
      pendingCancellation: false,
      pendingPlan: SubscriptionPlan(
        id: 3,
        name: 'Premium',
        priceMonthly: 49.99,
      ),
    );

    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [subWithPending]);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('Próximo plan'), findsOneWidget);
    expect(find.textContaining('Premium'), findsOneWidget);
  });

  testWidgets(
    'shows CANCELACIÓN PENDIENTE badge when pendingCancellation true',
    (tester) async {
      const subPendingCancel = Subscription(
        id: 7,
        plan: SubscriptionPlan(
          id: 2,
          name: 'Premium Monthly',
          priceMonthly: 49.99,
        ),
        gym: SubscriptionGym(
          id: 1,
          name: 'GymBook Central',
          address: 'Calle Mayor 1',
          city: 'Madrid',
        ),
        status: SubscriptionStatus.active,
        startDate: '2024-05-01',
        renewalDate: '2024-06-01',
        classesUsedThisMonth: 5,
        classesRemainingThisMonth: 7,
        pendingCancellation: true,
      );

      when(
        () => repo.fetchMySubscriptions(),
      ).thenAnswer((_) async => [subPendingCancel]);

      await tester.pumpWidget(_buildSubject(repo));
      await tester.pumpAndSettle();

      expect(find.text('CANCELACIÓN PENDIENTE'), findsOneWidget);
    },
  );

  testWidgets(
    'shows cancel button for active subscription without pending cancel',
    (tester) async {
      when(
        () => repo.fetchMySubscriptions(),
      ).thenAnswer((_) async => [_activeSubscription]);

      await tester.pumpWidget(_buildSubject(repo));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cancel_subscription_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets('does not show cancel button when pendingCancellation is true', (
    tester,
  ) async {
    const subPendingCancel = Subscription(
      id: 7,
      plan: SubscriptionPlan(
        id: 2,
        name: 'Premium Monthly',
        priceMonthly: 49.99,
      ),
      gym: SubscriptionGym(
        id: 1,
        name: 'GymBook Central',
        address: 'Calle Mayor 1',
        city: 'Madrid',
      ),
      status: SubscriptionStatus.active,
      startDate: '2024-05-01',
      renewalDate: '2024-06-01',
      classesUsedThisMonth: 5,
      classesRemainingThisMonth: 7,
      pendingCancellation: true,
    );

    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [subPendingCancel]);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cancel_subscription_button')), findsNothing);
  });

  testWidgets('does not show cancel button for expired subscription', (
    tester,
  ) async {
    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_expiredSubscription]);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cancel_subscription_button')), findsNothing);
  });

  testWidgets('tapping cancel button shows confirmation dialog', (
    tester,
  ) async {
    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubscription]);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_subscription_button')));
    await tester.pumpAndSettle();

    expect(find.text('Cancelar suscripción'), findsAtLeastNWidgets(1));
    expect(find.text('Volver'), findsOneWidget);
    expect(find.textContaining('GymBook Central'), findsAtLeastNWidgets(1));
  });

  testWidgets('tapping Volver in dialog does not call cancelSubscription', (
    tester,
  ) async {
    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubscription]);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_subscription_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    verifyNever(
      () =>
          repo.cancelSubscription(subscriptionId: any(named: 'subscriptionId')),
    );
  });

  testWidgets('confirming cancel on success shows snackbar', (tester) async {
    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubscription]);
    when(
      () =>
          repo.cancelSubscription(subscriptionId: any(named: 'subscriptionId')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_subscription_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar suscripción').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('cancelada'), findsOneWidget);
  });

  testWidgets('confirming cancel on failure shows error snackbar', (
    tester,
  ) async {
    when(
      () => repo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubscription]);
    when(
      () =>
          repo.cancelSubscription(subscriptionId: any(named: 'subscriptionId')),
    ).thenThrow(
      const ApiException(
        status: 409,
        error: 'Conflict',
        message: 'Ya está pendiente de cancelación',
        path: '/subscriptions/7/cancel',
      ),
    );

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_subscription_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar suscripción').last);
    await tester.pumpAndSettle();

    expect(find.text('Ya está pendiente de cancelación'), findsOneWidget);
  });

  testWidgets(
    'renders subscription screen without TokenStorage in provider tree',
    (tester) async {
      when(() => repo.fetchMySubscriptions()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(repository: repo),
          child: MaterialApp(
            home: Scaffold(
              body: MySubscriptionScreen(
                gymListScreenBuilder: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('browse_gyms_button')), findsOneWidget);
    },
  );
}
