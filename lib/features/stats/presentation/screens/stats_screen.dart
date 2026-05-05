import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/stats/data/models/stats_models.dart';
import 'package:tfg_frontend/features/stats/presentation/providers/stats_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, provider, _) {
        return switch (provider.state) {
          StatsLoadState.initial || StatsLoadState.loading => const Center(
            child: CircularProgressIndicator(key: Key('stats_loading')),
          ),
          StatsLoadState.error => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    key: const Key('stats_error'),
                    provider.errorMessage ?? 'Error al cargar las estadísticas',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('stats_retry_button'),
                    onPressed: provider.loadStats,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          StatsLoadState.loaded => _StatsContent(stats: provider.stats!),
        };
      },
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendancePct = '${(stats.attendanceRate * 100).toStringAsFixed(0)}%';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: const Key('stat_attended'),
                  icon: Icons.check_circle_outline,
                  value: '${stats.totalAttended}',
                  label: 'Clases asistidas',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  key: const Key('stat_streak'),
                  icon: Icons.local_fire_department_outlined,
                  value: '${stats.currentStreak}',
                  label: 'Racha actual',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: const Key('stat_rate'),
                  icon: Icons.percent,
                  value: attendancePct,
                  label: 'Asistencia',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  key: const Key('stat_this_month'),
                  icon: Icons.calendar_month_outlined,
                  value: '${stats.classesBookedThisMonth}',
                  label: 'Este mes',
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalle',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    key: const Key('detail_total_bookings'),
                    label: 'Total reservas',
                    value: '${stats.totalBookings}',
                  ),
                  _DetailRow(
                    key: const Key('detail_no_shows'),
                    label: 'No presentado',
                    value: '${stats.totalNoShows}',
                  ),
                  _DetailRow(
                    key: const Key('detail_cancellations'),
                    label: 'Cancelaciones',
                    value: '${stats.totalCancellations}',
                  ),
                  if (stats.classesRemainingThisMonth != null)
                    _DetailRow(
                      key: const Key('detail_remaining'),
                      label: 'Clases restantes mes',
                      value: '${stats.classesRemainingThisMonth}',
                    ),
                  if (stats.favoriteClassType != null)
                    _DetailRow(
                      key: const Key('detail_favorite'),
                      label: 'Clase favorita',
                      value: stats.favoriteClassType!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
