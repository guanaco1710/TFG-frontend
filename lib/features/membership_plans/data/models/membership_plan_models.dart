class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceMonthly,
    this.classesPerMonth,
    required this.allowsWaitlist,
    required this.active,
  });

  final int id;
  final String name;
  final String description;
  final double priceMonthly;
  final int? classesPerMonth; // null = unlimited
  final bool allowsWaitlist;
  final bool active;

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      priceMonthly: (json['priceMonthly'] as num).toDouble(),
      classesPerMonth: json['classesPerMonth'] as int?,
      allowsWaitlist: json['allowsWaitlist'] as bool,
      active: json['active'] as bool,
    );
  }
}
