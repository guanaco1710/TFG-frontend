import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/session_roster_provider.dart';

class ClassSessionDetailScreen extends StatefulWidget {
  const ClassSessionDetailScreen({
    super.key,
    required this.session,
    this.initialBookingId,
  });

  final ClassSession session;
  final int? initialBookingId;

  @override
  State<ClassSessionDetailScreen> createState() =>
      _ClassSessionDetailScreenState();
}

class _ClassSessionDetailScreenState extends State<ClassSessionDetailScreen> {
  int? _activeBookingId;
  bool _isBookingLoading = false;

  @override
  void initState() {
    super.initState();
    _activeBookingId = widget.initialBookingId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<SessionRosterProvider>().load(widget.session.id),
    );
  }

  String _formatTimeRange() {
    try {
      final start = DateTime.parse(widget.session.startTime).toLocal();
      final end = start.add(Duration(minutes: widget.session.durationMinutes));
      final fmt = DateFormat('HH:mm');
      return '${fmt.format(start)} – ${fmt.format(end)}';
    } catch (_) {
      return widget.session.startTime;
    }
  }

  int _completionPct() {
    if (widget.session.maxCapacity == 0) return 0;
    return (widget.session.confirmedCount / widget.session.maxCapacity * 100)
        .round();
  }

  Future<void> _book() async {
    setState(() => _isBookingLoading = true);
    final provider = context.read<BookingProvider>();
    final booking = await provider.book(classSessionId: widget.session.id);
    if (!mounted) return;
    setState(() {
      _isBookingLoading = false;
      if (booking != null) _activeBookingId = booking.id;
    });
    if (!mounted) return;
    final message = booking == null
        ? (provider.bookingError ?? 'Error al realizar la reserva')
        : booking.status == BookingStatus.waitlisted
            ? 'Añadido a lista de espera'
            : 'Reserva confirmada';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancel() async {
    final bookingId = _activeBookingId;
    if (bookingId == null) return;
    setState(() => _isBookingLoading = true);
    final provider = context.read<BookingProvider>();
    final success = await provider.cancelBooking(bookingId: bookingId);
    if (!mounted) return;
    setState(() {
      _isBookingLoading = false;
      if (success) _activeBookingId = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Reserva cancelada'
              : (provider.bookingError ?? 'Error al cancelar'),
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

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.fitness_center,
                        size: 28,
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
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimeRange(),
                            style: theme.textTheme.bodyMedium?.copyWith(
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
                      Icons.person_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      session.instructor.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Asistentes',
                  key: const Key('detail_attendees_header'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_completionPct()}% completo',
                  key: const Key('detail_completion_pct'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SessionRosterProvider>(
              builder: (context, rosterProvider, _) {
                return switch (rosterProvider.state) {
                  SessionRosterState.initial ||
                  SessionRosterState.loading => const Center(
                    child: CircularProgressIndicator(
                      key: Key('detail_roster_loading'),
                    ),
                  ),
                  SessionRosterState.error => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rosterProvider.errorMessage ??
                              'Error al cargar asistentes',
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const Key('detail_roster_retry'),
                          onPressed: () => rosterProvider.reload(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                  SessionRosterState.loaded => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: rosterProvider.entries.length,
                    itemBuilder: (context, i) {
                      final entry = rosterProvider.entries[i];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(entry.userFullName),
                        trailing: Icon(
                          Icons.check_circle,
                          key: Key('attendee_check_${entry.userId}'),
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
                  ),
                };
              },
            ),
          ),
          if (showBookButton)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: _isBookingLoading
                    ? const Center(child: CircularProgressIndicator())
                    : isBooked
                        ? FilledButton(
                            key: const Key('detail_cancel_button'),
                            onPressed: _cancel,
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                            ),
                            child: const Text('Salir de la clase'),
                          )
                        : FilledButton.tonal(
                            key: const Key('detail_book_button'),
                            onPressed: _book,
                            child: const Text('Unirse a la clase'),
                          ),
              ),
            ),
        ],
      ),
    );
  }
}
