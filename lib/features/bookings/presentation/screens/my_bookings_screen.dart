import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart';
import 'package:tfg_frontend/features/ratings/presentation/providers/rating_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadMyBookings();
      context.read<RatingProvider>().loadMyRatings();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context.read<BookingProvider>().loadMore();
    }
  }

  Future<void> _onRefresh() {
    return context.read<BookingProvider>().loadMyBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas')),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          return switch (provider.state) {
            BookingLoadState.initial ||
            BookingLoadState.loading => const Center(
              child: CircularProgressIndicator(key: Key('bookings_loading')),
            ),
            BookingLoadState.error => Center(
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
                      key: const Key('bookings_error'),
                      provider.errorMessage ?? 'Error al cargar las reservas',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => provider.loadMyBookings(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
            BookingLoadState.loaded =>
              provider.bookings.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            key: Key('bookings_empty'),
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tienes reservas todavía',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            provider.bookings.length +
                            (provider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.bookings.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  key: Key('bookings_load_more'),
                                ),
                              ),
                            );
                          }
                          final booking = provider.bookings[index];
                          return Consumer<RatingProvider>(
                            builder: (context, ratingProvider, _) {
                              final isRated = ratingProvider.isRated(
                                booking.classSession.id,
                              );
                              return _BookingCard(
                                booking: booking,
                                onCancel: () =>
                                    _confirmCancel(context, booking),
                                isRated: isRated,
                                onRate: booking.status ==
                                            BookingStatus.attended &&
                                        !isRated
                                    ? () => _showRatingDialog(
                                          context,
                                          booking.classSession.id,
                                        )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    ),
          };
        },
      ),
    );
  }

  Future<void> _showRatingDialog(
    BuildContext context,
    int sessionId,
  ) async {
    int? selectedScore;
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          key: const Key('rate_dialog'),
          title: const Text('Valorar clase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    key: Key('star_$star'),
                    icon: Icon(
                      star <= (selectedScore ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () =>
                        setDialogState(() => selectedScore = star),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('rate_comment_field'),
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Comentario (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('rate_submit_button'),
              onPressed: selectedScore == null
                  ? null
                  : () async {
                      final score = selectedScore!;
                      final comment = commentController.text.trim().isEmpty
                          ? null
                          : commentController.text.trim();
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      final ratingProvider = context.read<RatingProvider>();
                      final result = await ratingProvider.submitRating(
                        sessionId: sessionId,
                        score: score,
                        comment: comment,
                      );
                      if (!mounted) return;
                      if (result == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ratingProvider.submitError ??
                                  'Error al valorar la clase',
                            ),
                          ),
                        );
                      }
                    },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    commentController.dispose();
  }

  Future<void> _confirmCancel(BuildContext context, Booking booking) async {
    final provider = context.read<BookingProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text(
          '¿Deseas cancelar tu reserva de ${booking.classSession.classType.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await provider.cancelBooking(bookingId: booking.id);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Reserva cancelada')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Error al cancelar la reserva',
          ),
        ),
      );
    }
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.isRated,
    this.onRate,
  });

  final Booking booking;
  final VoidCallback onCancel;
  final bool isRated;
  final VoidCallback? onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: Key('booking_card_${booking.id}'),
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
                    booking.classSession.classType.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              booking.classSession.gym.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatStartTime(booking.classSession.startTime),
              style: theme.textTheme.bodySmall,
            ),
            if (booking.status == BookingStatus.waitlisted &&
                booking.waitlistPosition != null) ...[
              const SizedBox(height: 4),
              Text(
                'Posición: ${booking.waitlistPosition}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],
            if (booking.status == BookingStatus.confirmed ||
                booking.status == BookingStatus.waitlisted) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: Key('cancel_booking_${booking.id}'),
                onPressed: onCancel,
                child: const Text('Cancelar'),
              ),
            ],
            if (booking.status == BookingStatus.attended) ...[
              const SizedBox(height: 12),
              if (isRated)
                Container(
                  key: Key('rated_badge_${booking.id}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Valorada',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: Key('rate_booking_${booking.id}'),
                    icon: const Icon(Icons.star_border),
                    label: const Text('Valorar'),
                    onPressed: onRate,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatStartTime(DateTime startTime) =>
      DateFormat('dd MMM · HH:mm').format(startTime.toLocal());
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BookingStatus.confirmed => ('CONFIRMADA', Colors.green),
      BookingStatus.waitlisted => ('LISTA DE ESPERA', Colors.orange),
      BookingStatus.cancelled => ('CANCELADA', Colors.grey),
      BookingStatus.attended => ('ASISTIDA', Colors.blue),
      BookingStatus.noShow => ('NO PRESENTADO', Colors.red),
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
