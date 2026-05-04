import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/models/membership_plan_models.dart';

class MembershipPlanRepository {
  MembershipPlanRepository({
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

  Future<List<MembershipPlan>> fetchActivePlans() async {
    final uri = Uri.parse(
      '$_baseUrl/membership-plans',
    ).replace(queryParameters: {'active': 'true', 'size': '100'});

    final response = await _client.get(uri, headers: await _authHeaders());

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
          path: '/membership-plans',
        );
      }
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['content'] as List<dynamic>)
        .map((e) => MembershipPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
