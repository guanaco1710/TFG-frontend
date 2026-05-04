// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:tfg_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:tfg_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:tfg_frontend/features/auth/presentation/screens/signup_screen.dart';
import 'package:tfg_frontend/features/gyms/data/repositories/gym_repository.dart';
import 'package:tfg_frontend/features/gyms/presentation/providers/gym_list_provider.dart';
import 'package:tfg_frontend/features/gyms/presentation/screens/gym_list_screen.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/screens/my_subscription_screen.dart';

const _baseUrl = 'http://localhost:8080/api/v1';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final authRepository = AuthRepository(
      httpClient: http.Client(),
      tokenStorage: tokenStorage,
      baseUrl: _baseUrl,
    );

    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<String>.value(value: _baseUrl),
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(repository: authRepository)..restoreSession(),
        ),
      ],
      child: MaterialApp(
        title: 'GymBook',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((p) => p.status);

    if (status == AuthStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (status == AuthStatus.authenticated) {
      return _HomeShell(onLogout: () => context.read<AuthProvider>().logout());
    }

    if (_showLogin) {
      return LoginScreen(onSignupTap: () => setState(() => _showLogin = false));
    }
    return SignupScreen(onLoginTap: () => setState(() => _showLogin = true));
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final tokenStorage = context.read<TokenStorage>();
    final baseUrl = context.read<String>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: onLogout),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset('assets/logo.png', width: 80, height: 80),
              ),
              const SizedBox(height: 64),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => SubscriptionProvider(
                        repository: SubscriptionRepository(
                          httpClient: http.Client(),
                          tokenStorage: tokenStorage,
                          baseUrl: baseUrl,
                        ),
                      ),
                      child: const MySubscriptionScreen(),
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                child: const Text('MI SUSCRIPCIÓN'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => GymListProvider(
                        repository: GymRepository(
                          httpClient: http.Client(),
                          tokenStorage: tokenStorage,
                          baseUrl: baseUrl,
                        ),
                      ),
                      child: const GymListScreen(),
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                child: const Text('GIMNASIOS'),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
