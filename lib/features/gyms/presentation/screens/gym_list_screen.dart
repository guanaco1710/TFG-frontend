import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/gyms/data/models/gym_models.dart';
import 'package:tfg_frontend/features/gyms/presentation/providers/gym_list_provider.dart';

class GymListScreen extends StatefulWidget {
  const GymListScreen({super.key, required this.gymPlansProviderBuilder});

  final Widget Function(Gym gym) gymPlansProviderBuilder;

  @override
  State<GymListScreen> createState() => _GymListScreenState();
}

class _GymListScreenState extends State<GymListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GymListProvider>().loadGyms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context.read<GymListProvider>().loadMore();
    }
  }

  void _clearSearch(GymListProvider provider) {
    _searchController.clear();
    provider.query = '';
  }

  void _openGymPlans(Gym gym) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.gymPlansProviderBuilder(gym),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gimnasios')),
      body: Consumer<GymListProvider>(
        builder: (context, provider, _) {
          return switch (provider.state) {
            GymListLoadState.initial ||
            GymListLoadState.loading => const Center(
              child: CircularProgressIndicator(key: Key('gym_list_loading')),
            ),
            GymListLoadState.error => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  key: const Key('gym_list_error'),
                  provider.errorMessage ?? 'Error al cargar los gimnasios',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            GymListLoadState.loaded => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    key: const Key('gym_search_field'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar gimnasio...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: provider.query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _clearSearch(provider),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => provider.query = value,
                  ),
                ),
                Expanded(
                  child: provider.gyms.isEmpty
                      ? Center(
                          key: const Key('gym_list_empty'),
                          child: Text(
                            provider.query.isEmpty
                                ? 'No hay gimnasios disponibles'
                                : 'Sin resultados para "${provider.query}"',
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<GymListProvider>().loadGyms(),
                          child: ListView.builder(
                            key: const Key('gym_list'),
                            controller: _scrollController,
                            itemCount:
                                provider.gyms.length +
                                (provider.isLoadingMore ? 1 : 0),
                            itemBuilder: (_, index) {
                              if (index == provider.gyms.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final gym = provider.gyms[index];
                              return _GymCard(
                                gym: gym,
                                onTap: () => _openGymPlans(gym),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          };
        },
      ),
    );
  }
}

class _GymCard extends StatelessWidget {
  const _GymCard({required this.gym, required this.onTap});

  final Gym gym;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
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
      ),
    );
  }
}
