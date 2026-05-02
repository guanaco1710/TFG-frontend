import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:tfg_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:tfg_frontend/features/auth/presentation/screens/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('App shows login screen by default', (WidgetTester tester) async {
    final repo = MockAuthRepository();
    when(() => repo.restoreSession()).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(repository: repo)..restoreSession(),
        child: const MaterialApp(home: LoginScreen(onSignupTap: _noop)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_button')), findsOneWidget);
  });

  testWidgets('Authenticated state shows welcome message', (
    WidgetTester tester,
  ) async {
    final repo = MockAuthRepository();
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => AuthResponse(
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
      ),
    );

    final provider = AuthProvider(repository: repo);
    await provider.login(email: 'alice@example.com', password: 'password123');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final user = context.watch<AuthProvider>().currentUser;
              return Scaffold(body: Text('Welcome, ${user?.name}!'));
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Welcome, Alice Smith!'), findsOneWidget);
  });
}

void _noop() {}
