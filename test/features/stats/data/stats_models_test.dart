import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/features/stats/data/models/stats_models.dart';

void main() {
  const stats = UserStats(
    totalBookings: 42,
    totalAttended: 38,
    totalNoShows: 2,
    totalCancellations: 4,
    attendanceRate: 0.95,
    currentStreak: 5,
    favoriteClassType: 'Spinning 45min',
    classesBookedThisMonth: 8,
    classesRemainingThisMonth: 12,
  );

  final statsJson = {
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

  group('UserStats.fromJson', () {
    test('parses all fields', () {
      final parsed = UserStats.fromJson(statsJson);
      expect(parsed.totalBookings, 42);
      expect(parsed.totalAttended, 38);
      expect(parsed.totalNoShows, 2);
      expect(parsed.totalCancellations, 4);
      expect(parsed.attendanceRate, closeTo(0.95, 0.001));
      expect(parsed.currentStreak, 5);
      expect(parsed.favoriteClassType, 'Spinning 45min');
      expect(parsed.classesBookedThisMonth, 8);
      expect(parsed.classesRemainingThisMonth, 12);
    });

    test('parses null favoriteClassType', () {
      final json = {...statsJson, 'favoriteClassType': null};
      expect(UserStats.fromJson(json).favoriteClassType, isNull);
    });

    test('parses null classesRemainingThisMonth (unlimited plan)', () {
      final json = {...statsJson, 'classesRemainingThisMonth': null};
      expect(UserStats.fromJson(json).classesRemainingThisMonth, isNull);
    });

    test('coerces int attendanceRate to double', () {
      final json = {...statsJson, 'attendanceRate': 1};
      expect(UserStats.fromJson(json).attendanceRate, 1.0);
      expect(UserStats.fromJson(json).attendanceRate, isA<double>());
    });
  });

  group('UserStats.toJson', () {
    test('round-trips correctly', () {
      final json = stats.toJson();
      expect(json['totalBookings'], 42);
      expect(json['attendanceRate'], 0.95);
      expect(json['favoriteClassType'], 'Spinning 45min');
    });
  });

  group('UserStats equality', () {
    test('equal for same data', () {
      const other = UserStats(
        totalBookings: 42,
        totalAttended: 38,
        totalNoShows: 2,
        totalCancellations: 4,
        attendanceRate: 0.95,
        currentStreak: 5,
        favoriteClassType: 'Spinning 45min',
        classesBookedThisMonth: 8,
        classesRemainingThisMonth: 12,
      );
      expect(stats, equals(other));
      expect(stats.hashCode, equals(other.hashCode));
    });

    test('not equal for different streak', () {
      const other = UserStats(
        totalBookings: 42,
        totalAttended: 38,
        totalNoShows: 2,
        totalCancellations: 4,
        attendanceRate: 0.95,
        currentStreak: 99,
        classesBookedThisMonth: 8,
      );
      expect(stats, isNot(equals(other)));
    });

    test('identical returns true', () {
      expect(stats == stats, isTrue);
    });
  });
}
