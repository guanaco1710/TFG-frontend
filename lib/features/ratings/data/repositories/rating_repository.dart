import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/ratings/data/models/rating_models.dart';

class RatingRepository {
  RatingRepository({
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

  Future<Rating> submitRating({
    required int sessionId,
    required int score,
    String? comment,
  }) async {
    final uri = Uri.parse('$_baseUrl/ratings');
    final body = <String, dynamic>{
      'sessionId': sessionId,
      'score': score,
      if (comment != null) 'comment': comment,
    };

    final response = await _client.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw ApiException.fromJson(responseBody, response.statusCode);
    }

    return Rating.fromJson(responseBody);
  }

  Future<RatingPage> fetchMyRatings({int page = 0, int size = 200}) async {
    final uri = Uri.parse('$_baseUrl/ratings/me').replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );

    final response = await _client.get(uri, headers: await _authHeaders());

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ApiException.fromJson(body, response.statusCode);
    }

    return RatingPage.fromJson(body);
  }
}
