import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tfg_frontend/core/exceptions/api_exception.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/notifications/data/models/notification_models.dart';

class NotificationRepository {
  NotificationRepository({
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

  Future<NotificationPage> fetchNotifications({
    required int page,
    int size = 20,
    bool unreadOnly = false,
  }) async {
    final queryParams = <String, String>{
      'page': '$page',
      'size': '$size',
      if (unreadOnly) 'unreadOnly': 'true',
    };

    final response = await _client.get(
      Uri.parse('$_baseUrl/notifications/me').replace(
        queryParameters: queryParams,
      ),
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
          path: '/notifications/me',
        );
      }
    }

    return NotificationPage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<int> fetchUnreadCount() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/notifications/me/unread-count'),
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
          path: '/notifications/me/unread-count',
        );
      }
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['unread'] as int;
  }

  Future<void> markRead(int id) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/notifications/$id/read'),
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
          path: '/notifications/$id/read',
        );
      }
    }
  }

  Future<int> markAllRead() async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/notifications/me/read-all'),
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
          path: '/notifications/me/read-all',
        );
      }
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['updated'] as int;
  }

  Future<void> delete(int id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/notifications/$id'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 204) {
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
          path: '/notifications/$id',
        );
      }
    }
  }
}
