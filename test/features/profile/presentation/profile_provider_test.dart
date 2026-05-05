import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/profile/data/models/user_profile_models.dart';
import 'package:tfg_frontend/features/profile/data/repositories/user_repository.dart';
import 'package:tfg_frontend/features/profile/presentation/providers/profile_provider.dart';

class MockUserRepository extends Mock implements UserRepository {}

const _profile = UserProfile(
  id: 1,
  name: 'Alice Smith',
  email: 'alice@example.com',
  phone: '+34 911 000 001',
  role: 'CUSTOMER',
  active: true,
  createdAt: '2024-01-01T00:00:00Z',
  specialty: null,
);

void main() {
  late MockUserRepository repository;
  late ProfileProvider provider;

  setUp(() {
    repository = MockUserRepository();
    provider = ProfileProvider(repository: repository);
  });

  test('initial state is initial', () {
    expect(provider.state, ProfileLoadState.initial);
    expect(provider.profile, isNull);
    expect(provider.errorMessage, isNull);
  });

  group('loadProfile', () {
    test('transitions loading → loaded, sets profile', () async {
      when(() => repository.getMe()).thenAnswer((_) async => _profile);

      final states = <ProfileLoadState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadProfile();

      expect(states, [ProfileLoadState.loading, ProfileLoadState.loaded]);
      expect(provider.profile, _profile);
      expect(provider.errorMessage, isNull);
    });

    test('transitions loading → error on ApiException', () async {
      when(() => repository.getMe()).thenThrow(
        ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Token expired',
          path: '/users/me',
        ),
      );

      await provider.loadProfile();

      expect(provider.state, ProfileLoadState.error);
      expect(provider.errorMessage, 'Token expired');
      expect(provider.profile, isNull);
    });

    test('transitions loading → error on generic exception', () async {
      when(() => repository.getMe()).thenThrow(Exception('Network error'));

      await provider.loadProfile();

      expect(provider.state, ProfileLoadState.error);
      expect(provider.errorMessage, isNotNull);
    });

    test('clears previous error on retry', () async {
      when(() => repository.getMe()).thenThrow(
        ApiException(
          status: 500,
          error: 'Server Error',
          message: 'Internal error',
          path: '/users/me',
        ),
      );
      await provider.loadProfile();
      expect(provider.state, ProfileLoadState.error);

      when(() => repository.getMe()).thenAnswer((_) async => _profile);
      await provider.loadProfile();

      expect(provider.state, ProfileLoadState.loaded);
      expect(provider.errorMessage, isNull);
    });

    test('notifyListeners called on loading and on completion', () async {
      when(() => repository.getMe()).thenAnswer((_) async => _profile);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadProfile();

      expect(notifyCount, 2);
    });
  });
}
