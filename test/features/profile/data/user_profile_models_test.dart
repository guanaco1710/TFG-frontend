import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/features/profile/data/models/user_profile_models.dart';

void main() {
  const fullProfile = UserProfile(
    id: 1,
    name: 'Alice Smith',
    email: 'alice@example.com',
    phone: '+34 911 000 001',
    role: 'CUSTOMER',
    active: true,
    createdAt: '2024-01-01T00:00:00Z',
    specialty: null,
  );

  final fullJson = {
    'id': 1,
    'name': 'Alice Smith',
    'email': 'alice@example.com',
    'phone': '+34 911 000 001',
    'role': 'CUSTOMER',
    'active': true,
    'createdAt': '2024-01-01T00:00:00Z',
    'specialty': null,
  };

  group('UserProfile.fromJson', () {
    test('parses full profile', () {
      final profile = UserProfile.fromJson(fullJson);
      expect(profile.id, 1);
      expect(profile.name, 'Alice Smith');
      expect(profile.email, 'alice@example.com');
      expect(profile.phone, '+34 911 000 001');
      expect(profile.role, 'CUSTOMER');
      expect(profile.active, isTrue);
      expect(profile.specialty, isNull);
    });

    test('parses instructor with specialty', () {
      final json = {...fullJson, 'role': 'INSTRUCTOR', 'specialty': 'Cycling'};
      final profile = UserProfile.fromJson(json);
      expect(profile.role, 'INSTRUCTOR');
      expect(profile.specialty, 'Cycling');
    });

    test('parses null phone', () {
      final json = {...fullJson, 'phone': null};
      expect(UserProfile.fromJson(json).phone, isNull);
    });
  });

  group('UserProfile.toJson', () {
    test('round-trips correctly', () {
      final json = fullProfile.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Alice Smith');
      expect(json['role'], 'CUSTOMER');
      expect(json['specialty'], isNull);
    });
  });

  group('UserProfile equality', () {
    test('equal for same data', () {
      const other = UserProfile(
        id: 1,
        name: 'Alice Smith',
        email: 'alice@example.com',
        phone: '+34 911 000 001',
        role: 'CUSTOMER',
        active: true,
        createdAt: '2024-01-01T00:00:00Z',
        specialty: null,
      );
      expect(fullProfile, equals(other));
      expect(fullProfile.hashCode, equals(other.hashCode));
    });

    test('not equal for different id', () {
      const other = UserProfile(
        id: 2,
        name: 'Alice Smith',
        email: 'alice@example.com',
        phone: null,
        role: 'CUSTOMER',
        active: true,
        createdAt: '2024-01-01T00:00:00Z',
        specialty: null,
      );
      expect(fullProfile, isNot(equals(other)));
    });

    test('identical returns true', () {
      expect(fullProfile == fullProfile, isTrue);
    });
  });
}
