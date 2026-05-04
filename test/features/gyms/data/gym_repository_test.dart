import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/gyms/data/repositories/gym_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeUri extends Fake implements Uri {}

const _gymPageJson = {
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

void main() {
  late MockHttpClient httpClient;
  late MockTokenStorage tokenStorage;
  late GymRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    httpClient = MockHttpClient();
    tokenStorage = MockTokenStorage();
    repository = GymRepository(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    when(() => tokenStorage.getAccessToken()).thenAnswer((_) async => 'acc');
  });

  group('fetchGyms', () {
    test('returns GymPage on 200', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode(_gymPageJson),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.fetchGyms();

      expect(result.content.length, 1);
      expect(result.content[0].name, 'GymBook Central');
      expect(result.totalElements, 1);
    });

    test('throws ApiException on non-200 response', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2024-05-20T10:00:00Z',
            'status': 403,
            'error': 'Forbidden',
            'message': 'Access denied',
            'path': '/api/v1/gyms',
          }),
          403,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.fetchGyms(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
    });
  });
}
