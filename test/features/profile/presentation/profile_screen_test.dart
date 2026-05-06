import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/profile/data/models/user_profile_models.dart';
import 'package:tfg_frontend/features/profile/data/repositories/user_repository.dart';
import 'package:tfg_frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:tfg_frontend/features/profile/presentation/screens/profile_screen.dart';

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

const _instructor = UserProfile(
  id: 2,
  name: 'Jane Doe',
  email: 'jane@example.com',
  phone: null,
  role: 'INSTRUCTOR',
  active: true,
  createdAt: '2024-01-01T00:00:00Z',
  specialty: 'Cycling',
);

Widget _wrap(ProfileProvider provider) => ChangeNotifierProvider.value(
  value: provider,
  child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
);

void main() {
  late MockUserRepository repository;

  setUp(() {
    repository = MockUserRepository();
  });

  testWidgets('shows loading indicator on initial/loading state', (
    tester,
  ) async {
    when(
      () => repository.getMe(),
    ).thenAnswer((_) => Completer<UserProfile>().future);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byKey(const Key('profile_loading')), findsOneWidget);
  });

  testWidgets('shows profile content when loaded', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _profile);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_avatar')), findsOneWidget);
    expect(find.byKey(const Key('profile_role_badge')), findsOneWidget);
    expect(find.byKey(const Key('profile_email')), findsOneWidget);
    expect(find.byKey(const Key('profile_name')), findsOneWidget);
    expect(find.byKey(const Key('profile_phone')), findsOneWidget);
    expect(find.byKey(const Key('edit_save_button')), findsNothing);
    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('alice@example.com'), findsOneWidget);
    expect(find.text('+34 911 000 001'), findsOneWidget);
  });

  testWidgets('shows CLIENTE role badge for CUSTOMER', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _profile);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('CLIENTE'), findsOneWidget);
  });

  testWidgets('shows specialty display row for instructor', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _instructor);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_specialty')), findsOneWidget);
    expect(find.text('Cycling'), findsOneWidget);
    expect(find.text('INSTRUCTOR'), findsOneWidget);
  });

  testWidgets('phone shows placeholder text when phone is null', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _instructor);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_phone')), findsOneWidget);
    expect(find.text('no hay teléfono agregado'), findsOneWidget);
  });

  testWidgets('customer does not see specialty row', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _profile);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_specialty')), findsNothing);
  });

  testWidgets('shows error state with retry button on failure', (tester) async {
    when(() => repository.getMe()).thenThrow(
      ApiException(
        status: 500,
        error: 'Server Error',
        message: 'Internal server error',
        path: '/users/me',
      ),
    );
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_error')), findsOneWidget);
    expect(find.byKey(const Key('profile_retry_button')), findsOneWidget);
    expect(find.text('Internal server error'), findsOneWidget);
  });

  testWidgets('retry button calls loadProfile again', (tester) async {
    when(() => repository.getMe()).thenThrow(
      ApiException(
        status: 500,
        error: 'Server Error',
        message: 'Internal server error',
        path: '/users/me',
      ),
    );
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    when(() => repository.getMe()).thenAnswer((_) async => _profile);

    await tester.tap(find.byKey(const Key('profile_retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_name')), findsOneWidget);
  });

  testWidgets('avatar shows initials from name', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _profile);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('AS'), findsOneWidget);
  });

  testWidgets('name shows current value in display row', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _profile);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_name')), findsOneWidget);
    expect(find.text('Alice Smith'), findsOneWidget);
  });

  testWidgets('tapping name pencil shows text field pre-filled', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _profile);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_name_pencil')));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('edit_name_field')),
    );
    expect(nameField.controller?.text, 'Alice Smith');
  });

  testWidgets('tapping specialty pencil shows specialty field', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _instructor);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_specialty_pencil')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_specialty_field')), findsOneWidget);
  });

  testWidgets('save calls updateProfile on success', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _profile);
    final updated = const UserProfile(
      id: 1,
      name: 'Alice Updated',
      email: 'alice@example.com',
      phone: '+34 911 000 001',
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

    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_name_pencil')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('edit_name_field')),
      'Alice Updated',
    );
    await tester.tap(find.byKey(const Key('edit_save_button')));
    await tester.pumpAndSettle();

    verify(
      () => repository.updateMe(
        name: 'Alice Updated',
        phone: any(named: 'phone'),
        specialty: any(named: 'specialty'),
      ),
    ).called(1);
    expect(find.byKey(const Key('edit_name_field')), findsNothing);
    expect(find.byKey(const Key('profile_name')), findsOneWidget);
  });

  testWidgets('save shows snackbar on error', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _profile);
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
        message: 'Nombre inválido',
        path: '/users/me',
      ),
    );

    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_name_pencil')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Nombre inválido'), findsOneWidget);
  });

  testWidgets('cancel resets fields and hides buttons', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _profile);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_name_pencil')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('edit_name_field')), 'Changed');
    await tester.tap(find.byKey(const Key('edit_cancel_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_save_button')), findsNothing);
    expect(find.byKey(const Key('edit_name_field')), findsNothing);
    expect(find.text('Alice Smith'), findsOneWidget);
  });

  testWidgets('validation rejects empty name', (tester) async {
    when(() => repository.getMe()).thenAnswer((_) async => _profile);
    final provider = ProfileProvider(repository: repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_name_pencil')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('edit_name_field')), '');
    await tester.tap(find.byKey(const Key('edit_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Nombre requerido'), findsOneWidget);
    verifyNever(
      () => repository.updateMe(
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        specialty: any(named: 'specialty'),
      ),
    );
  });
}
