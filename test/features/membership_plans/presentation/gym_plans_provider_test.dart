import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/models/membership_plan_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/repositories/membership_plan_repository.dart';
import 'package:tfg_frontend/features/membership_plans/presentation/providers/gym_plans_provider.dart';
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
  });

  group('loadPlans', () {
    test('transitions to loading then loaded and sets plans', () async {
      when(() => planRepo.fetchActivePlans()).thenAnswer((_) async => _plans);

      final states = <PlansLoadState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadPlans();

      expect(states, [PlansLoadState.loading, PlansLoadState.loaded]);
      expect(provider.plans.length, 1);
      expect(provider.plans[0].name, 'Basic');
      expect(provider.errorMessage, isNull);
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

      await provider.loadPlans();

      expect(provider.state, PlansLoadState.error);
      expect(provider.errorMessage, 'Token expired');
    });

    test('transitions to error on generic exception', () async {
      when(
        () => planRepo.fetchActivePlans(),
      ).thenThrow(Exception('Network failure'));

      await provider.loadPlans();

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
}
