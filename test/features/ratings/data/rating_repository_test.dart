import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/ratings/data/repositories/rating_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeUri extends Fake implements Uri {}

http.Response _json201(Object body) => http.Response(
  jsonEncode(body),
  201,
  headers: {'content-type': 'application/json'},
);

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
        'path': '/api/v1/ratings',
      }),
      status,
      headers: {'content-type': 'application/json'},
    );

final _ratingJson = {
  'id': 10,
  'score': 5,
  'comment': 'Great class!',
  'ratedAt': '2026-05-01T09:00:00Z',
  'userId': 1,
  'sessionId': 1,
};

Map<String, dynamic> _pageJson({
  List<Map<String, dynamic>>? content,
  bool hasMore = false,
}) => {
  'content': content ?? [_ratingJson],
  'page': 0,
  'size': 20,
  'totalElements': content?.length ?? 1,
  'totalPages': 1,
  'hasMore': hasMore,
};

void main() {
  late MockHttpClient httpClient;
  late MockTokenStorage tokenStorage;
  late RatingRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    httpClient = MockHttpClient();
    tokenStorage = MockTokenStorage();
    repository = RatingRepository(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    when(
      () => tokenStorage.getAccessToken(),
    ).thenAnswer((_) async => 'access-token');
  });

  group('submitRating', () {
    test('returns Rating on 201', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _json201(_ratingJson));

      final rating = await repository.submitRating(
        sessionId: 1,
        score: 5,
        comment: 'Great!',
      );

      expect(rating.id, 10);
      expect(rating.score, 5);
    });

    test('hits POST /ratings URL', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _json201(_ratingJson));

      await repository.submitRating(sessionId: 1, score: 5);

      final captured = verify(
        () => httpClient.post(
          captureAny(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured;
      expect((captured.first as Uri).path, '/api/v1/ratings');
    });

    test('sends correct request body with comment', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _json201(_ratingJson));

      await repository.submitRating(sessionId: 1, score: 4, comment: 'Nice');

      final captured = verify(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      final body = jsonDecode(captured.first as String) as Map<String, dynamic>;
      expect(body['sessionId'], 1);
      expect(body['score'], 4);
      expect(body['comment'], 'Nice');
    });

    test('omits comment from body when null', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _json201(_ratingJson));

      await repository.submitRating(sessionId: 1, score: 5);

      final captured = verify(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      final body = jsonDecode(captured.first as String) as Map<String, dynamic>;
      expect(body.containsKey('comment'), isFalse);
    });

    test('sends Authorization header', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => _json201(_ratingJson));

      await repository.submitRating(sessionId: 1, score: 5);

      final captured = verify(
        () => httpClient.post(
          any(),
          headers: captureAny(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured;
      expect(
        (captured.first as Map<String, String>)['Authorization'],
        'Bearer access-token',
      );
    });

    test('throws ApiException on 409', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => _jsonError(409, 'Conflict', 'Already rated'),
      );

      expect(
        () => repository.submitRating(sessionId: 1, score: 5),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)),
      );
    });
  });

  group('fetchMyRatings', () {
    test('returns RatingPage on 200', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson()));

      final page = await repository.fetchMyRatings();

      expect(page.content.length, 1);
      expect(page.content.first.score, 5);
    });

    test('hits GET /ratings/me URL', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson()));

      await repository.fetchMyRatings();

      final captured = verify(
        () => httpClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      expect((captured.first as Uri).path, '/api/v1/ratings/me');
    });

    test('sends page and size params', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson()));

      await repository.fetchMyRatings(page: 1, size: 10);

      final captured = verify(
        () => httpClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final uri = captured.first as Uri;
      expect(uri.queryParameters['page'], '1');
      expect(uri.queryParameters['size'], '10');
    });

    test('sends Authorization header', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _jsonOk(_pageJson()));

      await repository.fetchMyRatings();

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
        () => repository.fetchMyRatings(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });

    test('returns empty page', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => _jsonOk(_pageJson(content: [])),
      );

      final page = await repository.fetchMyRatings();

      expect(page.content, isEmpty);
    });
  });
}
