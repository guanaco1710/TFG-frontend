import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/models/subscription.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/class_session_provider.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/session_roster_provider.dart';
import 'package:tfg_frontend/features/classes/presentation/screens/class_session_detail_screen.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/providers/subscription_provider.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key, this.onBookingSuccess});

  final VoidCallback? onBookingSuccess;

  @override
  State<ClassesScreen> createState() => ClassesScreenState();
}

class ClassesScreenState extends State<ClassesScreen> {
  DateTime _selectedDay = _today();
  int? _activeGymId;
  bool? _hasActiveSubscription;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      _hasActiveSubscription = null;
      _selectedDay = _today();
    });
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final subProvider = context.read<SubscriptionProvider>();
    await subProvider.loadMySubscriptions();
    if (!mounted) return;
    final activeSub = subProvider.subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .firstOrNull;
    setState(() {
      _hasActiveSubscription = activeSub != null;
      _activeGymId = activeSub?.gym.id;
    });
    if (activeSub != null) {
      await Future.wait([
        context
            .read<ClassSessionProvider>()
            .loadSessionsByDay(_selectedDay, gymId: _activeGymId),
        context.read<BookingProvider>().loadMyBookings(),
      ]);
    }
  }

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = day);
    context
        .read<ClassSessionProvider>()
        .loadSessionsByDay(day, gymId: _activeGymId);
  }

  void _reloadCurrentDay() {
    context
        .read<ClassSessionProvider>()
        .refreshSessionsByDay(_selectedDay, gymId: _activeGymId);
  }

  void _retryCurrentDay() {
    context
        .read<ClassSessionProvider>()
        .loadSessionsByDay(_selectedDay, gymId: _activeGymId);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasActiveSubscription == false) {
      return const _NoSubscriptionState();
    }
    return Column(
      children: [
        _WeekStrip(
          selectedDay: _selectedDay,
          onDaySelected: _onDaySelected,
        ),
        const Divider(height: 1),
        Expanded(
          child: Consumer<ClassSessionProvider>(
            builder: (context, provider, _) {
              return switch (provider.state) {
                ClassSessionLoadState.initial ||
                ClassSessionLoadState.loading => const Center(
                  child: CircularProgressIndicator(key: Key('classes_loading')),
                ),
                ClassSessionLoadState.error => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          key: const Key('classes_error'),
                          provider.errorMessage ?? 'Error al cargar las clases',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const Key('classes_retry_button'),
                          onPressed: _retryCurrentDay,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
                ClassSessionLoadState.loaded =>
                  provider.sessions.isEmpty
                      ? const _EmptyState()
                      : _SessionList(
                          sessions: provider.sessions,
                          onRefresh: () {
                            _reloadCurrentDay();
                            widget.onBookingSuccess?.call();
                          },
                        ),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _WeekStrip extends StatefulWidget {
  const _WeekStrip({required this.selectedDay, required this.onDaySelected});

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
  static const _initialPage = 10000;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _weekMonday(int pageIndex) {
    final today = DateTime.now();
    final mondayThisWeek = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    return mondayThisWeek.add(Duration(days: (pageIndex - _initialPage) * 7));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('week_strip'),
      height: 72,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, pageIndex) {
          final monday = _weekMonday(pageIndex);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final day = monday.add(Duration(days: i));
              return _DayChip(
                day: day,
                isSelected: _isSameDay(day, widget.selectedDay),
                onTap: () => widget.onDaySelected(day),
              );
            }),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final label = dayLabels[day.weekday - 1];
    final dateStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      key: Key('day_chip_$dateStr'),
      onTap: onTap,
      child: Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSubscriptionState extends StatelessWidget {
  const _NoSubscriptionState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_membership_outlined,
            key: Key('no_subscription'),
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No tienes una suscripción activa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_outlined,
            key: Key('classes_empty_icon'),
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No hay clases disponibles',
            key: Key('classes_empty_text'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions, required this.onRefresh});

  final List<ClassSession> sessions;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) => _SessionCard(
        session: sessions[index],
        onRefresh: onRefresh,
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  const _SessionCard({required this.session, required this.onRefresh});

  final ClassSession session;
  final VoidCallback onRefresh;

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  int? _activeBookingId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bookings = context.read<BookingProvider>().bookings;
      final existing = bookings
          .where(
            (b) =>
                b.classSession.id == widget.session.id &&
                (b.status == BookingStatus.confirmed ||
                    b.status == BookingStatus.waitlisted),
          )
          .firstOrNull;
      if (existing != null) setState(() => _activeBookingId = existing.id);
    });
  }

  String _formatTimeRange(String isoStart, int durationMinutes) {
    try {
      final start = DateTime.parse(isoStart).toLocal();
      final end = start.add(Duration(minutes: durationMinutes));
      final fmt = DateFormat('HH:mm');
      return '${fmt.format(start)} – ${fmt.format(end)}';
    } catch (_) {
      return isoStart;
    }
  }

  Future<void> _book(BuildContext context) async {
    setState(() => _isLoading = true);
    final provider = context.read<BookingProvider>();
    final booking = await provider.book(classSessionId: widget.session.id);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (booking != null) _activeBookingId = booking.id;
    });
    if (!mounted) return;
    final message = booking == null
        ? (provider.bookingError ?? 'Error al realizar la reserva')
        : booking.status == BookingStatus.waitlisted
            ? 'Añadido a lista de espera'
            : 'Reserva confirmada';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (booking != null) widget.onRefresh();
  }

  Future<void> _cancel(BuildContext context) async {
    final bookingId = _activeBookingId;
    if (bookingId == null) return;
    setState(() => _isLoading = true);
    final provider = context.read<BookingProvider>();
    final success = await provider.cancelBooking(bookingId: bookingId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (success) _activeBookingId = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Reserva cancelada' : (provider.bookingError ?? 'Error al cancelar'),
        ),
      ),
    );
    if (success) widget.onRefresh();
  }

  void _openDetail(BuildContext context) {
    final tokenStorage = context.read<TokenStorage>();
    final baseUrl = context.read<String>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => SessionRosterProvider(
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
          ],
          child: ClassSessionDetailScreen(
            session: widget.session,
            initialBookingId: _activeBookingId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;
    final showBookButton = session.status == ClassSessionStatus.scheduled ||
        session.status == ClassSessionStatus.active;
    final isBooked = _activeBookingId != null;

    return Card(
      key: const Key('session_card'),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.fitness_center,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.classType.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimeRange(
                          session.startTime,
                          session.durationMinutes,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.confirmedCount}/${session.maxCapacity} inscritos',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  session.instructor.name,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (showBookButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : isBooked
                        ? FilledButton(
                            key: Key('cancel_session_${session.id}'),
                            onPressed: () => _cancel(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                            ),
                            child: const Text('Salir de la clase'),
                          )
                        : FilledButton.tonal(
                            key: Key('book_session_${session.id}'),
                            onPressed: () => _book(context),
                            child: const Text('Unirse a la clase'),
                          ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}


