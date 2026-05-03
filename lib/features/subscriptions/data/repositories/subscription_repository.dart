import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart';

class SubscriptionRepository {
  SubscriptionRepository({
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

  /// Returns the active subscription for the current user, or null when the
  /// user has no subscription (200 with null body).
  Future<Subscription?> fetchMySubscription() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/subscriptions/me'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 204) return null;

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
          message: 'Server returned ${response.statusCode}. Check backend logs.',
          path: '/subscriptions/me',
        );
      }
    }

    final bodyStr = response.body.trim();
    if (bodyStr.isEmpty || bodyStr == 'null') return null;

    final json = jsonDecode(bodyStr);
    if (json == null) return null;

    return Subscription.fromJson(json as Map<String, dynamic>);
  }
}
