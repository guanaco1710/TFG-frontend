import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/gyms/data/models/gym_models.dart';
import 'package:tfg_frontend/features/gyms/presentation/providers/gym_list_provider.dart';

class GymListScreen extends StatefulWidget {
  const GymListScreen({super.key});

  @override
  State<GymListScreen> createState() => _GymListScreenState();
}

class _GymListScreenState extends State<GymListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GymListProvider>().loadGyms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gyms')),
      body: Consumer<GymListProvider>(
        builder: (context, provider, _) {
          return switch (provider.state) {
            GymListLoadState.initial ||
            GymListLoadState.loading => const Center(
              child: CircularProgressIndicator(key: Key('gym_list_loading')),
            ),
            GymListLoadState.error => Center(
              child: Text(
                key: const Key('gym_list_error'),
                provider.errorMessage ?? 'Failed to load gyms',
                textAlign: TextAlign.center,
              ),
            ),
            GymListLoadState.loaded =>
              provider.gyms.isEmpty
                  ? const Center(
                      key: Key('gym_list_empty'),
                      child: Text('No gyms available'),
                    )
                  : ListView.builder(
                      key: const Key('gym_list'),
                      itemCount: provider.gyms.length,
                      itemBuilder: (context, index) =>
                          _GymCard(gym: provider.gyms[index]),
                    ),
          };
        },
      ),
    );
  }
}

class _GymCard extends StatelessWidget {
  const _GymCard({required this.gym});

  final Gym gym;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gym.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${gym.address}, ${gym.city}'),
            if (gym.openingHours != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14),
                  const SizedBox(width: 4),
                  Expanded(child: Text(gym.openingHours!)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
