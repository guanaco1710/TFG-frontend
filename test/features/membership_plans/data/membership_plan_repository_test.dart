import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/repositories/membership_plan_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeUri extends Fake implements Uri {}

const _plansPageJson = {
  'content': [
    {
      'id': 1,
      'name': 'Basic',
      'description': 'Basic access',
      'priceMonthly': 19.99,
      'classesPerMonth': 8,
      'allowsWaitlist': false,
      'active': true,
    },
    {
      'id': 2,
      'name': 'Premium',
      'description': 'Full access',
      'priceMonthly': 49.99,
      'classesPerMonth': null,
      'allowsWaitlist': true,
      'active': true,
    },
  ],
  'page': 0,
  'size': 100,
  'totalElements': 2,
  'totalPages': 1,
  'hasMore': false,
};

void main() {
  late MockHttpClient httpClient;
  late MockTokenStorage tokenStorage;
  late MembershipPlanRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    httpClient = MockHttpClient();
    tokenStorage = MockTokenStorage();
    repository = MembershipPlanRepository(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    when(() => tokenStorage.getAccessToken()).thenAnswer((_) async => 'acc');
  });

  group('fetchActivePlans', () {
    test('returns list of plans on 200', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode(_plansPageJson),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.fetchActivePlans();

      expect(result.length, 2);
      expect(result[0].name, 'Basic');
      expect(result[1].classesPerMonth, isNull);
      expect(result[1].allowsWaitlist, true);
    });

    test('throws ApiException on non-200 with JSON error body', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2024-05-20T10:00:00Z',
            'status': 403,
            'error': 'Forbidden',
            'message': 'Access denied',
            'path': '/api/v1/membership-plans',
          }),
          403,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.fetchActivePlans(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
    });

    test('throws ApiException on non-200 with non-JSON body', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => repository.fetchActivePlans(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });

    test('requests active=true and size=100 in URL', () async {
      Uri? capturedUri;
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((invocation) async {
        capturedUri = invocation.positionalArguments[0] as Uri;
        return http.Response(
          jsonEncode(_plansPageJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await repository.fetchActivePlans();

      expect(capturedUri!.queryParameters['active'], 'true');
      expect(capturedUri!.queryParameters['size'], '100');
    });
  });
}
