import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/screens/my_subscription_screen.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

const _baseUrl = 'http://localhost:8080/api/v1';

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
);

Widget _buildSubject(MockSubscriptionRepository repo) {
  final tokenStorage = MockTokenStorage();
  return MultiProvider(
    providers: [
      Provider<TokenStorage>.value(value: tokenStorage),
      Provider<String>.value(value: _baseUrl),
      ChangeNotifierProvider(
        create: (_) => SubscriptionProvider(repository: repo),
      ),
    ],
    // ignore: prefer_const_constructors
    child: MaterialApp(home: Scaffold(body: MySubscriptionScreen())),
  );
}

void main() {
  late MockSubscriptionRepository repo;

  setUp(() {
    repo = MockSubscriptionRepository();
  });

  testWidgets('shows loading indicator while fetching subscription', (
    tester,
  ) async {
    when(() => repo.fetchMySubscription()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return _activeSubscription;
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
      () => repo.fetchMySubscription(),
    ).thenAnswer((_) async => _activeSubscription);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('subscription_card')), findsOneWidget);
    expect(find.text('GymBook Central'), findsOneWidget);
    expect(find.text('Calle Mayor 1, Madrid'), findsOneWidget);
    expect(find.text('Premium Monthly'), findsOneWidget);
    expect(find.text('\$49.99 / month'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('shows "Unlimited" when classesRemainingThisMonth is null', (
    tester,
  ) async {
    when(
      () => repo.fetchMySubscription(),
    ).thenAnswer((_) async => _cancelledSubscription);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('Unlimited'), findsOneWidget);
    expect(find.text('CANCELLED'), findsOneWidget);
  });

  testWidgets('shows empty state when subscription is null', (tester) async {
    when(() => repo.fetchMySubscription()).thenAnswer((_) async => null);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('No active subscription'), findsOneWidget);
    expect(find.byKey(const Key('browse_gyms_button')), findsOneWidget);
  });

  testWidgets('shows error message on ApiException', (tester) async {
    when(() => repo.fetchMySubscription()).thenThrow(
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
      () => repo.fetchMySubscription(),
    ).thenAnswer((_) async => _expiredSubscription);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('EXPIRED'), findsOneWidget);
  });

  testWidgets('shows error message on generic exception', (tester) async {
    when(
      () => repo.fetchMySubscription(),
    ).thenThrow(Exception('Network failure'));

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('subscription_error')), findsOneWidget);
  });

  testWidgets('browse gyms button navigates to GymListScreen when tapped', (
    tester,
  ) async {
    when(() => repo.fetchMySubscription()).thenAnswer((_) async => null);

    await tester.pumpWidget(_buildSubject(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('browse_gyms_button')));
    await tester.pumpAndSettle();

    expect(find.text('Gyms'), findsOneWidget);
  });
}
