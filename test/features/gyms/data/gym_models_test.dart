import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/features/gyms/data/models/gym_models.dart';

void main() {
  group('Gym', () {
    test('fromJson parses all fields including optional', () {
      final json = {
        'id': 1,
        'name': 'GymBook Central',
        'address': 'Calle Mayor 1',
        'city': 'Madrid',
        'phone': '+34 91 000 0000',
        'openingHours': 'Mon–Fri 07:00–22:00',
        'active': true,
      };
      final gym = Gym.fromJson(json);
      expect(gym.id, 1);
      expect(gym.name, 'GymBook Central');
      expect(gym.address, 'Calle Mayor 1');
      expect(gym.city, 'Madrid');
      expect(gym.phone, '+34 91 000 0000');
      expect(gym.openingHours, 'Mon–Fri 07:00–22:00');
      expect(gym.active, true);
    });

    test('fromJson parses nullable fields as null', () {
      final json = {
        'id': 2,
        'name': 'FitLife North',
        'address': 'Av. Norte 22',
        'city': 'Barcelona',
        'phone': null,
        'openingHours': null,
        'active': false,
      };
      final gym = Gym.fromJson(json);
      expect(gym.phone, isNull);
      expect(gym.openingHours, isNull);
      expect(gym.active, false);
    });
  });

  group('GymPage', () {
    test('fromJson parses page with content list', () {
      final json = {
        'content': [
          {
            'id': 1,
            'name': 'GymBook Central',
            'address': 'Calle Mayor 1',
            'city': 'Madrid',
            'phone': null,
            'openingHours': null,
            'active': true,
          },
        ],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
        'hasMore': false,
      };
      final page = GymPage.fromJson(json);
      expect(page.content.length, 1);
      expect(page.content[0].name, 'GymBook Central');
      expect(page.page, 0);
      expect(page.size, 20);
      expect(page.totalElements, 1);
      expect(page.totalPages, 1);
      expect(page.hasMore, false);
    });
  });
}
