class Gym {
  const Gym({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.phone,
    this.openingHours,
    required this.active,
  });

  final int id;
  final String name;
  final String address;
  final String city;
  final String? phone;
  final String? openingHours;
  final bool active;

  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      phone: json['phone'] as String?,
      openingHours: json['openingHours'] as String?,
      active: json['active'] as bool,
    );
  }
}

class GymPage {
  const GymPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasMore,
  });

  final List<Gym> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasMore;

  factory GymPage.fromJson(Map<String, dynamic> json) {
    return GymPage(
      content: (json['content'] as List<dynamic>)
          .map((e) => Gym.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      size: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      hasMore: json['hasMore'] as bool,
    );
  }
}
