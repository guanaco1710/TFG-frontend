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

  group('updateProfile', () {
    setUp(() {
      when(() => repository.getMe()).thenAnswer((_) async => _profile);
    });

    test('returns true and updates profile on success', () async {
      final updated = const UserProfile(
        id: 1,
        name: 'Alice Updated',
        email: 'alice@example.com',
        phone: '+34 600 000 000',
        role: 'CUSTOMER',
        active: true,
        createdAt: '2024-01-01T00:00:00Z',
        specialty: null,
      );
      when(
        () => repository.updateMe(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          specialty: any(named: 'specialty'),
        ),
      ).thenAnswer((_) async => updated);

      final result = await provider.updateProfile(
        name: 'Alice Updated',
        phone: '+34 600 000 000',
      );

      expect(result, isTrue);
      expect(provider.profile?.name, 'Alice Updated');
      expect(provider.saveError, isNull);
      expect(provider.isSaving, isFalse);
    });

    test('sets isSaving during call', () async {
      when(
        () => repository.updateMe(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          specialty: any(named: 'specialty'),
        ),
      ).thenAnswer((_) async => _profile);

      final savingStates = <bool>[];
      provider.addListener(() => savingStates.add(provider.isSaving));

      await provider.updateProfile(name: 'Alice');

      expect(savingStates, containsAllInOrder([true, false]));
    });

    test('returns false and sets saveError on ApiException', () async {
      when(
        () => repository.updateMe(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          specialty: any(named: 'specialty'),
        ),
      ).thenThrow(
        const ApiException(
          status: 400,
          error: 'Bad Request',
          message: 'Formato de teléfono inválido',
          path: '/users/me',
        ),
      );

      final result = await provider.updateProfile(phone: 'bad');

      expect(result, isFalse);
      expect(provider.saveError, 'Formato de teléfono inválido');
      expect(provider.isSaving, isFalse);
    });

    test('returns false on generic exception', () async {
      when(
        () => repository.updateMe(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          specialty: any(named: 'specialty'),
        ),
      ).thenThrow(Exception('network'));

      final result = await provider.updateProfile(name: 'Alice');

      expect(result, isFalse);
      expect(provider.saveError, isNotNull);
    });
  });
}
