import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/features/membership_plans/data/models/membership_plan_models.dart';

void main() {
  group('MembershipPlan.fromJson', () {
    test('parses all fields correctly', () {
      final plan = MembershipPlan.fromJson({
        'id': 1,
        'name': 'Premium Monthly',
        'description': 'Access to all facilities',
        'priceMonthly': 49.99,
        'classesPerMonth': 12,
        'allowsWaitlist': true,
        'active': true,
      });

      expect(plan.id, 1);
      expect(plan.name, 'Premium Monthly');
      expect(plan.description, 'Access to all facilities');
      expect(plan.priceMonthly, 49.99);
      expect(plan.classesPerMonth, 12);
      expect(plan.allowsWaitlist, true);
      expect(plan.active, true);
    });

    test('parses null classesPerMonth as null', () {
      final plan = MembershipPlan.fromJson({
        'id': 2,
        'name': 'Unlimited',
        'description': 'No class limit',
        'priceMonthly': 79.99,
        'classesPerMonth': null,
        'allowsWaitlist': false,
        'active': true,
      });

      expect(plan.classesPerMonth, isNull);
    });

    test('coerces int priceMonthly to double', () {
      final plan = MembershipPlan.fromJson({
        'id': 3,
        'name': 'Basic',
        'description': 'Basic plan',
        'priceMonthly': 20,
        'classesPerMonth': 8,
        'allowsWaitlist': false,
        'active': true,
      });

      expect(plan.priceMonthly, 20.0);
      expect(plan.priceMonthly, isA<double>());
    });

    test('parses active=false and allowsWaitlist=false', () {
      final plan = MembershipPlan.fromJson({
        'id': 4,
        'name': 'Legacy',
        'description': 'Old plan',
        'priceMonthly': 15.0,
        'classesPerMonth': 5,
        'allowsWaitlist': false,
        'active': false,
      });

      expect(plan.active, false);
      expect(plan.allowsWaitlist, false);
    });
  });
}
