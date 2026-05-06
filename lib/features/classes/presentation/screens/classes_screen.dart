import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/models/subscription.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/class_session_provider.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/providers/subscription_provider.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

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
      await context
          .read<ClassSessionProvider>()
          .loadSessionsByDay(_selectedDay, gymId: _activeGymId);
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
                          onPressed: _reloadCurrentDay,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
                ClassSessionLoadState.loaded =>
                  provider.sessions.isEmpty
                      ? const _EmptyState()
                      : _SessionList(sessions: provider.sessions),
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
  const _SessionList({required this.sessions});

  final List<ClassSession> sessions;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) => _SessionCard(session: sessions[index]),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final ClassSession session;

  String _formatTime(String isoTime) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(isoTime).toLocal());
    } catch (_) {
      return isoTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (session.status) {
      ClassSessionStatus.scheduled => Colors.blue,
      ClassSessionStatus.active => Colors.green,
      ClassSessionStatus.cancelled => Colors.red,
      ClassSessionStatus.finished => Colors.grey,
    };

    final showBookButton = session.status == ClassSessionStatus.scheduled;
    final isWaitlist = showBookButton && session.availableSpots == 0;

    return Card(
      key: const Key('session_card'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.classType.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(status: session.status, color: statusColor),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              session.classType.level ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(height: 20),
            _IconRow(
              icon: Icons.location_on_outlined,
              text: '${session.gym.name} · ${session.room}',
            ),
            const SizedBox(height: 6),
            _IconRow(
              icon: Icons.person_outline,
              text: session.instructor.specialty != null
                  ? '${session.instructor.name} · ${session.instructor.specialty}'
                  : session.instructor.name,
            ),
            const SizedBox(height: 6),
            _IconRow(
              icon: Icons.schedule_outlined,
              text: '${_formatTime(session.startTime)} · ${session.durationMinutes} min',
            ),
            const SizedBox(height: 6),
            _IconRow(
              icon: Icons.people_outline,
              text:
                  '${session.availableSpots} plazas disponibles'
                  ' de ${session.maxCapacity}',
            ),
            if (showBookButton) ...[
              const SizedBox(height: 12),
              _BookButton(sessionId: session.id, isWaitlist: isWaitlist),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({required this.sessionId, required this.isWaitlist});

  final int sessionId;
  final bool isWaitlist;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      key: Key('book_session_$sessionId'),
      onPressed: () => _onBook(context),
      child: Text(isWaitlist ? 'Lista de espera' : 'Reservar'),
    );
  }

  Future<void> _onBook(BuildContext context) async {
    final provider = context.read<BookingProvider>();
    final booking = await provider.book(classSessionId: sessionId);

    if (!context.mounted) return;

    if (booking != null) {
      final message = booking.status == BookingStatus.waitlisted
          ? 'Añadido a lista de espera'
          : 'Reserva confirmada';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.bookingError ?? 'Error al realizar la reserva',
          ),
        ),
      );
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final ClassSessionStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ClassSessionStatus.scheduled => 'PROGRAMADA',
      ClassSessionStatus.active => 'ACTIVA',
      ClassSessionStatus.cancelled => 'CANCELADA',
      ClassSessionStatus.finished => 'FINALIZADA',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
