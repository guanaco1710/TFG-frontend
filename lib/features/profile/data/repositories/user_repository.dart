import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/profile/data/models/user_profile_models.dart';

class UserRepository {
  UserRepository({
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

  Future<UserProfile> getMe() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: await _authHeaders(),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ApiException.fromJson(body, response.statusCode);
    }

    return UserProfile.fromJson(body);
  }

  Future<UserProfile> updateMe({
    String? name,
    String? phone,
    String? specialty,
  }) async {
    final payload = <String, dynamic>{
      'name': ?name,
      'phone': ?phone,
      'specialty': ?specialty,
    };

    final response = await _client.patch(
      Uri.parse('$_baseUrl/users/me'),
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ApiException.fromJson(body, response.statusCode);
    }

    return UserProfile.fromJson(body);
  }
}
