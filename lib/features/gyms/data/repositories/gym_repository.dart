import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/gyms/data/models/gym_models.dart';

class GymRepository {
  GymRepository({
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

  Future<GymPage> fetchGyms({int page = 0, int size = 20}) async {
    final uri = Uri.parse('$_baseUrl/gyms').replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );

    final response = await _client.get(uri, headers: await _authHeaders());

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(body, response.statusCode);
    }

    return GymPage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
