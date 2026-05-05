import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/stats/data/repositories/stats_repository.dart';

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
        'path': '/api/v1/stats/me',
      }),
      status,
      headers: {'content-type': 'application/json'},
    );

const _statsJson = {
  'totalBookings': 42,
  'totalAttended': 38,
  'totalNoShows': 2,
  'totalCancellations': 4,
  'attendanceRate': 0.95,
  'currentStreak': 5,
  'favoriteClassType': 'Spinning 45min',
  'classesBookedThisMonth': 8,
  'classesRemainingThisMonth': 12,
};

void main() {
  late MockHttpClient httpClient;
  late MockTokenStorage tokenStorage;
  late StatsRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    httpClient = MockHttpClient();
    tokenStorage = MockTokenStorage();
    repository = StatsRepository(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    when(
      () => tokenStorage.getAccessToken(),
    ).thenAnswer((_) async => 'access-token');
  });

  group('getMyStats', () {
    test('returns UserStats on 200', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_statsJson));

      final stats = await repository.getMyStats();

      expect(stats.totalBookings, 42);
      expect(stats.totalAttended, 38);
      expect(stats.currentStreak, 5);
      expect(stats.favoriteClassType, 'Spinning 45min');
    });

    test('hits /stats/me endpoint', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_statsJson));

      await repository.getMyStats();

      final captured = verify(
        () => httpClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      expect(
        (captured.first as Uri).toString(),
        'http://localhost:8080/api/v1/stats/me',
      );
    });

    test('sends Authorization header', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_statsJson));

      await repository.getMyStats();

      final captured = verify(
        () => httpClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      final headers = captured.first as Map<String, String>;
      expect(headers['Authorization'], 'Bearer access-token');
    });

    test('omits Authorization when no token', () async {
      when(() => tokenStorage.getAccessToken()).thenAnswer((_) async => null);
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_statsJson));

      await repository.getMyStats();

      final captured = verify(
        () => httpClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      final headers = captured.first as Map<String, String>;
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('throws ApiException on 401', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => _jsonError(401, 'Unauthorized', 'Token expired'),
      );

      expect(
        () => repository.getMyStats(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });

    test('throws ApiException on 404', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => _jsonError(404, 'Not Found', 'Stats not found'),
      );

      expect(
        () => repository.getMyStats(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
    });

    test('parses null classesRemainingThisMonth (unlimited plan)', () async {
      final json = {..._statsJson, 'classesRemainingThisMonth': null};
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(json));

      final stats = await repository.getMyStats();

      expect(stats.classesRemainingThisMonth, isNull);
    });
  });
}
