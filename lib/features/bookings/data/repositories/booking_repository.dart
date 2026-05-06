import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/core/exceptions/api_exception.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';

class BookingRepository {
  BookingRepository({
    required http.Client httpClient,
    required TokenStorage tokenStorage,
    required String baseUrl,
  }) : _client = httpClient,
       _tokenStorage = tokenStorage,
       _baseUrl = baseUrl;

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Booking> book({required int classSessionId}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/bookings'),
      headers: await _authHeaders(),
      body: jsonEncode({'sessionId': classSessionId}),
    );

    if (response.statusCode != 201) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException.fromJson(body, response.statusCode);
      } on ApiException {
        rethrow;
      } catch (_) {
        throw ApiException(
          status: response.statusCode,
          error: 'Server error',
          message: 'Server returned ${response.statusCode}.',
          path: '/bookings',
        );
      }
    }

    return Booking.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<BookingPage> fetchMyBookings({
    required int page,
    int size = 20,
    BookingStatus? status,
  }) async {
    final queryParams = <String, String>{
      'page': '$page',
      'size': '$size',
      if (status != null) 'status': status.toJson(),
    };

    final response = await _client.get(
      Uri.parse('$_baseUrl/bookings/me').replace(queryParameters: queryParams),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException.fromJson(body, response.statusCode);
      } on ApiException {
        rethrow;
      } catch (_) {
        throw ApiException(
          status: response.statusCode,
          error: 'Server error',
          message: 'Server returned ${response.statusCode}.',
          path: '/bookings/me',
        );
      }
    }

    return BookingPage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Booking> cancelBooking({required int bookingId}) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/bookings/$bookingId/cancel'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException.fromJson(body, response.statusCode);
      } on ApiException {
        rethrow;
      } catch (_) {
        throw ApiException(
          status: response.statusCode,
          error: 'Server error',
          message: 'Server returned ${response.statusCode}.',
          path: '/bookings/$bookingId/cancel',
        );
      }
    }

    return Booking.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
