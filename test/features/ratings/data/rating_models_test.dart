import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/features/ratings/data/models/rating_models.dart';

final _ratingJson = {
  'id': 10,
  'score': 5,
  'comment': 'Great class!',
  'ratedAt': '2026-05-01T09:00:00Z',
  'userId': 1,
  'sessionId': 1,
};

void main() {
  group('Rating', () {
    test('fromJson parses all fields', () {
      final r = Rating.fromJson(_ratingJson);
      expect(r.id, 10);
      expect(r.score, 5);
      expect(r.comment, 'Great class!');
      expect(r.ratedAt, '2026-05-01T09:00:00Z');
      expect(r.userId, 1);
      expect(r.sessionId, 1);
    });

    test('fromJson parses null comment', () {
      final r = Rating.fromJson({..._ratingJson, 'comment': null});
      expect(r.comment, isNull);
    });

    test('toJson round-trips', () {
      final r = Rating.fromJson(_ratingJson);
      final json = r.toJson();
      expect(json['id'], 10);
      expect(json['score'], 5);
      expect(json['comment'], 'Great class!');
      expect(json['sessionId'], 1);
    });

    test('toJson with null comment', () {
      const r = Rating(
        id: 1,
        score: 3,
        comment: null,
        ratedAt: '2026-05-01T09:00:00Z',
        userId: 1,
        sessionId: 2,
      );
      expect(r.toJson()['comment'], isNull);
    });
  });

  group('RatingPage', () {
    test('fromJson parses page and ratings', () {
      final page = RatingPage.fromJson({
        'content': [_ratingJson],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
        'hasMore': false,
      });
      expect(page.content.length, 1);
      expect(page.content.first.score, 5);
      expect(page.hasMore, isFalse);
    });

    test('fromJson parses empty content', () {
      final page = RatingPage.fromJson({
        'content': [],
        'page': 0,
        'size': 20,
        'totalElements': 0,
        'totalPages': 0,
        'hasMore': false,
      });
      expect(page.content, isEmpty);
    });
  });
}
