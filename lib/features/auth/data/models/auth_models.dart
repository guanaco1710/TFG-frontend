// Re-exported for backward compatibility — ApiException now lives in core.
export 'package:tfg_frontend/core/exceptions/api_exception.dart';

enum UserRole {
  customer,
  instructor,
  admin;

  static UserRole fromString(String value) {
    return switch (value) {
      'CUSTOMER' => UserRole.customer,
      'INSTRUCTOR' => UserRole.instructor,
      'ADMIN' => UserRole.admin,
      _ => throw ArgumentError('Unknown role: $value'),
    };
  }

  String toJson() {
    return switch (this) {
      UserRole.customer => 'CUSTOMER',
      UserRole.instructor => 'INSTRUCTOR',
      UserRole.admin => 'ADMIN',
    };
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role.toJson()};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, name, email, role);
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresInSeconds': expiresInSeconds,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthTokens &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.expiresInSeconds == expiresInSeconds;
  }

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, expiresInSeconds);
}

class AuthResponse {
  const AuthResponse({required this.tokens, required this.user});

  final AuthTokens tokens;
  final AuthUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'tokens': tokens.toJson(), 'user': user.toJson()};
  }
}
