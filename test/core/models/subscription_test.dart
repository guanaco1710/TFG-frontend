import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/core/models/subscription.dart';

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
    test('fromJson parses full subscription', () {
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
      expect(sub.classesUsedThisMonth, 5);
      expect(sub.pendingCancellation, false);
    });
  });
}
