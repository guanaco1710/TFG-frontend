import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/exceptions/api_exception.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/notifications/data/models/notification_models.dart';
import 'package:tfg_frontend/features/notifications/data/repositories/notification_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeUri extends Fake implements Uri {}

const _notificationJson = {
  'id': 1,
  'type': 'CONFIRMATION',
  'scheduledAt': '2026-05-01T09:00:00Z',
  'sent': true,
  'sentAt': '2026-05-01T09:00:05Z',
  'read': false,
  'userId': 1,
  'session': {
    'id': 10,
    'startTime': '2026-05-01T10:00:00Z',
    'classType': {'name': 'Spinning 45min'},
  },
};

const _pageJson = {
  'content': [_notificationJson],
  'page': 0,
  'size': 20,
  'totalElements': 5,
  'totalPages': 1,
  'hasMore': false,
};

const _errorJson = {
  'timestamp': '2026-05-01T09:00:00Z',
  'status': 401,
  'error': 'Unauthorized',
  'message': 'Token expired',
  'path': '/api/v1/notifications/me',
};

void main() {
  late MockHttpClient httpClient;
  late MockTokenStorage tokenStorage;
  late NotificationRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    httpClient = MockHttpClient();
    tokenStorage = MockTokenStorage();
    repository = NotificationRepository(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    when(() => tokenStorage.getAccessToken()).thenAnswer((_) async => 'acc');
  });

  group('fetchNotifications', () {
    test('returns NotificationPage on 200', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response(
          jsonEncode(_pageJson),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.fetchNotifications(page: 0);

      expect(result.content, hasLength(1));
      expect(result.content[0].id, 1);
      expect(result.content[0].type, NotificationType.confirmation);
      expect(result.content[0].read, isFalse);
      expect(result.content[0].session.classTypeName, 'Spinning 45min');
      expect(result.hasMore, isFalse);
      expect(result.totalPages, 1);
    });

    test('passes page and size in query params', () async {
      Uri? capturedUri;
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        capturedUri = invocation.positionalArguments[0] as Uri;
        return http.Response(
          jsonEncode(_pageJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await repository.fetchNotifications(page: 2, size: 10);

      expect(capturedUri?.queryParameters['page'], '2');
      expect(capturedUri?.queryParameters['size'], '10');
    });

    test('passes unreadOnly when true', () async {
      Uri? capturedUri;
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        capturedUri = invocation.positionalArguments[0] as Uri;
        return http.Response(
          jsonEncode(_pageJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await repository.fetchNotifications(page: 0, unreadOnly: true);

      expect(capturedUri?.queryParameters['unreadOnly'], 'true');
    });

    test('throws ApiException on non-200', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response(
          jsonEncode(_errorJson),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );

      await expectLater(
        () => repository.fetchNotifications(page: 0),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 401)
              .having((e) => e.error, 'error', 'Unauthorized'),
        ),
      );
    });

    test('throws ApiException on non-JSON body', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Internal Server Error', 500));

      await expectLater(
        () => repository.fetchNotifications(page: 0),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });
  });

  group('fetchUnreadCount', () {
    test('returns unread int on 200', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response(
          jsonEncode({'unread': 3}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final count = await repository.fetchUnreadCount();

      expect(count, 3);
    });

    test('throws ApiException on non-200', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response(
          jsonEncode(_errorJson),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );

      await expectLater(
        () => repository.fetchUnreadCount(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });
  });

  group('markRead', () {
    test('calls PATCH /notifications/{id}/read on 200', () async {
      Uri? capturedUri;
      when(
        () => httpClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer((invocation) async {
        capturedUri = invocation.positionalArguments[0] as Uri;
        return http.Response(
          jsonEncode({'updated': 1}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await repository.markRead(42);

      expect(capturedUri?.path, endsWith('/notifications/42/read'));
    });

    test('throws ApiException on non-200', () async {
      when(
        () => httpClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2026-05-01T09:00:00Z',
            'status': 404,
            'error': 'NotFound',
            'message': 'Notification not found',
            'path': '/notifications/99/read',
          }),
          404,
          headers: {'content-type': 'application/json'},
        ),
      );

      await expectLater(
        () => repository.markRead(99),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
    });
  });

  group('markAllRead', () {
    test('calls PATCH /notifications/me/read-all and returns updated count',
        () async {
      Uri? capturedUri;
      when(
        () => httpClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer((invocation) async {
        capturedUri = invocation.positionalArguments[0] as Uri;
        return http.Response(
          jsonEncode({'updated': 3}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final count = await repository.markAllRead();

      expect(capturedUri?.path, endsWith('/notifications/me/read-all'));
      expect(count, 3);
    });

    test('throws ApiException on non-200', () async {
      when(
        () => httpClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response('Internal Server Error', 500),
      );

      await expectLater(
        () => repository.markAllRead(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });
  });

  group('delete', () {
    test('calls DELETE /notifications/{id} on 204', () async {
      Uri? capturedUri;
      when(
        () => httpClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer((invocation) async {
        capturedUri = invocation.positionalArguments[0] as Uri;
        return http.Response('', 204);
      });

      await repository.delete(7);

      expect(capturedUri?.path, endsWith('/notifications/7'));
    });

    test('throws ApiException on non-204', () async {
      when(
        () => httpClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2026-05-01T09:00:00Z',
            'status': 404,
            'error': 'NotFound',
            'message': 'Notification not found',
            'path': '/notifications/99',
          }),
          404,
          headers: {'content-type': 'application/json'},
        ),
      );

      await expectLater(
        () => repository.delete(99),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
    });
  });
}
