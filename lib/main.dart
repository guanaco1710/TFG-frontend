import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:tfg_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:tfg_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:tfg_frontend/features/auth/presentation/screens/signup_screen.dart';

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
      baseUrl: 'http://localhost:8080/api/v1',
    );

    return ChangeNotifierProvider(
      create: (_) => AuthProvider(repository: authRepository)..restoreSession(),
      child: MaterialApp(
        title: 'TFG App',
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
      final user = context.read<AuthProvider>().currentUser!;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthProvider>().logout();
              },
            ),
          ],
        ),
        body: Center(child: Text('Welcome, ${user.name}!')),
      );
    }

    if (_showLogin) {
      return LoginScreen(onSignupTap: () => setState(() => _showLogin = false));
    }
    return SignupScreen(onLoginTap: () => setState(() => _showLogin = true));
  }
}
