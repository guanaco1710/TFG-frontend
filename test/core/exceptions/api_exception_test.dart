import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_frontend/core/exceptions/api_exception.dart';

void main() {
  group('ApiException', () {
    test('fromJson parses error envelope', () {
      final json = {
        'timestamp': '2024-05-20T10:00:00Z',
        'status': 401,
        'error': 'Unauthorized',
        'message': 'Invalid credentials',
        'path': '/api/v1/auth/login',
      };
      final ex = ApiException.fromJson(json, 401);
      expect(ex.status, 401);
      expect(ex.error, 'Unauthorized');
      expect(ex.message, 'Invalid credentials');
      expect(ex.path, '/api/v1/auth/login');
    });

    test('fromJson defaults missing fields to empty string', () {
      final ex = ApiException.fromJson({}, 500);
      expect(ex.status, 500);
      expect(ex.error, '');
      expect(ex.message, '');
      expect(ex.path, '');
    });

    test('toString includes status and message', () {
      const ex = ApiException(
        status: 401,
        error: 'Unauthorized',
        message: 'Invalid credentials',
        path: '/api/v1/auth/login',
      );
      expect(ex.toString(), contains('401'));
      expect(ex.toString(), contains('Invalid credentials'));
    });

    test('is an Exception', () {
      const ex = ApiException(
        status: 500,
        error: 'InternalServerError',
        message: 'Something went wrong',
        path: '/api/v1/test',
      );
      expect(ex, isA<Exception>());
    });
  });
}
