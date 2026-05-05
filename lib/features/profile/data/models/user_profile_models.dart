class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.active,
    required this.createdAt,
    this.specialty,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool active;
  final String createdAt;
  final String? specialty;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      active: json['active'] as bool,
      createdAt: json['createdAt'] as String,
      specialty: json['specialty'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'active': active,
    'createdAt': createdAt,
    'specialty': specialty,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.role == role &&
        other.active == active &&
        other.createdAt == createdAt &&
        other.specialty == specialty;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, email, phone, role, active, createdAt, specialty);
}
