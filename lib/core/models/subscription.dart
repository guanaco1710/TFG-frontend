enum SubscriptionStatus {
  active,
  cancelled,
  expired;

  static SubscriptionStatus fromString(String value) {
    return switch (value) {
      'ACTIVE' => SubscriptionStatus.active,
      'CANCELLED' => SubscriptionStatus.cancelled,
      'EXPIRED' => SubscriptionStatus.expired,
      _ => throw ArgumentError('Unknown subscription status: $value'),
    };
  }
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceMonthly,
  });

  final int id;
  final String name;
  final double priceMonthly;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as int,
      name: json['name'] as String,
      priceMonthly: (json['priceMonthly'] as num).toDouble(),
    );
  }
}

class SubscriptionGym {
  const SubscriptionGym({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
  });

  final int id;
  final String name;
  final String address;
  final String city;

  factory SubscriptionGym.fromJson(Map<String, dynamic> json) {
    return SubscriptionGym(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
    );
  }
}

class Subscription {
  const Subscription({
    required this.id,
    required this.plan,
    required this.gym,
    required this.status,
    required this.startDate,
    required this.renewalDate,
    this.endDate,
    required this.classesUsedThisMonth,
    this.classesRemainingThisMonth,
    required this.pendingCancellation,
    this.cancelledAt,
    this.pendingPlan,
  });

  final int id;
  final SubscriptionPlan plan;
  final SubscriptionGym gym;
  final SubscriptionStatus status;
  final String startDate;
  final String renewalDate;
  final String? endDate;
  final int classesUsedThisMonth;
  final int? classesRemainingThisMonth;
  final bool pendingCancellation;
  final String? cancelledAt;
  final SubscriptionPlan? pendingPlan;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int,
      plan: SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>),
      gym: SubscriptionGym.fromJson(json['gym'] as Map<String, dynamic>),
      status: SubscriptionStatus.fromString(json['status'] as String),
      startDate: json['startDate'] as String,
      renewalDate: json['renewalDate'] as String,
      endDate: json['endDate'] as String?,
      classesUsedThisMonth: json['classesUsedThisMonth'] as int,
      classesRemainingThisMonth: json['classesRemainingThisMonth'] as int?,
      pendingCancellation: json['pendingCancellation'] as bool? ?? false,
      cancelledAt: json['cancelledAt'] as String?,
      pendingPlan: json['pendingPlan'] == null
          ? null
          : SubscriptionPlan.fromJson(
              json['pendingPlan'] as Map<String, dynamic>,
            ),
    );
  }
}
