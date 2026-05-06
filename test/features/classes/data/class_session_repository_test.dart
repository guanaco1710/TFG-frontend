import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeUri extends Fake implements Uri {}

http.Response _jsonOk(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response _jsonError(int status, String error, String message) =>
    http.Response(
      jsonEncode({
        'timestamp': '2024-05-20T10:00:00Z',
        'status': status,
        'error': error,
        'message': message,
        'path': '/api/v1/class-sessions',
      }),
      status,
      headers: {'content-type': 'application/json'},
    );

final _sessionJson = {
  'id': 1,
  'classType': {'id': 1, 'name': 'Spinning 45min', 'level': 'INTERMEDIATE'},
  'gym': {
    'id': 1,
    'name': 'GymBook Central',
    'address': 'Calle Mayor 1',
    'city': 'Madrid',
  },
  'instructor': {'id': 2, 'name': 'Jane Doe', 'specialty': 'Cycling'},
  'startTime': '2024-06-01T09:00:00',
  'durationMinutes': 45,
  'maxCapacity': 20,
  'room': 'Studio A',
  'status': 'SCHEDULED',
  'confirmedCount': 15,
  'availableSpots': 5,
};

Map<String, dynamic> _pageJson({
  List<Map<String, dynamic>>? content,
  int page = 0,
  int size = 20,
  int totalElements = 1,
  int totalPages = 1,
  bool hasMore = false,
}) => {
  'content': content ?? [_sessionJson],
  'page': page,
  'size': size,
  'totalElements': totalElements,
  'totalPages': totalPages,
  'hasMore': hasMore,
};

void main() {
  late MockHttpClient httpClient;
  late MockTokenStorage tokenStorage;
  late ClassSessionRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    httpClient = MockHttpClient();
    tokenStorage = MockTokenStorage();
    repository = ClassSessionRepository(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    when(
      () => tokenStorage.getAccessToken(),
    ).thenAnswer((_) async => 'access-token');
  });

  group('fetchSessions', () {
    test('returns ClassSessionPage on 200', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson()));

      final page = await repository.fetchSessions();

      expect(page.content.length, 1);
      expect(page.content.first.classType.name, 'Spinning 45min');
      expect(page.hasMore, isFalse);
    });

    test('hits /class-sessions with default page/size params', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson()));

      await repository.fetchSessions();

      final captured = verify(
        () => httpClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final uri = captured.first as Uri;
      expect(uri.path, '/api/v1/class-sessions');
      expect(uri.queryParameters['page'], '0');
      expect(uri.queryParameters['size'], '20');
    });

    test('includes gymId when provided', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson()));

      await repository.fetchSessions(gymId: 5);

      final captured = verify(
        () => httpClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final uri = captured.first as Uri;
      expect(uri.queryParameters['gymId'], '5');
    });

    test('includes classTypeId when provided', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson()));

      await repository.fetchSessions(classTypeId: 3);

      final captured = verify(
        () => httpClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final uri = captured.first as Uri;
      expect(uri.queryParameters['classTypeId'], '3');
    });

    test('omits gymId/classTypeId when not provided', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson()));

      await repository.fetchSessions();

      final captured = verify(
        () => httpClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final uri = captured.first as Uri;
      expect(uri.queryParameters.containsKey('gymId'), isFalse);
      expect(uri.queryParameters.containsKey('classTypeId'), isFalse);
    });

    test('passes custom page number', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson(page: 2)));

      await repository.fetchSessions(page: 2);

      final captured = verify(
        () => httpClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      expect((captured.first as Uri).queryParameters['page'], '2');
    });

    test('sends Authorization header', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson()));

      await repository.fetchSessions();

      final captured = verify(
        () => httpClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      expect(
        (captured.first as Map<String, String>)['Authorization'],
        'Bearer access-token',
      );
    });

    test('throws ApiException on 401', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => _jsonError(401, 'Unauthorized', 'Token expired'),
      );

      expect(
        () => repository.fetchSessions(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });

    test('hasMore true when more pages exist', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => _jsonOk(_pageJson(hasMore: true, totalElements: 40)),
      );

      final page = await repository.fetchSessions();

      expect(page.hasMore, isTrue);
    });

    test('returns empty content list', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            _jsonOk(_pageJson(content: [], totalElements: 0, totalPages: 0)),
      );

      final page = await repository.fetchSessions();

      expect(page.content, isEmpty);
      expect(page.totalElements, 0);
    });
  });

  group('fetchRoster', () {
    final rosterJson = [
      {'userId': 1, 'userFullName': 'Jane Doe', 'userEmail': 'jane@example.com'},
      {'userId': 2, 'userFullName': 'Carlos M.', 'userEmail': 'carlos@gym.es'},
    ];

    test('returns list of RosterEntry on 200', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(rosterJson));

      final entries = await repository.fetchRoster(5);

      expect(entries.length, 2);
      expect(entries.first.userFullName, 'Jane Doe');
      expect(entries.last.userId, 2);
    });

    test('hits /class-sessions/{id}/bookings URL', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(rosterJson));

      await repository.fetchRoster(7);

      final captured = verify(
        () => httpClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      expect((captured.first as Uri).path, '/api/v1/class-sessions/7/bookings');
    });

    test('sends Authorization header', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(rosterJson));

      await repository.fetchRoster(1);

      final captured = verify(
        () => httpClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      expect(
        (captured.first as Map<String, String>)['Authorization'],
        'Bearer access-token',
      );
    });

    test('throws ApiException on 401', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => _jsonError(401, 'Unauthorized', 'Token expired'),
      );

      expect(
        () => repository.fetchRoster(1),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });

    test('returns empty list when no attendees', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(<dynamic>[]));

      final entries = await repository.fetchRoster(1);

      expect(entries, isEmpty);
    });
  });
}
