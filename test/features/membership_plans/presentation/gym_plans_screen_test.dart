import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/gyms/data/models/gym_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/models/membership_plan_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/repositories/membership_plan_repository.dart';
import 'package:tfg_frontend/features/membership_plans/presentation/providers/gym_plans_provider.dart';
import 'package:tfg_frontend/features/membership_plans/presentation/screens/gym_plans_screen.dart';
import 'package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';

class MockMembershipPlanRepository extends Mock
    implements MembershipPlanRepository {}

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

const _gym = Gym(
  id: 1,
  name: 'GymBook Central',
  address: 'Calle Mayor 1',
  city: 'Madrid',
  active: true,
);

const _plans = [
  MembershipPlan(
    id: 1,
    name: 'Basic',
    description: 'Entry-level access',
    priceMonthly: 19.99,
    classesPerMonth: 8,
    allowsWaitlist: false,
    active: true,
  ),
  MembershipPlan(
    id: 2,
    name: 'Premium',
    description: 'Unlimited everything',
    priceMonthly: 49.99,
    classesPerMonth: null,
    allowsWaitlist: true,
    active: true,
  ),
];

const _activeSubBasic = Subscription(
  id: 7,
  plan: SubscriptionPlan(id: 1, name: 'Basic', priceMonthly: 19.99),
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
  classesRemainingThisMonth: 3,
  pendingCancellation: false,
);

Widget _buildSubject(
  MockMembershipPlanRepository planRepo,
  MockSubscriptionRepository subRepo,
) {
  return ChangeNotifierProvider(
    create: (_) => GymPlansProvider(
      planRepository: planRepo,
      subscriptionRepository: subRepo,
    ),
    child: const MaterialApp(home: GymPlansScreen(gym: _gym)),
  );
}

// Builds with a navigable parent so GymPlansScreen can be popped.
Widget _buildWithParent(
  MockMembershipPlanRepository planRepo,
  MockSubscriptionRepository subRepo,
) {
  return MaterialApp(
    home: Builder(
      builder: (ctx) => Scaffold(
        body: ElevatedButton(
          key: const Key('open_plans'),
          onPressed: () => Navigator.of(ctx).push(
            MaterialPageRoute<void>(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => GymPlansProvider(
                  planRepository: planRepo,
                  subscriptionRepository: subRepo,
                ),
                child: const GymPlansScreen(gym: _gym),
              ),
            ),
          ),
          child: const Text('Parent'),
        ),
      ),
    ),
  );
}

void main() {
  late MockMembershipPlanRepository planRepo;
  late MockSubscriptionRepository subRepo;

  setUp(() {
    planRepo = MockMembershipPlanRepository();
    subRepo = MockSubscriptionRepository();
    when(() => subRepo.fetchMySubscriptions()).thenAnswer((_) async => []);
  });

  testWidgets('shows loading indicator while fetching plans', (tester) async {
    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return _plans;
    });

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('shows plan cards when plans are loaded (no subscription)', (
    tester,
  ) async {
    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('Entry-level access'), findsOneWidget);
    expect(find.text('19.99 €'), findsOneWidget);
    expect(find.text('49.99 €'), findsOneWidget);
    expect(find.text('8 clases / mes'), findsOneWidget);
    expect(find.text('Clases ilimitadas'), findsOneWidget);
    expect(find.text('Lista de espera'), findsOneWidget);
    expect(find.text('Unirse'), findsNWidgets(2));
  });

  testWidgets(
    'shows Suscrito button (disabled) for current plan and Cambiar plan for others',
    (tester) async {
      when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);
      when(
        () => subRepo.fetchMySubscriptions(),
      ).thenAnswer((_) async => [_activeSubBasic]);

      await tester.pumpWidget(_buildSubject(planRepo, subRepo));
      await tester.pumpAndSettle();

      expect(find.text('Suscrito'), findsOneWidget);
      expect(find.text('Cambiar plan'), findsOneWidget);
      expect(find.text('Unirse'), findsNothing);
    },
  );

  testWidgets('shows Cambio pendiente button when pendingPlan matches plan', (
    tester,
  ) async {
    const subWithPending = Subscription(
      id: 7,
      plan: SubscriptionPlan(id: 1, name: 'Basic', priceMonthly: 19.99),
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
      classesRemainingThisMonth: 3,
      pendingCancellation: false,
      pendingPlan: SubscriptionPlan(id: 2, name: 'Premium', priceMonthly: 49.99),
    );

    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);
    when(
      () => subRepo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [subWithPending]);

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    expect(find.text('Suscrito'), findsOneWidget);
    expect(find.text('Cambio pendiente'), findsOneWidget);
  });

  testWidgets('shows empty state when no plans available', (tester) async {
    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => []);

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    expect(find.text('No hay planes disponibles'), findsOneWidget);
  });

  testWidgets('shows error message on ApiException', (tester) async {
    when(() => planRepo.fetchActivePlans()).thenThrow(
      const ApiException(
        status: 500,
        error: 'InternalServerError',
        message: 'Service unavailable',
        path: '/membership-plans',
      ),
    );

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    expect(find.text('Service unavailable'), findsOneWidget);
  });

  testWidgets('shows error message on generic exception', (tester) async {
    when(
      () => planRepo.fetchActivePlans(),
    ).thenThrow(Exception('Network failure'));

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    expect(find.text('Ha ocurrido un error inesperado'), findsOneWidget);
  });

  testWidgets('tapping Unirse shows confirmation dialog', (tester) async {
    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unirse').first);
    await tester.pumpAndSettle();

    expect(find.text('Confirmar suscripción'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('tapping Cambiar plan shows upgrade dialog with next-cycle text',
    (tester) async {
    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);
    when(
      () => subRepo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubBasic]);

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cambiar plan'));
    await tester.pumpAndSettle();

    expect(find.text('Cambiar plan'), findsNWidgets(2));
    expect(
      find.textContaining('próximo ciclo de facturación'),
      findsOneWidget,
    );
    expect(find.text('Aceptar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('cancelling upgrade dialog does not call upgradeSubscription', (
    tester,
  ) async {
    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);
    when(
      () => subRepo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubBasic]);

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cambiar plan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(
      () => subRepo.upgradeSubscription(
        subscriptionId: any(named: 'subscriptionId'),
        newMembershipPlanId: any(named: 'newMembershipPlanId'),
      ),
    );
    expect(find.text('Cambiar plan'), findsOneWidget);
  });

  testWidgets('confirming upgrade on success shows success snackbar', (
    tester,
  ) async {
    const upgraded = Subscription(
      id: 7,
      plan: SubscriptionPlan(id: 1, name: 'Basic', priceMonthly: 19.99),
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
      classesRemainingThisMonth: 3,
      pendingCancellation: false,
      pendingPlan: SubscriptionPlan(id: 2, name: 'Premium', priceMonthly: 49.99),
    );

    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);
    when(
      () => subRepo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubBasic]);
    when(
      () => subRepo.upgradeSubscription(
        subscriptionId: any(named: 'subscriptionId'),
        newMembershipPlanId: any(named: 'newMembershipPlanId'),
      ),
    ).thenAnswer((_) async => upgraded);

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cambiar plan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('próximo ciclo de facturación'),
      findsOneWidget,
    );
  });

  testWidgets('confirming upgrade on failure shows error snackbar', (
    tester,
  ) async {
    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);
    when(
      () => subRepo.fetchMySubscriptions(),
    ).thenAnswer((_) async => [_activeSubBasic]);
    when(
      () => subRepo.upgradeSubscription(
        subscriptionId: any(named: 'subscriptionId'),
        newMembershipPlanId: any(named: 'newMembershipPlanId'),
      ),
    ).thenThrow(
      const ApiException(
        status: 409,
        error: 'Conflict',
        message: 'Plan ya programado',
        path: '/subscriptions/7/upgrade',
      ),
    );

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cambiar plan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(find.text('Plan ya programado'), findsOneWidget);
  });

  testWidgets('cancelling dialog does not call subscribe', (tester) async {
    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unirse').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(
      () => subRepo.subscribe(
        membershipPlanId: any(named: 'membershipPlanId'),
        gymId: any(named: 'gymId'),
      ),
    );
    expect(find.text('Confirmar suscripción'), findsNothing);
  });

  testWidgets(
    'confirming subscribe on success shows snackbar and pops screen',
    (tester) async {
      when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);
      when(
        () => subRepo.subscribe(
          membershipPlanId: any(named: 'membershipPlanId'),
          gymId: any(named: 'gymId'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(_buildWithParent(planRepo, subRepo));
      await tester.tap(find.byKey(const Key('open_plans')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unirse').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('¡Te has suscrito correctamente!'), findsOneWidget);
      expect(find.text('Parent'), findsOneWidget);
    },
  );

  testWidgets('confirming subscribe on failure shows error snackbar', (
    tester,
  ) async {
    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);
    when(
      () => subRepo.subscribe(
        membershipPlanId: any(named: 'membershipPlanId'),
        gymId: any(named: 'gymId'),
      ),
    ).thenThrow(
      const ApiException(
        status: 409,
        error: 'Conflict',
        message: 'Ya tienes una suscripción activa',
        path: '/subscriptions',
      ),
    );

    await tester.pumpWidget(_buildWithParent(planRepo, subRepo));
    await tester.tap(find.byKey(const Key('open_plans')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unirse').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Ya tienes una suscripción activa'), findsOneWidget);
    expect(find.byType(GymPlansScreen), findsOneWidget);
  });

  testWidgets('AppBar title shows gym name', (tester) async {
    when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);

    await tester.pumpWidget(_buildSubject(planRepo, subRepo));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('GymBook Central'),
      ),
      findsOneWidget,
    );
  });
}
