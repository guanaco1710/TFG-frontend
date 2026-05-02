import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';

class AuthRepository {
  AuthRepository({
    required http.Client httpClient,
    required TokenStorage tokenStorage,
    required String baseUrl,
  }) : _client = httpClient,
       _tokenStorage = tokenStorage,
       _baseUrl = baseUrl;

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ApiException.fromJson(body, response.statusCode);
    }

    final authResponse = AuthResponse.fromJson(body);
    await _tokenStorage.saveTokens(
      authResponse.tokens.accessToken,
      authResponse.tokens.refreshToken,
    );
    return authResponse;
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    UserRole? role,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    };
    if (role != null) payload['role'] = role.toJson();

    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw ApiException.fromJson(body, response.statusCode);
    }

    final authResponse = AuthResponse.fromJson(body);
    await _tokenStorage.saveTokens(
      authResponse.tokens.accessToken,
      authResponse.tokens.refreshToken,
    );
    return authResponse;
  }

  Future<AuthResponse> refresh({required String refreshToken}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: _jsonHeaders,
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ApiException.fromJson(body, response.statusCode);
    }

    final authResponse = AuthResponse.fromJson(body);
    await _tokenStorage.saveTokens(
      authResponse.tokens.accessToken,
      authResponse.tokens.refreshToken,
    );
    return authResponse;
  }

  Future<void> logout({required String refreshToken}) async {
    await _client.post(
      Uri.parse('$_baseUrl/auth/logout'),
      headers: _jsonHeaders,
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    await _tokenStorage.clearTokens();
  }

  /// Attempts to restore a previous session from stored tokens.
  ///
  /// Returns the [AuthUser] if a valid session could be restored (either the
  /// access token is present, or a stored refresh token was used to obtain a
  /// new pair). Returns null when there are no usable tokens.
  Future<AuthUser?> restoreSession() async {
    final accessToken = await _tokenStorage.getAccessToken();
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (accessToken != null) {
      return null;
    }

    if (refreshToken == null) {
      return null;
    }

    try {
      final authResponse = await refresh(refreshToken: refreshToken);
      return authResponse.user;
    } on ApiException {
      await _tokenStorage.clearTokens();
      return null;
    }
  }
}
