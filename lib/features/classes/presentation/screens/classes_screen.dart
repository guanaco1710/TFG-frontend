import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/presentation/providers/class_session_provider.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassSessionProvider>().loadSessions();
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
      context.read<ClassSessionProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClassSessionProvider>(
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    key: const Key('classes_error'),
                    provider.errorMessage ?? 'Error al cargar las clases',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('classes_retry_button'),
                    onPressed: () => provider.loadSessions(),
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
                    hasMore: provider.hasMore,
                    isLoadingMore: provider.isLoadingMore,
                    scrollController: _scrollController,
                  ),
        };
      },
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
  const _SessionList({
    required this.sessions,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
  });

  final List<ClassSession> sessions;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == sessions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(key: Key('load_more_indicator')),
            ),
          );
        }
        return _SessionCard(session: sessions[index]);
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (session.status) {
      ClassSessionStatus.scheduled => Colors.blue,
      ClassSessionStatus.active => Colors.green,
      ClassSessionStatus.cancelled => Colors.red,
      ClassSessionStatus.finished => Colors.grey,
    };

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
              session.classType.level,
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
              text: '${session.startTime} · ${session.durationMinutes} min',
            ),
            const SizedBox(height: 6),
            _IconRow(
              icon: Icons.people_outline,
              text:
                  '${session.availableSpots} plazas disponibles'
                  ' de ${session.maxCapacity}',
            ),
          ],
        ),
      ),
    );
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
