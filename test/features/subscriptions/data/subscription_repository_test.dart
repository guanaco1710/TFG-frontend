import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeUri extends Fake implements Uri {}

const _subscriptionJson = {
  'id': 7,
  'plan': {'id': 2, 'name': 'Premium Monthly', 'priceMonthly': 49.99},
  'gym': {
    'id': 1,
    'name': 'GymBook Central',
    'address': 'Calle Mayor 1',
    'city': 'Madrid',
  },
  'status': 'ACTIVE',
  'startDate': '2024-05-01',
  'renewalDate': '2024-06-01',
  'endDate': null,
  'classesUsedThisMonth': 5,
  'classesRemainingThisMonth': 7,
  'pendingCancellation': false,
  'cancelledAt': null,
  'pendingPlan': null,
};

void main() {
  late MockHttpClient httpClient;
  late MockTokenStorage tokenStorage;
  late SubscriptionRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    httpClient = MockHttpClient();
    tokenStorage = MockTokenStorage();
    repository = SubscriptionRepository(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    when(() => tokenStorage.getAccessToken()).thenAnswer((_) async => 'acc');
  });

  group('fetchMySubscriptions', () {
    test('returns list of Subscriptions on 200 with array body', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode([_subscriptionJson]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.fetchMySubscriptions();

      expect(result, hasLength(1));
      expect(result[0].id, 7);
      expect(result[0].plan.name, 'Premium Monthly');
      expect(result[0].pendingCancellation, false);
      expect(result[0].pendingPlan, isNull);
    });

    test('returns empty list on 200 with empty array', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.fetchMySubscriptions();

      expect(result, isEmpty);
    });

    test('returns empty list on 200 with empty body', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('', 200));

      final result = await repository.fetchMySubscriptions();

      expect(result, isEmpty);
    });

    test('returns empty list on 200 with JSON null body', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('null', 200));

      final result = await repository.fetchMySubscriptions();

      expect(result, isEmpty);
    });

    test('throws ApiException on non-200 with JSON error body', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2024-05-20T10:00:00Z',
            'status': 401,
            'error': 'Unauthorized',
            'message': 'Token expired',
            'path': '/api/v1/subscriptions/me',
          }),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.fetchMySubscriptions(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });

    test('throws ApiException on non-200 with non-JSON body', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => repository.fetchMySubscriptions(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });

    test('parses pendingPlan when present', () async {
      final withPendingPlan = Map<String, dynamic>.from(_subscriptionJson)
        ..['pendingPlan'] = {
          'id': 3,
          'name': 'Premium',
          'priceMonthly': 49.99,
        };

      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode([withPendingPlan]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.fetchMySubscriptions();

      expect(result[0].pendingPlan, isNotNull);
      expect(result[0].pendingPlan!.name, 'Premium');
    });
  });

  group('subscribe', () {
    test('completes successfully on 201', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('', 201));

      await expectLater(
        repository.subscribe(membershipPlanId: 2, gymId: 1),
        completes,
      );
    });

    test('throws ApiException on non-201 with JSON error body', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2024-05-20T10:00:00Z',
            'status': 409,
            'error': 'Conflict',
            'message': 'Already subscribed',
            'path': '/api/v1/subscriptions',
          }),
          409,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.subscribe(membershipPlanId: 2, gymId: 1),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)),
      );
    });

    test('throws ApiException on non-201 with non-JSON body', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => repository.subscribe(membershipPlanId: 2, gymId: 1),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });
  });

  group('upgradeSubscription', () {
    test('returns updated Subscription on 200', () async {
      final upgraded = Map<String, dynamic>.from(_subscriptionJson)
        ..['pendingPlan'] = {
          'id': 3,
          'name': 'Premium',
          'priceMonthly': 49.99,
        };

      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode(upgraded),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await repository.upgradeSubscription(
        subscriptionId: 7,
        newMembershipPlanId: 3,
      );

      expect(result.id, 7);
      expect(result.pendingPlan, isNotNull);
      expect(result.pendingPlan!.name, 'Premium');
    });

    test('throws ApiException on 409', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2024-05-20T10:00:00Z',
            'status': 409,
            'error': 'Conflict',
            'message': 'Subscription not active',
            'path': '/api/v1/subscriptions/7/upgrade',
          }),
          409,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.upgradeSubscription(
          subscriptionId: 7,
          newMembershipPlanId: 3,
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)),
      );
    });

    test('throws ApiException on non-200 with non-JSON body', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => repository.upgradeSubscription(
          subscriptionId: 7,
          newMembershipPlanId: 3,
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });
  });

  group('cancelSubscription', () {
    test('completes successfully on 204', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 204));

      await expectLater(
        repository.cancelSubscription(subscriptionId: 7),
        completes,
      );
    });

    test('throws ApiException on 409 with JSON error body', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'timestamp': '2024-05-20T10:00:00Z',
            'status': 409,
            'error': 'Conflict',
            'message': 'Cancellation already pending',
            'path': '/api/v1/subscriptions/7/cancel',
          }),
          409,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => repository.cancelSubscription(subscriptionId: 7),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)),
      );
    });

    test('throws ApiException on non-204 with non-JSON body', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => repository.cancelSubscription(subscriptionId: 7),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });
  });
}
