import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';

void main() {
  group('UserRole', () {
    test('fromString maps CUSTOMER', () {
      expect(UserRole.fromString('CUSTOMER'), UserRole.customer);
    });

    test('fromString maps INSTRUCTOR', () {
      expect(UserRole.fromString('INSTRUCTOR'), UserRole.instructor);
    });

    test('fromString maps ADMIN', () {
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
    });

    test('fromString throws on unknown value', () {
      expect(() => UserRole.fromString('UNKNOWN'), throwsArgumentError);
    });

    test('toJson returns correct string', () {
      expect(UserRole.customer.toJson(), 'CUSTOMER');
      expect(UserRole.instructor.toJson(), 'INSTRUCTOR');
      expect(UserRole.admin.toJson(), 'ADMIN');
    });
  });

  group('AuthUser', () {
    const validJson = {
      'id': 1,
      'name': 'Alice Smith',
      'email': 'alice@example.com',
      'role': 'CUSTOMER',
    };

    test('fromJson parses all fields correctly', () {
      final user = AuthUser.fromJson(validJson);
      expect(user.id, 1);
      expect(user.name, 'Alice Smith');
      expect(user.email, 'alice@example.com');
      expect(user.role, UserRole.customer);
    });

    test('fromJson parses INSTRUCTOR role', () {
      final user = AuthUser.fromJson({...validJson, 'role': 'INSTRUCTOR'});
      expect(user.role, UserRole.instructor);
    });

    test('fromJson parses ADMIN role', () {
      final user = AuthUser.fromJson({...validJson, 'role': 'ADMIN'});
      expect(user.role, UserRole.admin);
    });

    test('toJson round-trips correctly', () {
      final user = AuthUser.fromJson(validJson);
      final json = user.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Alice Smith');
      expect(json['email'], 'alice@example.com');
      expect(json['role'], 'CUSTOMER');
    });

    test('equality holds for same data', () {
      final a = AuthUser.fromJson(validJson);
      final b = AuthUser.fromJson(validJson);
      expect(a, equals(b));
    });

    test('inequality when id differs', () {
      final a = AuthUser.fromJson(validJson);
      final b = AuthUser.fromJson({...validJson, 'id': 2});
      expect(a, isNot(equals(b)));
    });

    test('can be used as a map key (exercises hashCode)', () {
      final user = AuthUser.fromJson(validJson);
      final map = {user: 'value'};
      expect(map[AuthUser.fromJson(validJson)], 'value');
    });
  });

  group('AuthTokens', () {
    const validJson = {
      'accessToken': 'access.token.here',
      'refreshToken': 'refresh.token.here',
      'expiresInSeconds': 900,
    };

    test('fromJson parses all fields', () {
      final tokens = AuthTokens.fromJson(validJson);
      expect(tokens.accessToken, 'access.token.here');
      expect(tokens.refreshToken, 'refresh.token.here');
      expect(tokens.expiresInSeconds, 900);
    });

    test('toJson round-trips correctly', () {
      final tokens = AuthTokens.fromJson(validJson);
      final json = tokens.toJson();
      expect(json['accessToken'], 'access.token.here');
      expect(json['refreshToken'], 'refresh.token.here');
      expect(json['expiresInSeconds'], 900);
    });

    test('equality holds for same data', () {
      final a = AuthTokens.fromJson(validJson);
      final b = AuthTokens.fromJson(validJson);
      expect(a, equals(b));
    });

    test('can be used as a map key (exercises hashCode)', () {
      final tokens = AuthTokens.fromJson(validJson);
      final map = {tokens: 'value'};
      expect(map[AuthTokens.fromJson(validJson)], 'value');
    });
  });

  group('AuthResponse', () {
    final validJson = {
      'tokens': {
        'accessToken': 'access.token.here',
        'refreshToken': 'refresh.token.here',
        'expiresInSeconds': 900,
      },
      'user': {
        'id': 1,
        'name': 'Alice Smith',
        'email': 'alice@example.com',
        'role': 'CUSTOMER',
      },
    };

    test('fromJson parses full envelope', () {
      final response = AuthResponse.fromJson(validJson);
      expect(response.tokens.accessToken, 'access.token.here');
      expect(response.tokens.refreshToken, 'refresh.token.here');
      expect(response.tokens.expiresInSeconds, 900);
      expect(response.user.id, 1);
      expect(response.user.name, 'Alice Smith');
      expect(response.user.email, 'alice@example.com');
      expect(response.user.role, UserRole.customer);
    });

    test('fromJson handles JSON string input via jsonDecode', () {
      final jsonString = jsonEncode(validJson);
      final response = AuthResponse.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
      expect(response.user.email, 'alice@example.com');
    });

    test('toJson round-trips correctly', () {
      final response = AuthResponse.fromJson(validJson);
      final json = response.toJson();
      expect(json['tokens']['accessToken'], 'access.token.here');
      expect(json['user']['name'], 'Alice Smith');
    });
  });

  group('ApiException', () {
    test('fromJson parses error envelope', () {
      final json = {
        'timestamp': '2024-05-20T10:00:00Z',
        'status': 401,
        'error': 'Unauthorized',
        'message': 'Invalid credentials',
        'path': '/api/v1/auth/login',
      };
      final ex = ApiException.fromJson(json, 401);
      expect(ex.status, 401);
      expect(ex.error, 'Unauthorized');
      expect(ex.message, 'Invalid credentials');
      expect(ex.path, '/api/v1/auth/login');
    });

    test('toString includes status and message', () {
      final ex = ApiException(
        status: 401,
        error: 'Unauthorized',
        message: 'Invalid credentials',
        path: '/api/v1/auth/login',
      );
      expect(ex.toString(), contains('401'));
      expect(ex.toString(), contains('Invalid credentials'));
    });
  });
}
