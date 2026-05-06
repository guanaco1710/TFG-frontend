import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/notifications/data/models/notification_models.dart';
import 'package:tfg_frontend/features/notifications/presentation/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    final provider = context.read<NotificationProvider>();
    if (pos.pixels >= pos.maxScrollExtent - 300 &&
        provider.hasMore &&
        provider.state != NotificationState.loading) {
      provider.loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                key: const Key('mark_all_read_button'),
                onPressed: () => provider.markAllRead(),
                child: const Text('Marcar todo leído'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          return switch (provider.state) {
            NotificationState.idle ||
            NotificationState.loading => const Center(
              child: CircularProgressIndicator(
                key: Key('notifications_loading'),
              ),
            ),
            NotificationState.error => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      key: const Key('notifications_error'),
                      provider.error ?? 'Error al cargar notificaciones',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('notifications_retry_button'),
                      onPressed: () => provider.loadPage(0),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
            NotificationState.loaded => provider.notifications.isEmpty
                ? const Center(
                    child: Text(
                      key: Key('notifications_empty'),
                      'No tienes notificaciones',
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        provider.notifications.length +
                        (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final notification = provider.notifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () => provider.markRead(notification.id),
                        onDismiss: () => provider.delete(notification.id),
                      );
                    },
                  ),
          };
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  String get _title => switch (notification.type) {
    NotificationType.confirmation => 'Tu reserva fue confirmada',
    NotificationType.cancellation => 'Tu reserva fue cancelada',
    NotificationType.reminder => 'Tienes una clase próximamente',
  };

  String get _subtitle {
    final local = notification.session.startTime.toLocal();
    final formatted = DateFormat('dd/MM/yyyy HH:mm').format(local);
    return '${notification.session.classTypeName} · $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = notification.read
        ? null
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.3);

    return Dismissible(
      key: Key('notification_dismissible_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      child: ListTile(
        key: Key('notification_item_${notification.id}'),
        tileColor: backgroundColor,
        leading: Icon(
          notification.read
              ? Icons.notifications_outlined
              : Icons.notifications,
        ),
        title: Text(
          _title,
          style: notification.read
              ? null
              : const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_subtitle),
        onTap: onTap,
      ),
    );
  }
}
