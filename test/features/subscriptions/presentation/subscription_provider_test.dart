import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/providers/subscription_provider.dart';

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

void main() {
  late MockSubscriptionRepository repo;
  late SubscriptionProvider provider;

  setUp(() {
    repo = MockSubscriptionRepository();
    provider = SubscriptionProvider(repository: repo);
  });

  group('loadMySubscriptions', () {
    test('transitions loading → loaded and sets subscriptions', () async {
      when(
        () => repo.fetchMySubscriptions(),
      ).thenAnswer((_) async => [_activeSubscription]);

      final states = <SubscriptionLoadState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadMySubscriptions();

      expect(states, [
        SubscriptionLoadState.loading,
        SubscriptionLoadState.loaded,
      ]);
      expect(provider.subscriptions.length, 1);
      expect(provider.subscriptions[0].id, 7);
      expect(provider.errorMessage, isNull);
    });

    test('returns empty list when no subscriptions', () async {
      when(() => repo.fetchMySubscriptions()).thenAnswer((_) async => []);

      await provider.loadMySubscriptions();

      expect(provider.state, SubscriptionLoadState.loaded);
      expect(provider.subscriptions, isEmpty);
    });

    test('transitions to error on ApiException', () async {
      when(() => repo.fetchMySubscriptions()).thenThrow(
        const ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Token expired',
          path: '/subscriptions/me',
        ),
      );

      await provider.loadMySubscriptions();

      expect(provider.state, SubscriptionLoadState.error);
      expect(provider.errorMessage, 'Token expired');
    });

    test('transitions to error on generic exception', () async {
      when(
        () => repo.fetchMySubscriptions(),
      ).thenThrow(Exception('Network failure'));

      await provider.loadMySubscriptions();

      expect(provider.state, SubscriptionLoadState.error);
      expect(provider.errorMessage, isNotNull);
    });
  });

  group('cancelSubscription', () {
    setUp(() {
      when(
        () => repo.fetchMySubscriptions(),
      ).thenAnswer((_) async => [_activeSubscription]);
    });

    test('returns true and reloads subscriptions on success', () async {
      when(
        () => repo.cancelSubscription(
          subscriptionId: any(named: 'subscriptionId'),
        ),
      ).thenAnswer((_) async {});

      final result = await provider.cancelSubscription(subscriptionId: 7);

      expect(result, true);
      expect(provider.isCancelling, false);
      expect(provider.errorMessage, isNull);
      verify(() => repo.fetchMySubscriptions()).called(1);
    });

    test('returns false and sets errorMessage on ApiException', () async {
      when(
        () => repo.cancelSubscription(
          subscriptionId: any(named: 'subscriptionId'),
        ),
      ).thenThrow(
        const ApiException(
          status: 409,
          error: 'Conflict',
          message: 'Cancellation already pending',
          path: '/subscriptions/7/cancel',
        ),
      );

      final result = await provider.cancelSubscription(subscriptionId: 7);

      expect(result, false);
      expect(provider.errorMessage, 'Cancellation already pending');
      expect(provider.isCancelling, false);
    });

    test('returns false and sets errorMessage on generic exception', () async {
      when(
        () => repo.cancelSubscription(
          subscriptionId: any(named: 'subscriptionId'),
        ),
      ).thenThrow(Exception('Network failure'));

      final result = await provider.cancelSubscription(subscriptionId: 7);

      expect(result, false);
      expect(provider.isCancelling, false);
      expect(provider.errorMessage, isNotNull);
    });

    test('isCancelling is true while pending and false after', () async {
      when(
        () => repo.cancelSubscription(
          subscriptionId: any(named: 'subscriptionId'),
        ),
      ).thenAnswer((_) async {});

      final cancellingValues = <bool>[];
      provider.addListener(() => cancellingValues.add(provider.isCancelling));

      await provider.cancelSubscription(subscriptionId: 7);

      expect(cancellingValues, containsAllInOrder([true, false]));
    });
  });
}
