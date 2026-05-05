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

class _HomeShell extends StatefulWidget {
  const _HomeShell({required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;

  static const _titles = ['Inicio', 'Clases', 'Estadísticas', 'Perfil'];

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
          title: Text(_titles[_currentIndex]),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _HomeTab(tokenStorage: tokenStorage, baseUrl: baseUrl),
            const _ClassesTab(),
            const _StatsTab(),
            const _ProfileTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: 'Clases',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Estadísticas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.tokenStorage, required this.baseUrl});

  final TokenStorage tokenStorage;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

class _ClassesTab extends StatelessWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Clases disponibles',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Próximamente', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Mis estadísticas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Próximamente', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Mi perfil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Próximamente', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
