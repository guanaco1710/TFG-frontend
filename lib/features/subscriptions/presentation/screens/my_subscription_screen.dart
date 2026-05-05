import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/gyms/data/repositories/gym_repository.dart';
import 'package:tfg_frontend/features/gyms/presentation/providers/gym_list_provider.dart';
import 'package:tfg_frontend/features/gyms/presentation/screens/gym_list_screen.dart';
import 'package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart';
import 'package:tfg_frontend/features/subscriptions/presentation/providers/subscription_provider.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadMySubscriptions();
    });
  }

  Future<void> _onCancelTapped(
    BuildContext context,
    Subscription subscription,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar suscripción'),
        content: Text(
          '¿Quieres cancelar tu suscripción a ${subscription.gym.name}?\n\n'
          'Seguirás teniendo acceso hasta el ${subscription.renewalDate}. '
          'No se realizará ningún cargo adicional.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar suscripción'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<SubscriptionProvider>();
    final success = await provider.cancelSubscription(
      subscriptionId: subscription.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suscripción cancelada. Acceso activo hasta renovación.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Error al cancelar la suscripción',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _browseGyms(BuildContext context) {
    final tokenStorage = context.read<TokenStorage>();
    final baseUrl = context.read<String>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis suscripciones')),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          return switch (provider.state) {
            SubscriptionLoadState.initial ||
            SubscriptionLoadState.loading => const Center(
              child: CircularProgressIndicator(
                key: Key('subscription_loading'),
              ),
            ),
            SubscriptionLoadState.error => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  key: const Key('subscription_error'),
                  provider.errorMessage ?? 'Error al cargar las suscripciones',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SubscriptionLoadState.loaded =>
              provider.subscriptions.isEmpty
                  ? _EmptyState(onBrowseGyms: () => _browseGyms(context))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.subscriptions.length,
                      itemBuilder: (_, index) {
                        final sub = provider.subscriptions[index];
                        return _SubscriptionCard(
                          subscription: sub,
                          isCancelling: provider.isCancelling,
                          onCancel:
                              sub.status == SubscriptionStatus.active &&
                                      !sub.pendingCancellation
                                  ? () => _onCancelTapped(context, sub)
                                  : null,
                        );
                      },
                    ),
          };
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBrowseGyms});

  final VoidCallback onBrowseGyms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_membership_outlined,
                size: 52,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Sin suscripción activa',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Explora los gimnasios disponibles y encuentra un plan que se adapte a ti.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              key: const Key('browse_gyms_button'),
              onPressed: onBrowseGyms,
              icon: const Icon(Icons.search),
              label: const Text('Ver gimnasios'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.isCancelling,
    required this.onCancel,
  });

  final Subscription subscription;
  final bool isCancelling;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('subscription_card'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subscription.gym.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                _StatusBadge(
                  status: subscription.status,
                  pendingCancellation: subscription.pendingCancellation,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${subscription.gym.address}, ${subscription.gym.city}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 32),
            _InfoRow(label: 'Plan', value: subscription.plan.name),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Precio',
              value:
                  '${subscription.plan.priceMonthly.toStringAsFixed(2)} € / mes',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Clases utilizadas',
              value: '${subscription.classesUsedThisMonth}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Clases restantes',
              value: subscription.classesRemainingThisMonth == null
                  ? 'Ilimitadas'
                  : '${subscription.classesRemainingThisMonth}',
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Renovación', value: subscription.renewalDate),
            if (subscription.pendingPlan != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Próximo plan',
                value:
                    '${subscription.pendingPlan!.name} — ${subscription.pendingPlan!.priceMonthly.toStringAsFixed(2)} € / mes',
              ),
            ],
            if (onCancel != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('cancel_subscription_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: isCancelling ? null : onCancel,
                  child: isCancelling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancelar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.pendingCancellation,
  });

  final SubscriptionStatus status;
  final bool pendingCancellation;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SubscriptionStatus.active when pendingCancellation =>
        ('CANCELACIÓN PENDIENTE', Colors.orange),
      SubscriptionStatus.active => ('ACTIVA', Colors.green),
      SubscriptionStatus.cancelled => ('CANCELADA', Colors.orange),
      SubscriptionStatus.expired => ('EXPIRADA', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
