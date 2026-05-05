import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/auth/data/repositories/auth_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeUri extends Fake implements Uri {}

const _authEnvelope = {
  'tokens': {
    'accessToken': 'acc',
    'refreshToken': 'ref',
    'expiresInSeconds': 900,
  },
  'user': {
    'id': 1,
    'name': 'Alice Smith',
    'email': 'alice@example.com',
    'role': 'CUSTOMER',
  },
};

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
        'path': '/api/v1/auth/login',
      }),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  late MockHttpClient httpClient;
  late MockTokenStorage tokenStorage;
  late AuthRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    httpClient = MockHttpClient();
    tokenStorage = MockTokenStorage();
    repository = AuthRepository(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: 'http://localhost:8080/api/v1',
    );
  });

  group('login', () {
    test('returns AuthResponse on 200', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _jsonOk(_authEnvelope));

      when(
        () => tokenStorage.saveTokens(any(), any()),
      ).thenAnswer((_) async {});

      final result = await repository.login(
        email: 'alice@example.com',
        password: 'password123',
      );

      expect(result.user.email, 'alice@example.com');
      expect(result.tokens.accessToken, 'acc');
      verify(() => tokenStorage.saveTokens('acc', 'ref')).called(1);
    });

    test(
      'throws ApiException with status 401 on invalid credentials',
      () async {
        when(
          () => httpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => _jsonError(401, 'Unauthorized', 'Invalid credentials'),
        );

        expect(
          () => repository.login(email: 'x@x.com', password: 'wrong'),
          throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
        );
      },
    );

    test('throws ApiException with status 400 on validation failure', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => _jsonError(400, 'Bad Request', 'Email must not be blank'),
      );

      expect(
        () => repository.login(email: '', password: ''),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
      );
    });
  });

  group('register', () {
    test('returns AuthResponse on 201', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _jsonOk(_authEnvelope, status: 201));

      when(
        () => tokenStorage.saveTokens(any(), any()),
      ).thenAnswer((_) async {});

      final result = await repository.register(
        name: 'Alice Smith',
        email: 'alice@example.com',
        password: 'password123',
      );

      expect(result.user.name, 'Alice Smith');
      verify(() => tokenStorage.saveTokens('acc', 'ref')).called(1);
    });

    test('throws ApiException on 400', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => _jsonError(
          400,
          'Bad Request',
          'Password must be at least 8 characters',
        ),
      );

      expect(
        () =>
            repository.register(name: 'A', email: 'a@a.com', password: 'short'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
      );
    });

    test('sends phone when provided', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _jsonOk(_authEnvelope, status: 201));
      when(
        () => tokenStorage.saveTokens(any(), any()),
      ).thenAnswer((_) async {});

      await repository.register(
        name: 'Alice',
        email: 'alice@example.com',
        password: 'password123',
        phone: '+1234567890',
      );

      final captured = verify(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;

      final body = jsonDecode(captured.first as String) as Map<String, dynamic>;
      expect(body['phone'], '+1234567890');
    });

    test('sends role when provided', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _jsonOk(_authEnvelope, status: 201));
      when(
        () => tokenStorage.saveTokens(any(), any()),
      ).thenAnswer((_) async {});

      await repository.register(
        name: 'Admin',
        email: 'admin@example.com',
        password: 'password123',
        role: UserRole.admin,
      );

      final captured = verify(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;

      final body = jsonDecode(captured.first as String) as Map<String, dynamic>;
      expect(body['role'], 'ADMIN');
    });
  });

  group('refresh', () {
    test('returns AuthResponse and saves new tokens on 200', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _jsonOk(_authEnvelope));
      when(
        () => tokenStorage.saveTokens(any(), any()),
      ).thenAnswer((_) async {});

      final result = await repository.refresh(
        refreshToken: 'old-refresh-token',
      );

      expect(result.tokens.refreshToken, 'ref');
      verify(() => tokenStorage.saveTokens('acc', 'ref')).called(1);
    });

    test('throws ApiException on 401 (consumed token)', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => _jsonError(401, 'Unauthorized', 'Token revoked'),
      );

      expect(
        () => repository.refresh(refreshToken: 'consumed'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });
  });

  group('logout', () {
    test('calls storage clear on 204', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('', 204));
      when(() => tokenStorage.clearTokens()).thenAnswer((_) async {});

      await repository.logout(refreshToken: 'ref');

      verify(() => tokenStorage.clearTokens()).called(1);
    });

    test('still clears storage even on non-204 (idempotent server)', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));
      when(() => tokenStorage.clearTokens()).thenAnswer((_) async {});

      await repository.logout(refreshToken: 'ref');

      verify(() => tokenStorage.clearTokens()).called(1);
    });
  });

  group('restoreSession', () {
    test('returns AuthUser when refresh token stored', () async {
      when(
        () => tokenStorage.getRefreshToken(),
      ).thenAnswer((_) async => 'ref');
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _jsonOk(_authEnvelope));
      when(
        () => tokenStorage.saveTokens(any(), any()),
      ).thenAnswer((_) async {});

      final user = await repository.restoreSession();

      expect(user, isNotNull);
      expect(user!.email, 'alice@example.com');
    });

    test('returns null when no refresh token stored', () async {
      when(() => tokenStorage.getRefreshToken()).thenAnswer((_) async => null);

      final user = await repository.restoreSession();

      expect(user, isNull);
    });

    test('saves new tokens after successful restore', () async {
      when(
        () => tokenStorage.getRefreshToken(),
      ).thenAnswer((_) async => 'old-ref');
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _jsonOk(_authEnvelope));
      when(
        () => tokenStorage.saveTokens(any(), any()),
      ).thenAnswer((_) async {});

      await repository.restoreSession();

      verify(() => tokenStorage.saveTokens('acc', 'ref')).called(1);
    });

    test('returns null and clears tokens when refresh fails', () async {
      when(
        () => tokenStorage.getRefreshToken(),
      ).thenAnswer((_) async => 'ref');
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => _jsonError(401, 'Unauthorized', 'Token revoked'),
      );
      when(() => tokenStorage.clearTokens()).thenAnswer((_) async {});

      final user = await repository.restoreSession();

      expect(user, isNull);
      verify(() => tokenStorage.clearTokens()).called(1);
    });
  });
}
