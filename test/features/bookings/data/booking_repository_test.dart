import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeUri extends Fake implements Uri {}

const _bookingJson = {
  'id': 42,
  'classSession': {
    'id': 1,
    'classType': {'id': 1, 'name': 'Spinning 45min', 'durationMinutes': 45},
    'gym': {'id': 1, 'name': 'GymBook Central', 'city': 'Madrid'},
    'startTime': '2024-06-01T09:00:00Z',
  },
  'status': 'CONFIRMED',
  'waitlistPosition': null,
  'bookedAt': '2024-05-20T10:00:00Z',
};

const _waitlistedBookingJson = {
  'id': 43,
  'classSession': {
    'id': 1,
    'classType': {'id': 1, 'name': 'Spinning 45min', 'durationMinutes': 45},
    'gym': {'id': 1, 'name': 'GymBook Central', 'city': 'Madrid'},
    'startTime': '2024-06-01T09:00:00Z',
  },
  'status': 'WAITLISTED',
  'waitlistPosition': 3,
  'bookedAt': '2024-05-20T10:01:00Z',
};

const _pageJson = {
  'content': [_bookingJson],
  'page': 0,
  'size': 20,
  'totalElements': 1,
  'totalPages': 1,
  'hasMore': false,
};

const _errorJson = {
  'timestamp': '2024-05-20T10:00:00Z',
  'status': 409,
  'error': 'AlreadyBooked',
  'message': 'You already have a booking for this session',
  'path': '/api/v1/bookings',
};

void main() {
  late MockHttpClient httpClient;
  late MockTokenStorage tokenStorage;
  late BookingRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    httpClient = MockHttpClient();
    tokenStorage = MockTokenStorage();
    repository = BookingRepository(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    when(() => tokenStorage.getAccessToken()).thenAnswer((_) async => 'acc');
  });

  group('book', () {
    test('returns Booking on 201', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode(_bookingJson),
          201,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.book(classSessionId: 1);

      expect(result.id, 42);
      expect(result.status, BookingStatus.confirmed);
      expect(result.waitlistPosition, isNull);
    });

    test('returns waitlisted Booking on 201 when session is full', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode(_waitlistedBookingJson),
          201,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.book(classSessionId: 1);

      expect(result.status, BookingStatus.waitlisted);
      expect(result.waitlistPosition, 3);
    });

    test('throws ApiException on 409 AlreadyBooked', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode(_errorJson),
          409,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.book(classSessionId: 1),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.error, 'error', 'AlreadyBooked'),
        ),
      );
    });

    test('throws ApiException on 422 SessionNotBookable', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2024-05-20T10:00:00Z',
            'status': 422,
            'error': 'SessionNotBookable',
            'message': 'Session is cancelled',
            'path': '/api/v1/bookings',
          }),
          422,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.book(classSessionId: 1),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 422)),
      );
    });

    test('throws ApiException on non-JSON error body', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => repository.book(classSessionId: 1),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });
  });

  group('fetchMyBookings', () {
    test('returns BookingPage on 200', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode(_pageJson),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.fetchMyBookings(page: 0);

      expect(result.content, hasLength(1));
      expect(result.content[0].id, 42);
      expect(result.hasMore, false);
    });

    test('passes status filter in query params', () async {
      Uri? capturedUri;
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((invocation) async {
        capturedUri = invocation.positionalArguments[0] as Uri;
        return http.Response(
          jsonEncode(_pageJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await repository.fetchMyBookings(
        page: 0,
        status: BookingStatus.confirmed,
      );

      expect(capturedUri?.queryParameters['status'], 'CONFIRMED');
    });

    test('passes page and size in query params', () async {
      Uri? capturedUri;
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((invocation) async {
        capturedUri = invocation.positionalArguments[0] as Uri;
        return http.Response(
          jsonEncode(_pageJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await repository.fetchMyBookings(page: 2, size: 10);

      expect(capturedUri?.queryParameters['page'], '2');
      expect(capturedUri?.queryParameters['size'], '10');
    });

    test('throws ApiException on non-200', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2024-05-20T10:00:00Z',
            'status': 401,
            'error': 'Unauthorized',
            'message': 'Token expired',
            'path': '/api/v1/bookings/me',
          }),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.fetchMyBookings(page: 0),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });

    test('throws ApiException on non-JSON body', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => repository.fetchMyBookings(page: 0),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });
  });

  group('cancelBooking', () {
    test('returns updated Booking on 200', () async {
      final cancelledJson = Map<String, dynamic>.from(_bookingJson)
        ..['status'] = 'CANCELLED';

      when(
        () => httpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode(cancelledJson),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.cancelBooking(bookingId: 42);

      expect(result.id, 42);
      expect(result.status, BookingStatus.cancelled);
    });

    test('throws ApiException on 404 BookingNotFound', () async {
      when(
        () => httpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2024-05-20T10:00:00Z',
            'status': 404,
            'error': 'BookingNotFound',
            'message': 'Booking with id 42 not found',
            'path': '/api/v1/bookings/42/cancel',
          }),
          404,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.cancelBooking(bookingId: 42),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
    });

    test('throws ApiException on 403 Forbidden', () async {
      when(
        () => httpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2024-05-20T10:00:00Z',
            'status': 403,
            'error': 'Forbidden',
            'message': 'Not allowed',
            'path': '/api/v1/bookings/42/cancel',
          }),
          403,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.cancelBooking(bookingId: 42),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
    });

    test('throws ApiException on non-JSON body', () async {
      when(
        () => httpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => repository.cancelBooking(bookingId: 42),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });
  });
}
