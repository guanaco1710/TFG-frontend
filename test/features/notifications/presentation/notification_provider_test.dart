import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/exceptions/api_exception.dart';
import 'package:tfg_frontend/features/notifications/data/models/notification_models.dart';
import 'package:tfg_frontend/features/notifications/data/repositories/notification_repository.dart';
import 'package:tfg_frontend/features/notifications/presentation/providers/notification_provider.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

final _session = NotificationSession(
  id: 10,
  startTime: DateTime.parse('2026-05-01T10:00:00Z'),
  classTypeName: 'Spinning 45min',
);

AppNotification _makeNotification({
  int id = 1,
  bool read = false,
  NotificationType type = NotificationType.confirmation,
}) =>
    AppNotification(
      id: id,
      type: type,
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
      content: content ?? [_makeNotification()],
      page: 0,
      size: 20,
      totalElements: content?.length ?? 1,
      totalPages: 1,
      hasMore: hasMore,
    );

void main() {
  late MockNotificationRepository repository;

  setUp(() {
    repository = MockNotificationRepository();
    when(
      () => repository.fetchNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer((_) async => _makePage());
    when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 1);
  });

  NotificationProvider buildProvider() =>
      NotificationProvider(repository: repository);

  group('initial load', () {
    test('triggers fetchNotifications and fetchUnreadCount', () async {
      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      verify(
        () => repository.fetchNotifications(
          page: 0,
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).called(1);
      verify(() => repository.fetchUnreadCount()).called(1);

      provider.dispose();
    });

    test('state is loading during fetch then loaded when done', () async {
      // loadPage(0) fires notifyListeners() synchronously for the loading
      // state before the first await, so it happens inside the constructor.
      // We verify the post-construction state via a Completer-based approach.
      final completer = Completer<NotificationPage>();
      when(
        () => repository.fetchNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer((_) => completer.future);

      final provider = buildProvider();
      // At this point loadPage is mid-flight (awaiting fetchNotifications)
      // so state should be loading.
      expect(provider.state, NotificationState.loading);

      completer.complete(_makePage());
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(provider.state, NotificationState.loaded);
      provider.dispose();
    });

    test('populates notifications and unreadCount on success', () async {
      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(provider.notifications, hasLength(1));
      expect(provider.notifications[0].id, 1);
      expect(provider.unreadCount, 1);
      provider.dispose();
    });

    test('transitions to error state on ApiException', () async {
      when(
        () => repository.fetchNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenThrow(
        const ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Token expired',
          path: '/notifications/me',
        ),
      );

      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(provider.state, NotificationState.error);
      expect(provider.error, 'Token expired');
      provider.dispose();
    });

    test('transitions to error state on generic exception', () async {
      when(
        () => repository.fetchNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenThrow(Exception('Network error'));

      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(provider.state, NotificationState.error);
      expect(provider.error, isNotNull);
      provider.dispose();
    });
  });

  group('markRead', () {
    test('updates local notification read=true and decrements unreadCount',
        () async {
      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      when(() => repository.markRead(1)).thenAnswer((_) async {});

      await provider.markRead(1);

      expect(provider.notifications[0].read, isTrue);
      expect(provider.unreadCount, 0);
      provider.dispose();
    });

    test('does not decrement below zero when already read', () async {
      when(
        () => repository.fetchNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => _makePage(content: [_makeNotification(read: true)]),
      );
      when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 0);

      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      when(() => repository.markRead(1)).thenAnswer((_) async {});

      await provider.markRead(1);

      expect(provider.unreadCount, 0);
      provider.dispose();
    });
  });

  group('markAllRead', () {
    test('sets all notifications read=true and unreadCount=0', () async {
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

      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      when(() => repository.markAllRead()).thenAnswer((_) async => 2);

      await provider.markAllRead();

      expect(provider.notifications.every((n) => n.read), isTrue);
      expect(provider.unreadCount, 0);
      provider.dispose();
    });
  });

  group('delete', () {
    test('removes item from list and decrements unreadCount when unread',
        () async {
      when(
        () => repository.fetchNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => _makePage(content: [
          _makeNotification(id: 1, read: false),
          _makeNotification(id: 2, read: true),
        ]),
      );
      when(() => repository.fetchUnreadCount()).thenAnswer((_) async => 1);

      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      when(() => repository.delete(1)).thenAnswer((_) async {});

      await provider.delete(1);

      expect(provider.notifications, hasLength(1));
      expect(provider.notifications[0].id, 2);
      expect(provider.unreadCount, 0);
      provider.dispose();
    });

    test('removes item without decrementing unreadCount when already read',
        () async {
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

      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      when(() => repository.delete(1)).thenAnswer((_) async {});

      await provider.delete(1);

      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
      provider.dispose();
    });
  });

  group('loadNextPage', () {
    test('appends notifications when hasMore is true', () async {
      when(
        () => repository.fetchNotifications(
          page: 0,
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => NotificationPage(
          content: [_makeNotification(id: 1)],
          page: 0,
          size: 20,
          totalElements: 2,
          totalPages: 2,
          hasMore: true,
        ),
      );
      when(
        () => repository.fetchNotifications(
          page: 1,
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => NotificationPage(
          content: [_makeNotification(id: 2)],
          page: 1,
          size: 20,
          totalElements: 2,
          totalPages: 2,
          hasMore: false,
        ),
      );

      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(provider.hasMore, isTrue);

      await provider.loadNextPage();

      expect(provider.notifications, hasLength(2));
      expect(provider.hasMore, isFalse);
      provider.dispose();
    });

    test('does nothing when hasMore is false', () async {
      final provider = buildProvider();
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(provider.hasMore, isFalse);

      await provider.loadNextPage();

      verify(
        () => repository.fetchNotifications(
          page: any(named: 'page'),
          size: any(named: 'size'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).called(1); // only the initial load
      provider.dispose();
    });
  });
}
