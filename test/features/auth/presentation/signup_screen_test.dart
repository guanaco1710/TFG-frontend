import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:tfg_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:tfg_frontend/features/auth/presentation/screens/signup_screen.dart';

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

Widget _buildSubject(MockAuthRepository repo, {VoidCallback? onLoginTap}) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(repository: repo),
    child: MaterialApp(home: SignupScreen(onLoginTap: onLoginTap ?? () {})),
  );
}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  testWidgets('renders all fields and signup button', (tester) async {
    await tester.pumpWidget(_buildSubject(repo));

    expect(find.byKey(const Key('name_field')), findsOneWidget);
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('phone_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
    expect(find.byKey(const Key('confirm_password_field')), findsOneWidget);
    expect(find.byKey(const Key('signup_button')), findsOneWidget);
  });

  testWidgets('shows validation errors when required fields are empty', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject(repo));

    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });

  testWidgets('shows validation error for invalid email', (tester) async {
    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(find.byKey(const Key('name_field')), 'Alice');
    await tester.enterText(find.byKey(const Key('email_field')), 'notanemail');
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'securePass123!',
    );
    await tester.enterText(
      find.byKey(const Key('confirm_password_field')),
      'securePass123!',
    );
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets(
    'shows validation error when password is 12 characters or fewer',
    (tester) async {
      await tester.pumpWidget(_buildSubject(repo));

      await tester.enterText(find.byKey(const Key('name_field')), 'Alice');
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'alice@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'short123456',
      );
      await tester.tap(find.byKey(const Key('signup_button')));
      await tester.pump();

      expect(
        find.text('Password must be longer than 12 characters'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows validation error when passwords do not match', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(find.byKey(const Key('name_field')), 'Alice');
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'securePass123!',
    );
    await tester.enterText(
      find.byKey(const Key('confirm_password_field')),
      'different',
    );
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('shows loading indicator while registration is in progress', (
    tester,
  ) async {
    when(
      () => repo.register(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return _fakeAuthResponse();
    });

    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(find.byKey(const Key('name_field')), 'Alice Smith');
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'securePass123!',
    );
    await tester.enterText(
      find.byKey(const Key('confirm_password_field')),
      'securePass123!',
    );
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('shows success snackbar on successful registration', (
    tester,
  ) async {
    when(
      () => repo.register(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async => _fakeAuthResponse());

    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(find.byKey(const Key('name_field')), 'Alice Smith');
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'securePass123!',
    );
    await tester.enterText(
      find.byKey(const Key('confirm_password_field')),
      'securePass123!',
    );
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pumpAndSettle();

    expect(find.text('Account created successfully!'), findsOneWidget);
  });

  testWidgets('shows error snackbar on ApiException', (tester) async {
    when(
      () => repo.register(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        phone: any(named: 'phone'),
      ),
    ).thenThrow(
      const ApiException(
        status: 400,
        error: 'Bad Request',
        message: 'Email already registered',
        path: '/api/v1/auth/register',
      ),
    );

    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(find.byKey(const Key('name_field')), 'Alice Smith');
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'securePass123!',
    );
    await tester.enterText(
      find.byKey(const Key('confirm_password_field')),
      'securePass123!',
    );
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pumpAndSettle();

    expect(find.text('Email already registered'), findsOneWidget);
  });

  testWidgets('calls onLoginTap when login link is tapped', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _buildSubject(repo, onLoginTap: () => called = true),
    );

    await tester.tap(find.byKey(const Key('login_link')));
    await tester.pump();

    expect(called, isTrue);
  });

  testWidgets('register button calls repository with correct data', (
    tester,
  ) async {
    when(
      () => repo.register(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async => _fakeAuthResponse());

    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(find.byKey(const Key('name_field')), 'Alice Smith');
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('phone_field')),
      '+34600000000',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'securePass123!',
    );
    await tester.enterText(
      find.byKey(const Key('confirm_password_field')),
      'securePass123!',
    );
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pumpAndSettle();

    verify(
      () => repo.register(
        name: 'Alice Smith',
        email: 'alice@example.com',
        password: 'securePass123!',
        phone: '+34600000000',
      ),
    ).called(1);
  });

  testWidgets('submits without phone when phone field is empty', (
    tester,
  ) async {
    when(
      () => repo.register(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async => _fakeAuthResponse());

    await tester.pumpWidget(_buildSubject(repo));

    await tester.enterText(find.byKey(const Key('name_field')), 'Alice Smith');
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'securePass123!',
    );
    await tester.enterText(
      find.byKey(const Key('confirm_password_field')),
      'securePass123!',
    );
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pumpAndSettle();

    verify(
      () => repo.register(
        name: 'Alice Smith',
        email: 'alice@example.com',
        password: 'securePass123!',
        phone: null,
      ),
    ).called(1);
  });
}
