import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';
import 'package:tfg_frontend/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:tfg_frontend/features/dashboard/presentation/providers/dashboard_provider.dart';
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
import 'package:tfg_frontend/features/ratings/data/repositories/rating_repository.dart';
import 'package:tfg_frontend/features/ratings/presentation/providers/rating_provider.dart';
import 'package:tfg_frontend/features/notifications/data/repositories/notification_repository.dart';
import 'package:tfg_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:tfg_frontend/features/notifications/presentation/screens/notifications_screen.dart';
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

  void _onBookingSuccess(BuildContext context) {
    context.read<DashboardProvider>().loadUpcoming();
    context.read<StatsProvider>().loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final tokenStorage = context.read<TokenStorage>();
    final baseUrl = context.read<String>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(
            repository: BookingRepository(
              httpClient: http.Client(),
              tokenStorage: tokenStorage,
              baseUrl: baseUrl,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsProvider(
            repository: StatsRepository(
              httpClient: http.Client(),
              tokenStorage: tokenStorage,
              baseUrl: baseUrl,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            repository: NotificationRepository(
              httpClient: http.Client(),
              tokenStorage: tokenStorage,
              baseUrl: baseUrl,
            ),
          ),
        ),
      ],
      child: Builder(
        builder: (ctx) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) SystemNavigator.pop();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(titles[currentIndex]),
              actions: [
                Consumer<NotificationProvider>(
                  builder: (context, notifProvider, _) {
                    final unread = notifProvider.unreadCount;
                    return IconButton(
                      key: const Key('notifications_button'),
                      icon: Badge(
                        isLabelVisible: unread > 0,
                        label: Text('$unread'),
                        child: const Icon(Icons.notifications_outlined),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: context.read<NotificationProvider>(),
                            child: const NotificationsScreen(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
                  child: ClassesScreen(
                    key: _classesKey,
                    onBookingSuccess: () => _onBookingSuccess(ctx),
                  ),
                ),
                const StatsScreen(),
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
    ),
    ),
  );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.tokenStorage, required this.baseUrl});

  final TokenStorage tokenStorage;
  final String baseUrl;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadUpcoming();
    });
  }

  void _goToSubscription(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(
            repository: SubscriptionRepository(
              httpClient: http.Client(),
              tokenStorage: widget.tokenStorage,
              baseUrl: widget.baseUrl,
            ),
          ),
          child: MySubscriptionScreen(
            gymListScreenBuilder: () => ChangeNotifierProvider(
              create: (_) => GymListProvider(
                repository: GymRepository(
                  httpClient: http.Client(),
                  tokenStorage: widget.tokenStorage,
                  baseUrl: widget.baseUrl,
                ),
              ),
              child: GymListScreen(
                gymPlansProviderBuilder: (gym) => ChangeNotifierProvider(
                  create: (_) => GymPlansProvider(
                    planRepository: MembershipPlanRepository(
                      httpClient: http.Client(),
                      tokenStorage: widget.tokenStorage,
                      baseUrl: widget.baseUrl,
                    ),
                    subscriptionRepository: SubscriptionRepository(
                      httpClient: http.Client(),
                      tokenStorage: widget.tokenStorage,
                      baseUrl: widget.baseUrl,
                    ),
                  ),
                  child: GymPlansScreen(gym: gym),
                ),
              ),
            ),
          ),
        ),
      ));

  void _goToGyms(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => GymListProvider(
            repository: GymRepository(
              httpClient: http.Client(),
              tokenStorage: widget.tokenStorage,
              baseUrl: widget.baseUrl,
            ),
          ),
          child: GymListScreen(
            gymPlansProviderBuilder: (gym) => ChangeNotifierProvider(
              create: (_) => GymPlansProvider(
                planRepository: MembershipPlanRepository(
                  httpClient: http.Client(),
                  tokenStorage: widget.tokenStorage,
                  baseUrl: widget.baseUrl,
                ),
                subscriptionRepository: SubscriptionRepository(
                  httpClient: http.Client(),
                  tokenStorage: widget.tokenStorage,
                  baseUrl: widget.baseUrl,
                ),
              ),
              child: GymPlansScreen(gym: gym),
            ),
          ),
        ),
      ));

  void _goToMyBookings(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => BookingProvider(
                repository: BookingRepository(
                  httpClient: http.Client(),
                  tokenStorage: widget.tokenStorage,
                  baseUrl: widget.baseUrl,
                ),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => RatingProvider(
                repository: RatingRepository(
                  httpClient: http.Client(),
                  tokenStorage: widget.tokenStorage,
                  baseUrl: widget.baseUrl,
                ),
              ),
            ),
          ],
          child: const MyBookingsScreen(),
        ),
      ));

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  key: const Key('home_logo'),
                  width: 72,
                  height: 72,
                ),
              ),
              const SizedBox(height: 32),
              _UpcomingSection(dashboard: dashboard),
              const SizedBox(height: 32),
              _HomeButton(
                key: const Key('subscription_button'),
                label: 'MI SUSCRIPCIÓN',
                icon: Icons.card_membership_outlined,
                onPressed: () => _goToSubscription(context),
              ),
              const SizedBox(height: 12),
              _HomeButton(
                key: const Key('gyms_button'),
                label: 'GIMNASIOS',
                icon: Icons.location_on_outlined,
                onPressed: () => _goToGyms(context),
              ),
              const SizedBox(height: 12),
              _HomeButton(
                key: const Key('my_bookings_button'),
                label: 'MIS RESERVAS',
                icon: Icons.event_outlined,
                onPressed: () => _goToMyBookings(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.dashboard});

  final DashboardProvider dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximas clases',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (dashboard.state == DashboardState.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(
                key: Key('dashboard_loading'),
              ),
            ),
          )
        else if (dashboard.state == DashboardState.error)
          Text(
            key: const Key('dashboard_error'),
            dashboard.error ?? 'Error al cargar clases',
            style: TextStyle(color: theme.colorScheme.error),
          )
        else if (dashboard.upcoming.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    key: const Key('dashboard_empty'),
                    'No tienes clases próximas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...dashboard.upcoming.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UpcomingBookingCard(booking: b),
            ),
          ),
      ],
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  const _UpcomingBookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = booking.classSession;
    final local = session.startTime.toLocal();
    final dateStr = DateFormat('dd/MM/yyyy').format(local);
    final timeStr = DateFormat('HH:mm').format(local);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.classType.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.gym.name} · $dateStr $timeStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
