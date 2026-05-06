import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';

class ClassSessionRepository {
  ClassSessionRepository({
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

  Future<ClassSessionPage> fetchSessions({
    int? gymId,
    int? classTypeId,
    int page = 0,
    int size = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/class-sessions').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        if (gymId != null) 'gymId': '$gymId',
        if (classTypeId != null) 'classTypeId': '$classTypeId',
      },
    );

    final response = await _client.get(uri, headers: await _authHeaders());

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ApiException.fromJson(body, response.statusCode);
    }

    return ClassSessionPage.fromJson(body);
  }

  Future<List<ClassSession>> fetchSchedule({
    required DateTime from,
    required DateTime to,
    int? gymId,
  }) async {
    final uri = Uri.parse('$_baseUrl/class-sessions/schedule').replace(
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        if (gymId != null) 'gymId': '$gymId',
      },
    );

    final response = await _client.get(uri, headers: await _authHeaders());

    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw ApiException.fromJson(body as Map<String, dynamic>, response.statusCode);
    }

    return (body as List<dynamic>)
        .map((e) => ClassSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
