import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/profile/data/repositories/user_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeUri extends Fake implements Uri {}

http.Response _jsonOk(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _jsonError(int status, String error, String message) =>
    http.Response(
      jsonEncode({
        'timestamp': '2024-05-20T10:00:00Z',
        'status': status,
        'error': error,
        'message': message,
        'path': '/api/v1/users/me',
      }),
      status,
      headers: {'content-type': 'application/json'},
    );

const _profileJson = {
  'id': 1,
  'name': 'Alice Smith',
  'email': 'alice@example.com',
  'phone': '+34 911 000 001',
  'role': 'CUSTOMER',
  'active': true,
  'createdAt': '2024-01-01T00:00:00Z',
  'specialty': null,
};

void main() {
  late MockHttpClient httpClient;
  late MockTokenStorage tokenStorage;
  late UserRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    httpClient = MockHttpClient();
    tokenStorage = MockTokenStorage();
    repository = UserRepository(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    when(
      () => tokenStorage.getAccessToken(),
    ).thenAnswer((_) async => 'access-token');
  });

  group('getMe', () {
    test('returns UserProfile on 200', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_profileJson));

      final profile = await repository.getMe();

      expect(profile.id, 1);
      expect(profile.name, 'Alice Smith');
      expect(profile.email, 'alice@example.com');
      expect(profile.role, 'CUSTOMER');
    });

    test('sends Authorization header', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_profileJson));

      await repository.getMe();

      final captured = verify(
        () => httpClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      final headers = captured.first as Map<String, String>;
      expect(headers['Authorization'], 'Bearer access-token');
    });

    test('hits /users/me endpoint', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_profileJson));

      await repository.getMe();

      final captured = verify(
        () => httpClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      expect(
        (captured.first as Uri).toString(),
        'http://localhost:8080/api/v1/users/me',
      );
    });

    test('throws ApiException on 401', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => _jsonError(401, 'Unauthorized', 'Token expired'),
      );

      expect(
        () => repository.getMe(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });

    test('throws ApiException on 403', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonError(403, 'Forbidden', 'Access denied'));

      expect(
        () => repository.getMe(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
    });

    test('omits Authorization when no token', () async {
      when(() => tokenStorage.getAccessToken()).thenAnswer((_) async => null);
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_profileJson));

      await repository.getMe();

      final captured = verify(
        () => httpClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      final headers = captured.first as Map<String, String>;
      expect(headers.containsKey('Authorization'), isFalse);
    });
  });

  group('updateMe', () {
    test('returns updated UserProfile on 200', () async {
      final updated = {..._profileJson, 'name': 'Alice Updated'};
      when(
        () => httpClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _jsonOk(updated));

      final profile = await repository.updateMe(name: 'Alice Updated');

      expect(profile.name, 'Alice Updated');
    });

    test('sends only provided fields', () async {
      when(
        () => httpClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _jsonOk(_profileJson));

      await repository.updateMe(phone: '+34 600 000 000');

      final captured = verify(
        () => httpClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      final body = jsonDecode(captured.first as String) as Map<String, dynamic>;
      expect(body.containsKey('phone'), isTrue);
      expect(body['phone'], '+34 600 000 000');
      expect(body.containsKey('name'), isFalse);
      expect(body.containsKey('specialty'), isFalse);
    });

    test('throws ApiException on 400', () async {
      when(
        () => httpClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => _jsonError(400, 'Bad Request', 'Invalid phone format'),
      );

      expect(
        () => repository.updateMe(phone: 'invalid'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
      );
    });
  });
}
