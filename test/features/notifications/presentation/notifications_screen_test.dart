import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/exceptions/api_exception.dart';
import 'package:tfg_frontend/features/notifications/data/models/notification_models.dart';
import 'package:tfg_frontend/features/notifications/data/repositories/notification_repository.dart';
import 'package:tfg_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:tfg_frontend/features/notifications/presentation/screens/notifications_screen.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

final _session = NotificationSession(
  id: 10,
  startTime: DateTime.parse('2026-05-01T10:00:00Z'),
  classTypeName: 'Spinning 45min',
);

AppNotification _makeNotification({int id = 1, bool read = false}) =>
    AppNotification(
      id: id,
      type: NotificationType.confirmation,
      scheduledAt: DateTime.parse('2026-05-01T09:00:00Z'),
      sent: true,
      sentAt: DateTime.parse('2026-05-01T09:00:05Z'),
      read: read,
      userId: 1,
      session: _session,
    );

NotificationPage _makePage({
  List<AppNotification>? content,
  bool hasMore = false,
}) =>
    NotificationPage(
      content: content ?? [],
      page: 0,
      size: 20,
      totalElements: content?.length ?? 0,
      totalPages: 1,
      hasMore: hasMore,
    );

Widget _wrap(NotificationProvider provider) => ChangeNotifierProvider.value(
  value: provider,
  child: const MaterialApp(home: NotificationsScreen()),
);

NotificationProvider _buildProvider(MockNotificationRepository repo) =>
    NotificationProvider(repository: repo);

void main() {
  late MockNotificationRepository repository;

  setUp(() {
    repository = MockNotificationRepository();
  });

  testWidgets('shows CircularProgressIndicator in loading state', (
    tester,
  ) async {
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer((_) => Completer<NotificationPage>().future);
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 0);

    final provider = _buildProvider(repository);
    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byKey(const Key('notifications_loading')), findsOneWidget);
    provider.dispose();
  });

  testWidgets('shows empty state text when list is empty', (tester) async {
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer((_) async => _makePage());
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 0);

    final provider = _buildProvider(repository);
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications_empty')), findsOneWidget);
    expect(find.text('No tienes notificaciones'), findsOneWidget);
    provider.dispose();
  });

  testWidgets('shows error text and retry button in error state', (
    tester,
  ) async {
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenThrow(
      const ApiException(
        status: 500,
        error: 'Server Error',
        message: 'Internal server error',
        path: '/notifications/me',
      ),
    );
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 0);

    final provider = _buildProvider(repository);
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications_error')), findsOneWidget);
    expect(find.byKey(const Key('notifications_retry_button')), findsOneWidget);
    expect(find.text('Internal server error'), findsOneWidget);
    provider.dispose();
  });

  testWidgets('shows notification items with correct keys', (tester) async {
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer(
      (_) async => _makePage(content: [
        _makeNotification(id: 1),
        _makeNotification(id: 2),
      ]),
    );
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 2);

    final provider = _buildProvider(repository);
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification_item_1')), findsOneWidget);
    expect(find.byKey(const Key('notification_item_2')), findsOneWidget);
    provider.dispose();
  });

  testWidgets('tapping notification item calls markRead', (tester) async {
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer(
      (_) async => _makePage(content: [_makeNotification(id: 1)]),
    );
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 1);
    when(() => repository.markRead(1)).thenAnswer((_) async {});

    final provider = _buildProvider(repository);
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification_item_1')));
    await tester.pumpAndSettle();

    verify(() => repository.markRead(1)).called(1);
    provider.dispose();
  });

  testWidgets('shows mark_all_read_button when unreadCount > 0', (
    tester,
  ) async {
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer(
      (_) async => _makePage(content: [_makeNotification(id: 1)]),
    );
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 1);

    final provider = _buildProvider(repository);
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);
    provider.dispose();
  });

  testWidgets('mark_all_read_button is hidden when unreadCount is 0', (
    tester,
  ) async {
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer(
      (_) async => _makePage(content: [_makeNotification(id: 1, read: true)]),
    );
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 0);

    final provider = _buildProvider(repository);
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mark_all_read_button')), findsNothing);
    provider.dispose();
  });

  testWidgets('tapping mark_all_read_button calls markAllRead', (
    tester,
  ) async {
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer(
      (_) async => _makePage(content: [_makeNotification(id: 1)]),
    );
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 1);
    when(() => repository.markAllRead()).thenAnswer((_) async => 1);

    final provider = _buildProvider(repository);
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mark_all_read_button')));
    await tester.pumpAndSettle();

    verify(() => repository.markAllRead()).called(1);
    provider.dispose();
  });

  testWidgets('swipe-to-dismiss calls delete', (tester) async {
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer(
      (_) async => _makePage(content: [_makeNotification(id: 1)]),
    );
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 1);
    when(() => repository.delete(1)).thenAnswer((_) async {});

    final provider = _buildProvider(repository);
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('notification_dismissible_1')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    verify(() => repository.delete(1)).called(1);
    provider.dispose();
  });

  testWidgets('retry button reloads notifications', (tester) async {
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenThrow(
      const ApiException(
        status: 500,
        error: 'Server Error',
        message: 'Internal server error',
        path: '/notifications/me',
      ),
    );
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 0);

    final provider = _buildProvider(repository);
    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer((_) async => _makePage());

    await tester.tap(find.byKey(const Key('notifications_retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications_empty')), findsOneWidget);
    provider.dispose();
  });
}
