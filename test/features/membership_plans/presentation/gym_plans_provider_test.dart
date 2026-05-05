import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/models/membership_plan_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/repositories/membership_plan_repository.dart';
import 'package:tfg_frontend/features/membership_plans/presentation/providers/gym_plans_provider.dart';
import 'package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';

class MockMembershipPlanRepository extends Mock
    implements MembershipPlanRepository {}

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

const _plans = [
  MembershipPlan(
    id: 1,
    name: 'Basic',
    description: 'Basic access',
    priceMonthly: 19.99,
    classesPerMonth: 8,
    allowsWaitlist: false,
    active: true,
  ),
];

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
  late MockMembershipPlanRepository planRepo;
  late MockSubscriptionRepository subRepo;
  late GymPlansProvider provider;

  setUp(() {
    planRepo = MockMembershipPlanRepository();
    subRepo = MockSubscriptionRepository();
    provider = GymPlansProvider(
      planRepository: planRepo,
      subscriptionRepository: subRepo,
    );
    when(() => subRepo.fetchMySubscriptions()).thenAnswer((_) async => []);
  });

  group('loadPlans', () {
    test('transitions to loading then loaded and sets plans', () async {
      when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);

      final states = <PlansLoadState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadPlans(gymId: 1);

      expect(states, [PlansLoadState.loading, PlansLoadState.loaded]);
      expect(provider.plans.length, 1);
      expect(provider.plans[0].name, 'Basic');
      expect(provider.errorMessage, isNull);
    });

    test('sets gymSubscription when user has active sub for gym', () async {
      when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);
      when(
        () => subRepo.fetchMySubscriptions(),
      ).thenAnswer((_) async => [_activeSubscription]);

      await provider.loadPlans(gymId: 1);

      expect(provider.gymSubscription, isNotNull);
      expect(provider.gymSubscription!.id, 7);
    });

    test('gymSubscription is null when no sub for this gym', () async {
      when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);
      when(
        () => subRepo.fetchMySubscriptions(),
      ).thenAnswer((_) async => [_activeSubscription]);

      await provider.loadPlans(gymId: 99);

      expect(provider.gymSubscription, isNull);
    });

    test('transitions to error and sets message on ApiException', () async {
      when(() => planRepo.fetchActivePlans()).thenThrow(
        const ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Token expired',
          path: '/membership-plans',
        ),
      );

      await provider.loadPlans(gymId: 1);

      expect(provider.state, PlansLoadState.error);
      expect(provider.errorMessage, 'Token expired');
    });

    test('transitions to error on generic exception', () async {
      when(
        () => planRepo.fetchActivePlans(),
      ).thenThrow(Exception('Network failure'));

      await provider.loadPlans(gymId: 1);

      expect(provider.state, PlansLoadState.error);
      expect(provider.errorMessage, isNotNull);
    });
  });

  group('subscribe', () {
    test('returns true on success and clears errorMessage', () async {
      when(
        () => subRepo.subscribe(
          membershipPlanId: any(named: 'membershipPlanId'),
          gymId: any(named: 'gymId'),
        ),
      ).thenAnswer((_) async {});

      final result = await provider.subscribe(membershipPlanId: 1, gymId: 2);

      expect(result, true);
      expect(provider.isSubscribing, false);
      expect(provider.errorMessage, isNull);
    });

    test('returns false and sets errorMessage on ApiException', () async {
      when(
        () => subRepo.subscribe(
          membershipPlanId: any(named: 'membershipPlanId'),
          gymId: any(named: 'gymId'),
        ),
      ).thenThrow(
        const ApiException(
          status: 409,
          error: 'Conflict',
          message: 'Already subscribed to this gym',
          path: '/subscriptions',
        ),
      );

      final result = await provider.subscribe(membershipPlanId: 1, gymId: 2);

      expect(result, false);
      expect(provider.errorMessage, 'Already subscribed to this gym');
      expect(provider.isSubscribing, false);
    });

    test('returns false and sets errorMessage on generic exception', () async {
      when(
        () => subRepo.subscribe(
          membershipPlanId: any(named: 'membershipPlanId'),
          gymId: any(named: 'gymId'),
        ),
      ).thenThrow(Exception('Network failure'));

      final result = await provider.subscribe(membershipPlanId: 1, gymId: 2);

      expect(result, false);
      expect(provider.isSubscribing, false);
      expect(provider.errorMessage, isNotNull);
    });

    test('isSubscribing is true while pending and false after', () async {
      when(
        () => subRepo.subscribe(
          membershipPlanId: any(named: 'membershipPlanId'),
          gymId: any(named: 'gymId'),
        ),
      ).thenAnswer((_) async {});

      final subscribingValues = <bool>[];
      provider.addListener(() => subscribingValues.add(provider.isSubscribing));

      await provider.subscribe(membershipPlanId: 1, gymId: 2);

      expect(subscribingValues, containsAllInOrder([true, false]));
    });
  });

  group('upgrade', () {
    test('returns true and updates gymSubscription on success', () async {
      const upgraded = Subscription(
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
        pendingCancellation: false,
        pendingPlan: SubscriptionPlan(
          id: 3,
          name: 'Premium',
          priceMonthly: 49.99,
        ),
      );

      when(
        () => subRepo.upgradeSubscription(
          subscriptionId: any(named: 'subscriptionId'),
          newMembershipPlanId: any(named: 'newMembershipPlanId'),
        ),
      ).thenAnswer((_) async => upgraded);

      final result = await provider.upgrade(
        subscriptionId: 7,
        newMembershipPlanId: 3,
      );

      expect(result, true);
      expect(provider.gymSubscription?.pendingPlan?.name, 'Premium');
      expect(provider.isSubscribing, false);
    });

    test('returns false and sets errorMessage on ApiException', () async {
      when(
        () => subRepo.upgradeSubscription(
          subscriptionId: any(named: 'subscriptionId'),
          newMembershipPlanId: any(named: 'newMembershipPlanId'),
        ),
      ).thenThrow(
        const ApiException(
          status: 409,
          error: 'Conflict',
          message: 'Subscription not active',
          path: '/subscriptions/7/upgrade',
        ),
      );

      final result = await provider.upgrade(
        subscriptionId: 7,
        newMembershipPlanId: 3,
      );

      expect(result, false);
      expect(provider.errorMessage, 'Subscription not active');
      expect(provider.isSubscribing, false);
    });

    test('returns false and sets errorMessage on generic exception', () async {
      when(
        () => subRepo.upgradeSubscription(
          subscriptionId: any(named: 'subscriptionId'),
          newMembershipPlanId: any(named: 'newMembershipPlanId'),
        ),
      ).thenThrow(Exception('Network failure'));

      final result = await provider.upgrade(
        subscriptionId: 7,
        newMembershipPlanId: 3,
      );

      expect(result, false);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isSubscribing, false);
    });
  });
}
