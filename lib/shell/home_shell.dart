import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';
import 'package:tfg_frontend/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/class_session_provider.dart';
import 'package:tfg_frontend/features/classes/presentation/screens/classes_screen.dart';
import 'package:tfg_frontend/features/gyms/data/repositories/gym_repository.dart';
import 'package:tfg_frontend/features/gyms/presentation/providers/gym_list_provider.dart';
import 'package:tfg_frontend/features/gyms/presentation/screens/gym_list_screen.dart';
import 'package:tfg_frontend/features/membership_plans/data/repositories/membership_plan_repository.dart';
import 'package:tfg_frontend/features/membership_plans/presentation/providers/gym_plans_provider.dart';
import 'package:tfg_frontend/features/membership_plans/presentation/screens/gym_plans_screen.dart';
import 'package:tfg_frontend/features/profile/data/repositories/user_repository.dart';
import 'package:tfg_frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:tfg_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:tfg_frontend/features/stats/data/repositories/stats_repository.dart';
import 'package:tfg_frontend/features/stats/presentation/providers/stats_provider.dart';
import 'package:tfg_frontend/features/stats/presentation/screens/stats_screen.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/screens/my_subscription_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => HomeShellState();
}

@visibleForTesting
class HomeShellState extends State<HomeShell> {
  int currentIndex = 0;
  final _classesKey = GlobalKey<ClassesScreenState>();

  static const titles = ['Inicio', 'Clases', 'Estadísticas', 'Perfil'];

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
          title: Text(titles[currentIndex]),
          actions: [
            IconButton(
              key: const Key('logout_button'),
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
            ),
          ],
        ),
        body: IndexedStack(
          index: currentIndex,
          children: [
            HomeTab(tokenStorage: tokenStorage, baseUrl: baseUrl),
            MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => ClassSessionProvider(
                    repository: ClassSessionRepository(
                      httpClient: http.Client(),
                      tokenStorage: tokenStorage,
                      baseUrl: baseUrl,
                    ),
                  ),
                ),
                ChangeNotifierProvider(
                  create: (_) => BookingProvider(
                    repository: BookingRepository(
                      httpClient: http.Client(),
                      tokenStorage: tokenStorage,
                      baseUrl: baseUrl,
                    ),
                  ),
                ),
                ChangeNotifierProvider(
                  create: (_) => SubscriptionProvider(
                    repository: SubscriptionRepository(
                      httpClient: http.Client(),
                      tokenStorage: tokenStorage,
                      baseUrl: baseUrl,
                    ),
                  ),
                ),
              ],
              child: ClassesScreen(key: _classesKey),
            ),
            ChangeNotifierProvider(
              create: (_) => StatsProvider(
                repository: StatsRepository(
                  httpClient: http.Client(),
                  tokenStorage: tokenStorage,
                  baseUrl: baseUrl,
                ),
              ),
              child: const StatsScreen(),
            ),
            ChangeNotifierProvider(
              create: (_) => ProfileProvider(
                repository: UserRepository(
                  httpClient: http.Client(),
                  tokenStorage: tokenStorage,
                  baseUrl: baseUrl,
                ),
              ),
              child: const ProfileScreen(),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) {
          setState(() => currentIndex = i);
          if (i == 1) _classesKey.currentState?.refresh();
        },
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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.tokenStorage, required this.baseUrl});

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
              child: Image.asset(
                'assets/logo.png',
                key: const Key('home_logo'),
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 64),
            FilledButton(
              key: const Key('subscription_button'),
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
                    child: MySubscriptionScreen(
                      gymListScreenBuilder: () => ChangeNotifierProvider(
                        create: (_) => GymListProvider(
                          repository: GymRepository(
                            httpClient: http.Client(),
                            tokenStorage: tokenStorage,
                            baseUrl: baseUrl,
                          ),
                        ),
                        child: GymListScreen(
                          gymPlansProviderBuilder: (gym) =>
                              ChangeNotifierProvider(
                            create: (_) => GymPlansProvider(
                              planRepository: MembershipPlanRepository(
                                httpClient: http.Client(),
                                tokenStorage: tokenStorage,
                                baseUrl: baseUrl,
                              ),
                              subscriptionRepository: SubscriptionRepository(
                                httpClient: http.Client(),
                                tokenStorage: tokenStorage,
                                baseUrl: baseUrl,
                              ),
                            ),
                            child: GymPlansScreen(gym: gym),
                          ),
                        ),
                      ),
                    ),
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
              key: const Key('gyms_button'),
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
                    child: GymListScreen(
                      gymPlansProviderBuilder: (gym) => ChangeNotifierProvider(
                        create: (_) => GymPlansProvider(
                          planRepository: MembershipPlanRepository(
                            httpClient: http.Client(),
                            tokenStorage: tokenStorage,
                            baseUrl: baseUrl,
                          ),
                          subscriptionRepository: SubscriptionRepository(
                            httpClient: http.Client(),
                            tokenStorage: tokenStorage,
                            baseUrl: baseUrl,
                          ),
                        ),
                        child: GymPlansScreen(gym: gym),
                      ),
                    ),
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
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('my_bookings_button'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => BookingProvider(
                      repository: BookingRepository(
                        httpClient: http.Client(),
                        tokenStorage: tokenStorage,
                        baseUrl: baseUrl,
                      ),
                    ),
                    child: const MyBookingsScreen(),
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
              child: const Text('MIS RESERVAS'),
            ),
          ],
        ),
      ),
    );
  }
}
