import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/ratings/data/models/rating_models.dart';
import 'package:tfg_frontend/features/ratings/data/repositories/rating_repository.dart';
import 'package:tfg_frontend/features/ratings/presentation/providers/rating_provider.dart';

class MockRatingRepository extends Mock implements RatingRepository {}

Rating _makeRating({int id = 10, int score = 5, int sessionId = 1}) => Rating(
  id: id,
  score: score,
  comment: null,
  ratedAt: '2026-05-01T09:00:00Z',
  userId: 1,
  sessionId: sessionId,
);

RatingPage _makePage(List<Rating> ratings) => RatingPage(
  content: ratings,
  page: 0,
  size: 200,
  totalElements: ratings.length,
  totalPages: 1,
  hasMore: false,
);

void main() {
  late MockRatingRepository repo;
  late RatingProvider provider;

  setUp(() {
    repo = MockRatingRepository();
    provider = RatingProvider(repository: repo);
  });

  test('initial state is initial', () {
    expect(provider.state, RatingLoadState.initial);
    expect(provider.ratedSessionIds, isEmpty);
    expect(provider.errorMessage, isNull);
    expect(provider.submitError, isNull);
  });

  group('loadMyRatings', () {
    test('transitions to loaded', () async {
      when(
        () => repo.fetchMyRatings(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => _makePage([_makeRating(sessionId: 5)]));

      await provider.loadMyRatings();

      expect(provider.state, RatingLoadState.loaded);
    });

    test('populates ratedSessionIds from content', () async {
      final ratings = [
        _makeRating(sessionId: 1),
        _makeRating(id: 2, sessionId: 3),
      ];
      when(
        () => repo.fetchMyRatings(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => _makePage(ratings));

      await provider.loadMyRatings();

      expect(provider.ratedSessionIds, containsAll([1, 3]));
      expect(provider.ratedSessionIds.length, 2);
    });

    test('sets errorMessage on ApiException', () async {
      when(
        () => repo.fetchMyRatings(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenThrow(
        const ApiException(
          status: 401,
          error: 'Unauthorized',
          message: 'Token expired',
          path: '/ratings/me',
        ),
      );

      await provider.loadMyRatings();

      expect(provider.state, RatingLoadState.error);
      expect(provider.errorMessage, 'Token expired');
    });

    test('state error on generic exception', () async {
      when(
        () => repo.fetchMyRatings(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenThrow(Exception('network error'));

      await provider.loadMyRatings();

      expect(provider.state, RatingLoadState.error);
      expect(provider.errorMessage, isNotNull);
    });

    test('clears previous error on successful reload', () async {
      var calls = 0;
      when(
        () => repo.fetchMyRatings(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('fail');
        return _makePage([]);
      });

      await provider.loadMyRatings();
      expect(provider.state, RatingLoadState.error);

      await provider.loadMyRatings();
      expect(provider.state, RatingLoadState.loaded);
      expect(provider.errorMessage, isNull);
    });
  });

  group('isRated', () {
    test('returns false for unrated session', () {
      expect(provider.isRated(99), isFalse);
    });

    test('returns true after loadMyRatings contains sessionId', () async {
      when(
        () => repo.fetchMyRatings(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => _makePage([_makeRating(sessionId: 7)]));

      await provider.loadMyRatings();

      expect(provider.isRated(7), isTrue);
      expect(provider.isRated(8), isFalse);
    });
  });

  group('submitRating', () {
    test('returns Rating on success', () async {
      when(
        () => repo.submitRating(
          sessionId: any(named: 'sessionId'),
          score: any(named: 'score'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => _makeRating(sessionId: 2));

      final result = await provider.submitRating(sessionId: 2, score: 5);

      expect(result, isNotNull);
      expect(result!.sessionId, 2);
    });

    test('adds sessionId to ratedSessionIds on success', () async {
      when(
        () => repo.submitRating(
          sessionId: any(named: 'sessionId'),
          score: any(named: 'score'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => _makeRating(sessionId: 2));

      await provider.submitRating(sessionId: 2, score: 5);

      expect(provider.isRated(2), isTrue);
    });

    test('passes comment to repository', () async {
      when(
        () => repo.submitRating(
          sessionId: any(named: 'sessionId'),
          score: any(named: 'score'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => _makeRating());

      await provider.submitRating(sessionId: 1, score: 4, comment: 'Nice');

      verify(
        () => repo.submitRating(sessionId: 1, score: 4, comment: 'Nice'),
      ).called(1);
    });

    test('returns null and sets submitError on ApiException', () async {
      when(
        () => repo.submitRating(
          sessionId: any(named: 'sessionId'),
          score: any(named: 'score'),
          comment: any(named: 'comment'),
        ),
      ).thenThrow(
        const ApiException(
          status: 409,
          error: 'Conflict',
          message: 'Already rated',
          path: '/ratings',
        ),
      );

      final result = await provider.submitRating(sessionId: 1, score: 5);

      expect(result, isNull);
      expect(provider.submitError, 'Already rated');
    });

    test('does not add sessionId on failure', () async {
      when(
        () => repo.submitRating(
          sessionId: any(named: 'sessionId'),
          score: any(named: 'score'),
          comment: any(named: 'comment'),
        ),
      ).thenThrow(Exception('network'));

      await provider.submitRating(sessionId: 1, score: 5);

      expect(provider.isRated(1), isFalse);
    });

    test('clears submitError on next successful submit', () async {
      var calls = 0;
      when(
        () => repo.submitRating(
          sessionId: any(named: 'sessionId'),
          score: any(named: 'score'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('fail');
        return _makeRating(sessionId: 2);
      });

      await provider.submitRating(sessionId: 1, score: 5);
      expect(provider.submitError, isNotNull);

      await provider.submitRating(sessionId: 2, score: 5);
      expect(provider.submitError, isNull);
    });
  });
}
