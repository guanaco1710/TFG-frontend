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
      context.read<SubscriptionProvider>().loadMySubscription();
    });
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
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        return switch (provider.state) {
          SubscriptionLoadState.initial ||
          SubscriptionLoadState.loading => const Center(
            child: CircularProgressIndicator(key: Key('subscription_loading')),
          ),
          SubscriptionLoadState.error => Center(
            child: Text(
              key: const Key('subscription_error'),
              provider.errorMessage ?? 'Failed to load subscription',
              textAlign: TextAlign.center,
            ),
          ),
          SubscriptionLoadState.loaded =>
            provider.subscription == null
                ? _EmptyState(onBrowseGyms: () => _browseGyms(context))
                : _SubscriptionCard(subscription: provider.subscription!),
        };
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBrowseGyms});

  final VoidCallback onBrowseGyms;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No active subscription',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse available gyms and find a membership plan that suits you.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('browse_gyms_button'),
              onPressed: onBrowseGyms,
              child: const Text('Browse gyms'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        key: const Key('subscription_card'),
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
                  _StatusBadge(status: subscription.status),
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
                label: 'Price',
                value:
                    '\$${subscription.plan.priceMonthly.toStringAsFixed(2)} / month',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Classes used',
                value: '${subscription.classesUsedThisMonth}',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Classes remaining',
                value: subscription.classesRemainingThisMonth == null
                    ? 'Unlimited'
                    : '${subscription.classesRemainingThisMonth}',
              ),
              const SizedBox(height: 8),
              _InfoRow(label: 'Renewal', value: subscription.renewalDate),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SubscriptionStatus.active => ('ACTIVE', Colors.green),
      SubscriptionStatus.cancelled => ('CANCELLED', Colors.orange),
      SubscriptionStatus.expired => ('EXPIRED', Colors.red),
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
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
