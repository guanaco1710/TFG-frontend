import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/gyms/data/models/gym_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/models/membership_plan_models.dart';
import 'package:tfg_frontend/features/membership_plans/presentation/providers/gym_plans_provider.dart';

class GymPlansScreen extends StatefulWidget {
  const GymPlansScreen({super.key, required this.gym});

  final Gym gym;

  @override
  State<GymPlansScreen> createState() => _GymPlansScreenState();
}

class _GymPlansScreenState extends State<GymPlansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GymPlansProvider>().loadPlans();
    });
  }

  Future<void> _onJoinTapped(MembershipPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar suscripción'),
        content: Text(
          '¿Quieres unirte con el plan "${plan.name}" en ${widget.gym.name}?\n\n'
          '${plan.priceMonthly.toStringAsFixed(2)} € / mes',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<GymPlansProvider>();
    final success = await provider.subscribe(
      membershipPlanId: plan.id,
      gymId: widget.gym.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Te has suscrito correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al suscribirse'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.gym.name)),
      body: Consumer<GymPlansProvider>(
        builder: (context, provider, _) {
          return switch (provider.state) {
            PlansLoadState.initial || PlansLoadState.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            PlansLoadState.error => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  provider.errorMessage ?? 'Error al cargar los planes',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            PlansLoadState.loaded =>
              provider.plans.isEmpty
                  ? const Center(child: Text('No hay planes disponibles'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.plans.length,
                      itemBuilder: (_, index) => _PlanCard(
                        plan: provider.plans[index],
                        isSubscribing: provider.isSubscribing,
                        onJoin: () => _onJoinTapped(provider.plans[index]),
                      ),
                    ),
          };
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSubscribing,
    required this.onJoin,
  });

  final MembershipPlan plan;
  final bool isSubscribing;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classesLabel = plan.classesPerMonth == null
        ? 'Clases ilimitadas'
        : '${plan.classesPerMonth} clases / mes';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(plan.name, style: theme.textTheme.titleLarge),
                ),
                Text(
                  '${plan.priceMonthly.toStringAsFixed(2)} €',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '/ mes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              plan.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _Chip(icon: Icons.fitness_center, label: classesLabel),
                if (plan.allowsWaitlist)
                  _Chip(
                    icon: Icons.playlist_add_check,
                    label: 'Lista de espera',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSubscribing ? null : onJoin,
                child: isSubscribing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Unirse'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
