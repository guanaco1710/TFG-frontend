import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart';

void main() {
  group('SubscriptionStatus', () {
    test('fromString maps ACTIVE', () {
      expect(
        SubscriptionStatus.fromString('ACTIVE'),
        SubscriptionStatus.active,
      );
    });

    test('fromString maps CANCELLED', () {
      expect(
        SubscriptionStatus.fromString('CANCELLED'),
        SubscriptionStatus.cancelled,
      );
    });

    test('fromString maps EXPIRED', () {
      expect(
        SubscriptionStatus.fromString('EXPIRED'),
        SubscriptionStatus.expired,
      );
    });

    test('fromString throws on unknown value', () {
      expect(
        () => SubscriptionStatus.fromString('UNKNOWN'),
        throwsArgumentError,
      );
    });
  });

  group('SubscriptionPlan', () {
    test('fromJson parses all fields', () {
      final json = {'id': 2, 'name': 'Premium Monthly', 'priceMonthly': 49.99};
      final plan = SubscriptionPlan.fromJson(json);
      expect(plan.id, 2);
      expect(plan.name, 'Premium Monthly');
      expect(plan.priceMonthly, 49.99);
    });

    test('fromJson converts integer priceMonthly to double', () {
      final json = {'id': 1, 'name': 'Basic', 'priceMonthly': 20};
      final plan = SubscriptionPlan.fromJson(json);
      expect(plan.priceMonthly, isA<double>());
      expect(plan.priceMonthly, 20.0);
    });
  });

  group('SubscriptionGym', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 1,
        'name': 'GymBook Central',
        'address': 'Calle Mayor 1',
        'city': 'Madrid',
      };
      final gym = SubscriptionGym.fromJson(json);
      expect(gym.id, 1);
      expect(gym.name, 'GymBook Central');
      expect(gym.address, 'Calle Mayor 1');
      expect(gym.city, 'Madrid');
    });
  });

  group('Subscription', () {
    test('fromJson parses full subscription with all fields', () {
      final json = {
        'id': 7,
        'plan': {'id': 2, 'name': 'Premium Monthly', 'priceMonthly': 49.99},
        'gym': {
          'id': 1,
          'name': 'GymBook Central',
          'address': 'Calle Mayor 1',
          'city': 'Madrid',
        },
        'status': 'ACTIVE',
        'startDate': '2024-05-01',
        'renewalDate': '2024-06-01',
        'endDate': null,
        'classesUsedThisMonth': 5,
        'classesRemainingThisMonth': 7,
        'pendingCancellation': false,
        'cancelledAt': null,
        'pendingPlan': null,
      };
      final sub = Subscription.fromJson(json);
      expect(sub.id, 7);
      expect(sub.plan.name, 'Premium Monthly');
      expect(sub.gym.name, 'GymBook Central');
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.startDate, '2024-05-01');
      expect(sub.renewalDate, '2024-06-01');
      expect(sub.endDate, isNull);
      expect(sub.classesUsedThisMonth, 5);
      expect(sub.classesRemainingThisMonth, 7);
      expect(sub.pendingCancellation, false);
      expect(sub.cancelledAt, isNull);
      expect(sub.pendingPlan, isNull);
    });

    test('fromJson parses optional endDate and null classesRemaining', () {
      final json = {
        'id': 8,
        'plan': {'id': 1, 'name': 'Basic', 'priceMonthly': 19.99},
        'gym': {
          'id': 1,
          'name': 'GymBook Central',
          'address': 'Calle Mayor 1',
          'city': 'Madrid',
        },
        'status': 'CANCELLED',
        'startDate': '2024-03-01',
        'renewalDate': '2024-04-01',
        'endDate': '2024-04-15',
        'classesUsedThisMonth': 0,
        'classesRemainingThisMonth': null,
        'pendingCancellation': false,
        'cancelledAt': null,
        'pendingPlan': null,
      };
      final sub = Subscription.fromJson(json);
      expect(sub.endDate, '2024-04-15');
      expect(sub.classesRemainingThisMonth, isNull);
      expect(sub.status, SubscriptionStatus.cancelled);
    });

    test('fromJson parses pendingPlan when present', () {
      final json = {
        'id': 7,
        'plan': {'id': 1, 'name': 'Basic', 'priceMonthly': 19.99},
        'gym': {
          'id': 1,
          'name': 'GymBook Central',
          'address': 'Calle Mayor 1',
          'city': 'Madrid',
        },
        'status': 'ACTIVE',
        'startDate': '2024-05-01',
        'renewalDate': '2024-06-01',
        'endDate': null,
        'classesUsedThisMonth': 5,
        'classesRemainingThisMonth': 3,
        'pendingCancellation': false,
        'cancelledAt': null,
        'pendingPlan': {'id': 3, 'name': 'Premium', 'priceMonthly': 49.99},
      };
      final sub = Subscription.fromJson(json);
      expect(sub.pendingPlan, isNotNull);
      expect(sub.pendingPlan!.id, 3);
      expect(sub.pendingPlan!.name, 'Premium');
    });

    test('fromJson parses pendingCancellation true and cancelledAt', () {
      final json = {
        'id': 7,
        'plan': {'id': 2, 'name': 'Premium', 'priceMonthly': 49.99},
        'gym': {
          'id': 1,
          'name': 'GymBook Central',
          'address': 'Calle Mayor 1',
          'city': 'Madrid',
        },
        'status': 'ACTIVE',
        'startDate': '2024-05-01',
        'renewalDate': '2024-06-01',
        'endDate': null,
        'classesUsedThisMonth': 5,
        'classesRemainingThisMonth': 7,
        'pendingCancellation': true,
        'cancelledAt': '2024-05-20T10:00:00Z',
        'pendingPlan': null,
      };
      final sub = Subscription.fromJson(json);
      expect(sub.pendingCancellation, true);
      expect(sub.cancelledAt, '2024-05-20T10:00:00Z');
    });

    test('fromJson defaults pendingCancellation to false when absent', () {
      final json = {
        'id': 7,
        'plan': {'id': 2, 'name': 'Premium', 'priceMonthly': 49.99},
        'gym': {
          'id': 1,
          'name': 'GymBook Central',
          'address': 'Calle Mayor 1',
          'city': 'Madrid',
        },
        'status': 'ACTIVE',
        'startDate': '2024-05-01',
        'renewalDate': '2024-06-01',
        'endDate': null,
        'classesUsedThisMonth': 5,
        'classesRemainingThisMonth': 7,
      };
      final sub = Subscription.fromJson(json);
      expect(sub.pendingCancellation, false);
      expect(sub.pendingPlan, isNull);
    });
  });
}
