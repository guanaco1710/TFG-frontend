import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:tfg_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:tfg_frontend/features/auth/presentation/screens/login_screen.dart';

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

Widget _buildSubject(MockAuthRepository repo, {VoidCallback? onSignupTap}) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(repository: repo),
    child: MaterialApp(home: LoginScreen(onSignupTap: onSignupTap ?? () {})),
  );
}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  testWidgets('renders email and password fields and login button', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject(repo));

    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_button')), findsOneWidget);
  });

  testWidgets('shows validation error when fields are empty', (tester) async {
    await tester.pumpWidget(_buildSubject(repo));

    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
  });

  testWidgets('shows validation error for invalid email format', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(find.byKey(const Key('email_field')), 'notanemail');
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(find.text('Introduce un correo electrónico válido'), findsOneWidget);
  });

  testWidgets('shows loading indicator while login is in progress', (
    tester,
  ) async {
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return _fakeAuthResponse();
    });

    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('shows success snackbar on successful login', (tester) async {
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _fakeAuthResponse());

    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.text('¡Inicio de sesión correcto!'), findsOneWidget);
  });

  testWidgets('shows error snackbar on ApiException', (tester) async {
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

    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'wrongpass',
    );
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('calls onSignupTap when signup link is tapped', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _buildSubject(repo, onSignupTap: () => called = true),
    );

    await tester.tap(find.byKey(const Key('signup_link')));
    await tester.pump();

    expect(called, isTrue);
  });

  testWidgets('login button calls repository with correct credentials', (
    tester,
  ) async {
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _fakeAuthResponse());

    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    verify(
      () => repo.login(email: 'alice@example.com', password: 'password123'),
    ).called(1);
  });
}
