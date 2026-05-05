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

  Future<List<Subscription>> fetchMySubscriptions() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/subscriptions/me'),
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
          message:
              'Server returned ${response.statusCode}. Check backend logs.',
          path: '/subscriptions/me',
        );
      }
    }

    final bodyStr = response.body.trim();
    if (bodyStr.isEmpty) return [];

    final json = jsonDecode(bodyStr);
    if (json == null) return [];

    return (json as List<dynamic>)
        .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> subscribe({
    required int membershipPlanId,
    required int gymId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/subscriptions'),
      headers: await _authHeaders(),
      body: jsonEncode({'membershipPlanId': membershipPlanId, 'gymId': gymId}),
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
          path: '/subscriptions',
        );
      }
    }
  }

  Future<void> cancelSubscription({required int subscriptionId}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/subscriptions/$subscriptionId/cancel'),
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
          path: '/subscriptions/$subscriptionId/cancel',
        );
      }
    }
  }

  Future<Subscription> upgradeSubscription({
    required int subscriptionId,
    required int newMembershipPlanId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/subscriptions/$subscriptionId/upgrade'),
      headers: await _authHeaders(),
      body: jsonEncode({'newMembershipPlanId': newMembershipPlanId}),
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
          path: '/subscriptions/$subscriptionId/upgrade',
        );
      }
    }

    return Subscription.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
