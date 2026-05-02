import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:tfg_frontend/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

AuthResponse _fakeAuthResponse() => AuthResponse(
  tokens: const AuthTokens(
    accessToken: 'acc',
    refreshToken: 'ref',
    expiresInSeconds: 900,
  ),
  user: const AuthUser(
    id: 1,
    name: 'Alice Smith',
    email: 'alice@example.com',
    role: UserRole.customer,
  ),
);

void main() {
  late MockAuthRepository repo;
  late AuthProvider provider;

  setUp(() {
    repo = MockAuthRepository();
    provider = AuthProvider(repository: repo);
  });

  group('initial state', () {
    test('is unauthenticated with no user', () {
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.currentUser, isNull);
      expect(provider.errorMessage, isNull);
    });
  });

  group('login', () {
    test('transitions to authenticated on success', () async {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _fakeAuthResponse());

      await provider.login(email: 'alice@example.com', password: 'password123');

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.currentUser?.email, 'alice@example.com');
      expect(provider.errorMessage, isNull);
    });

    test('transitions to loading then error on ApiException', () async {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Invalid credentials',
          path: '/api/v1/auth/login',
        ),
      );

      await provider.login(email: 'x@x.com', password: 'wrong');

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.errorMessage, 'Invalid credentials');
    });

    test('emits loading state during login', () async {
      final states = <AuthStatus>[];
      provider.addListener(() => states.add(provider.status));

      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return _fakeAuthResponse();
      });

      await provider.login(email: 'alice@example.com', password: 'password123');

      expect(
        states,
        containsAllInOrder([AuthStatus.loading, AuthStatus.authenticated]),
      );
    });
  });

  group('register', () {
    test('transitions to authenticated on success', () async {
      when(
        () => repo.register(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _fakeAuthResponse());

      await provider.register(
        name: 'Alice Smith',
        email: 'alice@example.com',
        password: 'password123',
      );

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.currentUser?.name, 'Alice Smith');
    });

    test('sets errorMessage on ApiException', () async {
      when(
        () => repo.register(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ApiException(
          status: 400,
          error: 'Bad Request',
          message: 'Email already registered',
          path: '/api/v1/auth/register',
        ),
      );

      await provider.register(
        name: 'Alice',
        email: 'alice@example.com',
        password: 'password123',
      );

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.errorMessage, 'Email already registered');
    });
  });

  group('logout', () {
    test('transitions to unauthenticated', () async {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _fakeAuthResponse());
      await provider.login(email: 'alice@example.com', password: 'pass');
      expect(provider.status, AuthStatus.authenticated);

      when(
        () => repo.logout(refreshToken: any(named: 'refreshToken')),
      ).thenAnswer((_) async {});

      await provider.logout(refreshToken: 'ref');

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.currentUser, isNull);
    });

    test('uses empty string when no refresh token available', () async {
      when(
        () => repo.logout(refreshToken: any(named: 'refreshToken')),
      ).thenAnswer((_) async {});

      await provider.logout();

      verify(() => repo.logout(refreshToken: '')).called(1);
      expect(provider.status, AuthStatus.unauthenticated);
    });
  });

  group('restoreSession', () {
    test('restores user when session valid', () async {
      when(() => repo.restoreSession()).thenAnswer(
        (_) async => const AuthUser(
          id: 1,
          name: 'Alice Smith',
          email: 'alice@example.com',
          role: UserRole.customer,
        ),
      );

      await provider.restoreSession();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.currentUser?.email, 'alice@example.com');
    });

    test('stays unauthenticated when no session', () async {
      when(() => repo.restoreSession()).thenAnswer((_) async => null);

      await provider.restoreSession();

      expect(provider.status, AuthStatus.unauthenticated);
    });
  });

  group('clearError', () {
    test('clears the error message', () async {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Invalid credentials',
          path: '/api/v1/auth/login',
        ),
      );
      await provider.login(email: 'x@x.com', password: 'wrong');
      expect(provider.errorMessage, isNotNull);

      provider.clearError();

      expect(provider.errorMessage, isNull);
    });
  });
}
