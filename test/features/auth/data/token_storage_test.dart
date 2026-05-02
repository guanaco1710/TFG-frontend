import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage secureStorage;
  late TokenStorage tokenStorage;

  setUp(() {
    secureStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorage(storage: secureStorage);
  });

  group('saveTokens', () {
    test('writes access and refresh tokens to secure storage', () async {
      when(
        () => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await tokenStorage.saveTokens('acc', 'ref');

      verify(
        () => secureStorage.write(key: 'access_token', value: 'acc'),
      ).called(1);
      verify(
        () => secureStorage.write(key: 'refresh_token', value: 'ref'),
      ).called(1);
    });
  });

  group('getAccessToken', () {
    test('returns stored access token', () async {
      when(
        () => secureStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'acc');

      final token = await tokenStorage.getAccessToken();

      expect(token, 'acc');
    });

    test('returns null when not stored', () async {
      when(
        () => secureStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => null);

      final token = await tokenStorage.getAccessToken();

      expect(token, isNull);
    });
  });

  group('getRefreshToken', () {
    test('returns stored refresh token', () async {
      when(
        () => secureStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'ref');

      final token = await tokenStorage.getRefreshToken();

      expect(token, 'ref');
    });

    test('returns null when not stored', () async {
      when(
        () => secureStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => null);

      final token = await tokenStorage.getRefreshToken();

      expect(token, isNull);
    });
  });

  group('clearTokens', () {
    test('deletes both access and refresh tokens', () async {
      when(
        () => secureStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await tokenStorage.clearTokens();

      verify(() => secureStorage.delete(key: 'access_token')).called(1);
      verify(() => secureStorage.delete(key: 'refresh_token')).called(1);
    });
  });
}
